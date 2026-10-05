// Shared voucher draft form — billing slice (M04/M05/M11, G1).
// One implementation behind the sales and purchase entry screens: party
// pick (search + quick-add), item lines (search + quick-add,
// qty/rate/discount), godown, type auto-number or manual no, date,
// narration, explicit stock policy, live D-M4 totals, confirm preview, then
// one atomic post (voucher + stock + allocations + lineage). The two entry
// points differ only by [VoucherFormConfig] (titles, key prefix, voucher
// type, party role); posting semantics are identical.
//
// Explicit boundaries (never silent, never invented):
// - GST shows a gated note (verified schemas pending G3); no tax is
//   computed or persisted by this form.
// - Round-off posts exact paise totals; a separate round-off ledger line
//   waits on negative-line storage (the G0 amount CHECK stores >= 0).
// - Payment/receipt is recorded after posting from the invoice view.
// - A registered type matching the configured canonical with an auto
//   series numbers the voucher; otherwise the number is entered manually
//   (duplicates guarded by repo).
// Traceability: FR-M05-001/002 (sale/purchase entry); FR-M04-001/002
// (type/numbering); D-M4 (paise/Q4); FR-M13-001 (explicit policy);
// FR-M03-002/003 (quick-add).

import 'package:flutter/material.dart';

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/migrations/validators.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/billing/invoice_view_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// What differs between the sales and purchase entry screens. Widget keys
/// are `<keyPrefix>-...`, so each flow keeps stable test keys.
class VoucherFormConfig {
  const VoucherFormConfig({
    required this.title,
    required this.keyPrefix,
    required this.typeCanonical,
    required this.partyRole,
    required this.partyLabel,
    required this.settlementCanonical,
  });

  /// Screen title, e.g. 'New Sales Invoice'.
  final String title;

  /// Key prefix, e.g. 'sale' (stable: existing tests bind to these keys).
  final String keyPrefix;

  /// Canonical voucher type, e.g. 'Sales Invoice'.
  final String typeCanonical;

  /// Party role for picker and quick-add, 'customer' or 'supplier'.
  final String partyRole;

  /// Human party word, e.g. 'Customer'.
  final String partyLabel;

  /// Settlement voucher posted from the invoice view afterwards, or null
  /// when the document type is never settled directly (e.g. delivery
  /// notes convert to invoices instead — no settlement button is shown).
  final String? settlementCanonical;
}

/// Sales entry configuration (keys `sale-*`).
const VoucherFormConfig saleFormConfig = VoucherFormConfig(
  title: 'New Sales Invoice',
  keyPrefix: 'sale',
  typeCanonical: 'Sales Invoice',
  partyRole: 'customer',
  partyLabel: 'Customer',
  settlementCanonical: 'Receipt',
);

/// Purchase entry configuration (keys `buy-*`).
const VoucherFormConfig purchaseFormConfig = VoucherFormConfig(
  title: 'New Purchase Invoice',
  keyPrefix: 'buy',
  typeCanonical: 'Purchase Invoice',
  partyRole: 'supplier',
  partyLabel: 'Supplier',
  settlementCanonical: 'Payment',
);

/// Delivery note configuration (keys `dn-*`). Delivery notes are never
/// settled directly — they convert to invoices (M09) — so no settlement
/// button is offered afterwards.
const VoucherFormConfig deliveryFormConfig = VoucherFormConfig(
  title: 'New Delivery Note',
  keyPrefix: 'dn',
  typeCanonical: 'Delivery Note / Delivery Challan',
  partyRole: 'customer',
  partyLabel: 'Customer',
  settlementCanonical: null,
);

/// One editable draft line (ephemeral state; the posted voucher lines are
/// the record — nothing authoritative lives only here).
class _DraftLine {
  _DraftLine({required this.item});

  final Item item;
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController rate = TextEditingController();
  final TextEditingController discAmt = TextEditingController();
  final TextEditingController discRate = TextEditingController();

  void dispose() {
    qty.dispose();
    rate.dispose();
    discAmt.dispose();
    discRate.dispose();
  }
}

/// Config-driven voucher draft form for [companyId].
class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({
    super.key,
    required this.companyId,
    required this.scope,
    required this.config,
  });

  final CompanyId companyId;
  final CompanyScope scope;
  final VoucherFormConfig config;

  @override
  State<VoucherFormScreen> createState() => VoucherFormScreenState();
}

class VoucherFormScreenState extends State<VoucherFormScreen> {
  Party? _party;
  final TextEditingController _partyQuery = TextEditingController();
  final TextEditingController _itemQuery = TextEditingController();
  final List<_DraftLine> _lines = <_DraftLine>[];
  EntityId? _godownId;
  VoucherType? _voucherType;
  VoucherSeries? _series;
  final TextEditingController _manualNo = TextEditingController();
  late TextEditingController _date;
  final TextEditingController _narration = TextEditingController();
  StockPolicy _policy = StockPolicy.warn;
  String? _error;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(text: widget.scope.today.iso);
  }

  @override
  void dispose() {
    _partyQuery.dispose();
    _itemQuery.dispose();
    for (final _DraftLine l in _lines) {
      l.dispose();
    }
    _manualNo.dispose();
    _date.dispose();
    _narration.dispose();
    super.dispose();
  }

  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;
  VoucherFormConfig get _cfg => widget.config;
  String _k(String suffix) => '${_cfg.keyPrefix}-$suffix';
  String _mint(String prefix) => _scope.write.idMint(prefix);

  /// Registered types whose base resolves to the configured canonical.
  List<VoucherType> _matchingTypes() {
    final List<VoucherType> out = <VoucherType>[];
    for (final VoucherType t in _scope.types.listByCompany(_company)) {
      if (t.baseType == _cfg.typeCanonical ||
          t.baseType == voucherBaseSlug(_cfg.typeCanonical) ||
          t.name == _cfg.typeCanonical) {
        out.add(t);
      }
    }
    return out;
  }

  List<VoucherSeries> _autoSeries(VoucherType t) {
    return <VoucherSeries>[
      for (final VoucherSeries s
          in _scope.types.seriesForType(_company, t.id))
        if (s.mode == 'auto') s,
    ];
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _posting = false;
    });
  }

  int _parseQty(String raw) {
    final double? units = double.tryParse(raw.trim());
    if (units == null || units <= 0) return -1;
    return (units * 10000).round();
  }

  int _parsePaise(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return 0;
    final double? rupees = double.tryParse(t);
    if (rupees == null || rupees < 0) return -1;
    return (rupees * 100).round();
  }

  int _parseBps(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return 0;
    final double? pct = double.tryParse(t);
    if (pct == null || pct < 0 || pct > 100) return -1;
    return (pct * 100).round();
  }

  /// Draft totals over valid lines only (invalid rows show 0 until fixed).
  ({int gross, int net}) _draftTotals() {
    int gross = 0;
    int net = 0;
    for (final _DraftLine l in _lines) {
      final int qty = _parseQty(l.qty.text);
      final int rate = _parsePaise(l.rate.text);
      if (qty <= 0 || rate < 0) continue;
      final int amount = lineAmount(qty, rate);
      gross += amount;
      net += lineNet(
          amount, _parsePaise(l.discAmt.text), _parseBps(l.discRate.text));
    }
    return (gross: gross, net: net);
  }

  Future<void> _quickAddParty() async {
    final TextEditingController name = TextEditingController();
    final String? created = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('New ${_cfg.partyLabel.toLowerCase()}'),
        content: TextField(
          key: ValueKey<String>(_k('new-party-name')),
          controller: name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: ValueKey<String>(_k('new-party-create')),
            onPressed: () => Navigator.of(context).pop(name.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    name.dispose();
    if (created == null || created.isEmpty || !mounted) return;
    final Result<Party> r = _scope.parties.create(
      id: EntityId(_mint('party')),
      companyId: _company,
      name: created,
      role: _cfg.partyRole,
      deviceId: _scope.write.deviceId,
      opId: _mint('op'),
      eventId: _mint('ev'),
      actor: _scope.write.actor,
    );
    if (r.isErr) {
      _fail((r as Err<Party>).error.message);
      return;
    }
    setState(() {
      _party = (r as Ok<Party>).value;
      _partyQuery.clear();
      _error = null;
    });
  }

  Future<void> _quickAddItem() async {
    final TextEditingController name = TextEditingController();
    final String? created = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('New item'),
        content: TextField(
          key: ValueKey<String>(_k('new-item-name')),
          controller: name,
          decoration: const InputDecoration(labelText: 'Name (unit pcs)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: ValueKey<String>(_k('new-item-create')),
            onPressed: () => Navigator.of(context).pop(name.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    name.dispose();
    if (created == null || created.isEmpty || !mounted) return;
    final Result<Item> r = _scope.items.create(
      id: EntityId(_mint('item')),
      companyId: _company,
      name: created,
      deviceId: _scope.write.deviceId,
      opId: _mint('op'),
      eventId: _mint('ev'),
      actor: _scope.write.actor,
    );
    if (r.isErr) {
      _fail((r as Err<Item>).error.message);
      return;
    }
    setState(() {
      _lines.add(_DraftLine(item: (r as Ok<Item>).value));
      _itemQuery.clear();
      _error = null;
    });
  }

  String? _validate() {
    if (_party == null) return 'Select a ${_cfg.partyLabel.toLowerCase()} first.';
    if (_lines.isEmpty) return 'Add at least one item line.';
    if (_godownId == null) return 'Select a godown.';
    for (int i = 0; i < _lines.length; i++) {
      final _DraftLine l = _lines[i];
      if (_parseQty(l.qty.text) <= 0) {
        return 'Line ${i + 1}: quantity must be a positive number.';
      }
      if (_parsePaise(l.rate.text) < 0) {
        return 'Line ${i + 1}: rate must be a non-negative amount.';
      }
      if (_parsePaise(l.discAmt.text) < 0) {
        return 'Line ${i + 1}: discount amount must be non-negative.';
      }
      if (_parseBps(l.discRate.text) < 0) {
        return 'Line ${i + 1}: discount % must be 0–100.';
      }
    }
    try {
      NiavDate(_date.text.trim());
    } on ArgumentError {
      return 'Date must be YYYY-MM-DD.';
    }
    if (_voucherType == null) {
      return 'No ${_cfg.typeCanonical} type is registered.';
    }
    if (_series == null && _manualNo.text.trim().isEmpty) {
      return 'Enter the voucher number.';
    }
    return null;
  }

  Future<void> _post() async {
    final String? problem = _validate();
    if (problem != null) {
      _fail(problem);
      return;
    }
    setState(() {
      _posting = true;
      _error = null;
    });
    // Number: auto series generates at post time (no gaps from previews);
    // manual mode uses the entered number (duplicates guarded by repo).
    String seriesName;
    String voucherNo;
    if (_series != null) {
      final Result<String> gen =
          _scope.numbering.nextNumber(_company, _series!);
      if (gen.isErr) {
        _fail((gen as Err<String>).error.message);
        return;
      }
      seriesName = _series!.name;
      voucherNo = (gen as Ok<String>).value;
    } else {
      seriesName = 'manual';
      voucherNo = _manualNo.text.trim();
    }
    final EntityId voucherId = EntityId(_mint('voucher'));
    final Result<Voucher> created = _scope.vouchers.create(
      id: voucherId,
      companyId: _company,
      type: _voucherType!.name,
      series: seriesName,
      no: voucherNo,
      date: NiavDate(_date.text.trim()),
      narration:
          _narration.text.trim().isEmpty ? null : _narration.text.trim(),
      deviceId: _scope.write.deviceId,
      opId: _mint('op'),
      eventId: _mint('ev'),
      actor: _scope.write.actor,
    );
    if (created.isErr) {
      _fail((created as Err<Voucher>).error.message);
      return;
    }
    int lineNo = 0;
    for (final _DraftLine l in _lines) {
      lineNo += 1;
      final Result<VoucherLine> added = _scope.vouchers.addLine(
        lineId: EntityId(_mint('line')),
        voucherId: voucherId,
        companyId: _company,
        lineNo: lineNo,
        itemId: l.item.id,
        godownId: _godownId,
        partyId: _party!.id,
        qtyQ4: _parseQty(l.qty.text),
        ratePaise: _parsePaise(l.rate.text),
        discountAmountPaise: _parsePaise(l.discAmt.text),
        discountRateBps: _parseBps(l.discRate.text),
        deviceId: _scope.write.deviceId,
        opId: _mint('op'),
        eventId: _mint('ev'),
        actor: _scope.write.actor,
      );
      if (added.isErr) {
        _fail((added as Err<VoucherLine>).error.message);
        return;
      }
    }
    final Result<PostingResult> posted = _scope.engine.postWithStock(
      id: voucherId,
      companyId: _company,
      policy: _policy,
      deviceId: _scope.write.deviceId,
      opId: _mint('op'),
      eventId: _mint('ev'),
      actor: _scope.write.actor,
    );
    if (posted.isErr) {
      final AppError e = (posted as Err<PostingResult>).error;
      _fail('${e.code}: ${e.message} (saved as draft)');
      return;
    }
    if (!mounted) return;
    final PostingResult pr = (posted as Ok<PostingResult>).value;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => InvoiceViewScreen(
          companyId: _company,
          voucherId: voucherId,
          scope: _scope,
          settlementCanonical: _cfg.settlementCanonical,
          postingWarnings: pr.warnings,
        ),
      ),
    );
  }

  Future<void> _confirmAndPost() async {
    final String? problem = _validate();
    if (problem != null) {
      _fail(problem);
      return;
    }
    final ({int gross, int net}) totals = _draftTotals();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        key: ValueKey<String>(_k('confirm-dialog')),
        title: Text('Post ${_cfg.typeCanonical}?'),
        content: Text(
          '${_cfg.partyLabel}: ${_party?.name ?? '—'}\n'
          'Lines: ${_lines.length}\n'
          'Gross: ₹${MoneyPaise(totals.gross).toRupeesString()}\n'
          'Net: ₹${MoneyPaise(totals.net).toRupeesString()}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review'),
          ),
          TextButton(
            key: ValueKey<String>(_k('confirm-post')),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (go == true && mounted) await _post();
  }

  @override
  Widget build(BuildContext context) {
    final List<VoucherType> matching = _matchingTypes();
    // Dropdowns match by identity: rebind selections to this build's
    // instances (repositories return fresh objects per read).
    if (_voucherType != null) {
      final String want = _voucherType!.id.value;
      _voucherType = null;
      for (final VoucherType t in matching) {
        if (t.id.value == want) _voucherType = t;
      }
      if (_voucherType == null) _series = null;
    }
    _voucherType ??= matching.isEmpty ? null : matching.first;
    final List<VoucherSeries> autoSeries =
        _voucherType == null ? <VoucherSeries>[] : _autoSeries(_voucherType!);
    if (_series != null) {
      final String want = _series!.id.value;
      _series = null;
      for (final VoucherSeries s in autoSeries) {
        if (s.id.value == want) _series = s;
      }
    }
    _series ??= autoSeries.isEmpty ? null : autoSeries.first;
    final List<Godown> godowns =
        _scope.godowns.listByCompany(_company);
    if (_godownId != null &&
        godowns.every((Godown g) => g.id != _godownId)) {
      _godownId = null;
    }
    _godownId ??= godowns.isEmpty ? null : godowns.first.id;
    final List<Party> partyHits = _party == null
        ? _scope.search.searchParties(_company, _partyQuery.text)
        : <Party>[];
    final List<Item> itemHits = _scope.search.searchItems(
        _company, _itemQuery.text);
    final ({int gross, int net}) totals = _draftTotals();

    return Scaffold(
      appBar: AppBar(title: Text(_cfg.title)),
      body: ListView(
        key: ValueKey<String>(_k('form-list')),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Container(
                key: ValueKey<String>(_k('error')),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(_error!),
              ),
            ),
          Text(_cfg.partyLabel),
          if (_party == null) ...<Widget>[
            TextField(
              key: ValueKey<String>(_k('customer-field')),
              controller: _partyQuery,
              decoration: InputDecoration(
                  labelText: 'Search ${_cfg.partyLabel.toLowerCase()} by name'),
              onChanged: (_) => setState(() {}),
            ),
            for (final Party p in partyHits)
              ListTile(
                key: ValueKey<String>(
                    '${_cfg.keyPrefix}-customer-option-${p.id.value}'),
                title: Text(p.name),
                onTap: () => setState(() {
                  _party = p;
                  _partyQuery.clear();
                  _error = null;
                }),
              ),
            TextButton(
              key: ValueKey<String>(_k('new-party')),
              onPressed: _quickAddParty,
              child: Text('New ${_cfg.partyLabel.toLowerCase()}'),
            ),
          ] else
            ListTile(
              key: ValueKey<String>(_k('customer-set')),
              title: Text(_party!.name),
              trailing: TextButton(
                key: ValueKey<String>(_k('customer-change')),
                onPressed: () => setState(() => _party = null),
                child: const Text('Change'),
              ),
            ),
          const Divider(),
          const Text('Items'),
          TextField(
            key: ValueKey<String>(_k('item-field')),
            controller: _itemQuery,
            decoration:
                const InputDecoration(labelText: 'Search item by name/code'),
            onChanged: (_) => setState(() {}),
          ),
          for (final Item item in itemHits)
            ListTile(
              key: ValueKey<String>(
                  '${_cfg.keyPrefix}-item-option-${item.id.value}'),
              title: Text(item.name),
              onTap: () => setState(() {
                _lines.add(_DraftLine(item: item));
                _itemQuery.clear();
              }),
            ),
          TextButton(
            key: ValueKey<String>(_k('new-item')),
            onPressed: _quickAddItem,
            child: const Text('New item'),
          ),
          for (int i = 0; i < _lines.length; i++)
            _LineEditor(
              prefix: _cfg.keyPrefix,
              index: i,
              line: _lines[i],
              onRemove: () => setState(() {
                _lines[i].dispose();
                _lines.removeAt(i);
              }),
              onDuplicate: () => setState(() {
                final _DraftLine src = _lines[i];
                final _DraftLine copy = _DraftLine(item: src.item);
                copy.qty.text = src.qty.text;
                copy.rate.text = src.rate.text;
                copy.discAmt.text = src.discAmt.text;
                copy.discRate.text = src.discRate.text;
                _lines.insert(i + 1, copy);
              }),
              onChanged: () => setState(() {}),
            ),
          const Divider(),
          const Text('Godown'),
          DropdownButton<EntityId>(
            key: ValueKey<String>(_k('godown')),
            value: _godownId,
            hint: const Text('Select godown'),
            items: <DropdownMenuItem<EntityId>>[
              for (final Godown g in godowns)
                DropdownMenuItem<EntityId>(value: g.id, child: Text(g.name)),
            ],
            onChanged: (EntityId? v) => setState(() => _godownId = v),
          ),
          const Divider(),
          const Text('Numbering'),
          if (matching.isEmpty)
            Text(
              'No ${_cfg.typeCanonical} type is registered. Register one with an '
              'auto series (or enter the number manually).',
            )
          else ...<Widget>[
            DropdownButton<VoucherType>(
              key: ValueKey<String>(_k('type')),
              value: _voucherType,
              items: <DropdownMenuItem<VoucherType>>[
                for (final VoucherType t in matching)
                  DropdownMenuItem<VoucherType>(
                      value: t, child: Text(t.name)),
              ],
              onChanged: (VoucherType? v) => setState(() {
                _voucherType = v;
                _series = null;
              }),
            ),
            if (autoSeries.isNotEmpty)
              DropdownButton<VoucherSeries>(
                key: ValueKey<String>(_k('series')),
                value: _series,
                items: <DropdownMenuItem<VoucherSeries>>[
                  for (final VoucherSeries s in autoSeries)
                    DropdownMenuItem<VoucherSeries>(
                        value: s, child: Text(s.name)),
                ],
                onChanged: (VoucherSeries? v) =>
                    setState(() => _series = v),
              ),
            if (autoSeries.isNotEmpty)
              Text('Auto-numbered on post (${_series?.name ?? ''}).'),
            if (autoSeries.isEmpty)
              TextField(
                key: ValueKey<String>(_k('manual-no')),
                controller: _manualNo,
                decoration:
                    const InputDecoration(labelText: 'Voucher number'),
              ),
          ],
          if (matching.isEmpty)
            TextField(
              key: ValueKey<String>(_k('manual-no')),
              controller: _manualNo,
              decoration: const InputDecoration(labelText: 'Voucher number'),
            ),
          TextField(
            key: ValueKey<String>(_k('date')),
            controller: _date,
            decoration:
                const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
          ),
          TextField(
            key: ValueKey<String>(_k('narration')),
            controller: _narration,
            decoration:
                const InputDecoration(labelText: 'Narration (optional)'),
          ),
          const Divider(),
          const Text('Negative-stock policy'),
          RadioGroup<StockPolicy>(
            groupValue: _policy,
            onChanged: (StockPolicy? v) =>
                setState(() => _policy = v ?? StockPolicy.warn),
            child: Column(
              children: <Widget>[
                for (final StockPolicy p in StockPolicy.values)
                  RadioListTile<StockPolicy>(
                    key: ValueKey<String>(
                        '${_cfg.keyPrefix}-policy-${p.name}'),
                    title: Text(p.name),
                    value: p,
                  ),
              ],
            ),
          ),
          const Divider(),
          Text(
            'Gross: ₹${MoneyPaise(totals.gross).toRupeesString()} · '
            'Net: ₹${MoneyPaise(totals.net).toRupeesString()}',
            key: ValueKey<String>(_k('totals')),
          ),
          const Text(
            'GST is not computed here: tax fields wait on verified schemas '
            '(G3). Round-off posts exact paise; a separate round-off line '
            'waits on negative-line storage.',
          ),
          const SizedBox(height: 12),
        ],
      ),
      // Sticky primary action (UX-001): always visible above the fold.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: ValueKey<String>(_k('post')),
            onPressed: _posting ? null : _confirmAndPost,
            child: Text(_posting ? 'Posting…' : 'Preview & Post'),
          ),
        ),
      ),
    );
  }
}

/// Editable quantity/rate/discount row for one draft line.
class _LineEditor extends StatelessWidget {
  const _LineEditor({
    required this.prefix,
    required this.index,
    required this.line,
    required this.onRemove,
    required this.onDuplicate,
    required this.onChanged,
  });

  final String prefix;
  final int index;
  final _DraftLine line;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('$prefix-line-$index'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(line.item.name)),
                IconButton(
                  key: ValueKey<String>('$prefix-line-dupe-$index'),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate row',
                  onPressed: onDuplicate,
                ),
                IconButton(
                  key: ValueKey<String>('$prefix-line-remove-$index'),
                  icon: const Icon(Icons.delete),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('$prefix-line-qty-$index'),
                    controller: line.qty,
                    decoration:
                        const InputDecoration(labelText: 'Qty'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('$prefix-line-rate-$index'),
                    controller: line.rate,
                    decoration: const InputDecoration(
                        labelText: 'Rate (₹)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('$prefix-line-discamt-$index'),
                    controller: line.discAmt,
                    decoration: const InputDecoration(
                        labelText: 'Discount (₹)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('$prefix-line-discrate-$index'),
                    controller: line.discRate,
                    decoration: const InputDecoration(
                        labelText: 'Discount (%)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
