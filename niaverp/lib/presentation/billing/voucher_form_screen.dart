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
// - Round-off persists as its own Dr/Cr ledger arm at post time (D-M4, D3-A3:
//   a negative round-off is stored as a positive amount on the opposite side,
//   so the G0 amount CHECK (>= 0) always holds).
// - Payment/receipt is recorded after posting from the invoice view.
// - A registered type matching the configured canonical with an auto
//   series numbers the voucher; otherwise the number is entered manually
//   (duplicates guarded by repo).
// Traceability: FR-M05-001/002 (sale/purchase entry); FR-M04-001/002
// (type/numbering); D-M4 (paise/Q4); FR-M13-001 (explicit policy);
// FR-M03-002/003 (quick-add).

import 'package:flutter/material.dart';

import 'package:niaverp/application/formatting/niav_format.dart';
import 'package:niaverp/application/parsing/entry_parsing.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/migrations/validators.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/billing/invoice_view_screen.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// What differs between the sales and purchase entry screens. Widget keys
/// are `<keyPrefix>-...`, so each flow keeps stable test keys.
class VoucherFormConfig {
  const VoucherFormConfig({
    required this.titleKey,
    required this.keyPrefix,
    required this.typeCanonical,
    required this.partyRole,
    required this.partyWordKey,
    required this.searchHintKey,
    required this.newPartyKey,
    required this.selectFirstKey,
    required this.settlementCanonical,
  });

  /// ARB key for the screen title, e.g. 'vfTitleSale'.
  final String titleKey;

  /// Key prefix, e.g. 'sale' (stable: existing tests bind to these keys).
  final String keyPrefix;

  /// Canonical voucher type, e.g. 'Sales Invoice'.
  final String typeCanonical;

  /// Party role for picker and quick-add, 'customer' or 'supplier'.
  final String partyRole;

  /// ARB key for the human party word, e.g. 'vfCustomer'.
  final String partyWordKey;

  /// ARB key for the party search hint, e.g. 'vfSearchCustomer'.
  final String searchHintKey;

  /// ARB key for the quick-add party label, e.g. 'vfNewCustomer'.
  final String newPartyKey;

  /// ARB key for the select-party-first validation, e.g. 'vfSelectCustomer'.
  final String selectFirstKey;

  /// Settlement voucher posted from the invoice view afterwards, or null
  /// when the document type is never settled directly (e.g. delivery
  /// notes convert to invoices instead — no settlement button is shown).
  final String? settlementCanonical;
}

/// Sales entry configuration (keys `sale-*`).
const VoucherFormConfig saleFormConfig = VoucherFormConfig(
  titleKey: 'vfTitleSale',
  keyPrefix: 'sale',
  typeCanonical: 'Sales Invoice',
  partyRole: 'customer',
  partyWordKey: 'vfCustomer',
  searchHintKey: 'vfSearchCustomer',
  newPartyKey: 'vfNewCustomer',
  selectFirstKey: 'vfSelectCustomer',
  settlementCanonical: 'Receipt',
);

/// Purchase entry configuration (keys `buy-*`).
const VoucherFormConfig purchaseFormConfig = VoucherFormConfig(
  titleKey: 'vfTitlePurchase',
  keyPrefix: 'buy',
  typeCanonical: 'Purchase Invoice',
  partyRole: 'supplier',
  partyWordKey: 'vfSupplier',
  searchHintKey: 'vfSearchSupplier',
  newPartyKey: 'vfNewSupplier',
  selectFirstKey: 'vfSelectSupplier',
  settlementCanonical: 'Payment',
);

/// Delivery note configuration (keys `dn-*`). Delivery notes are never
/// settled directly — they convert to invoices (M09) — so no settlement
/// button is offered afterwards.
const VoucherFormConfig deliveryFormConfig = VoucherFormConfig(
  titleKey: 'vfTitleDelivery',
  keyPrefix: 'dn',
  typeCanonical: 'Delivery Note / Delivery Challan',
  partyRole: 'customer',
  partyWordKey: 'vfCustomer',
  searchHintKey: 'vfSearchCustomer',
  newPartyKey: 'vfNewCustomer',
  selectFirstKey: 'vfSelectCustomer',
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

  int _parseQty(String raw) => parseQuantityQ4(raw);

  int _parsePaise(String raw) => parsePaise(raw);

  int _parseBps(String raw) => parsePercentBps(raw);

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
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.t(_cfg.newPartyKey)),
          content: TextField(
            key: ValueKey<String>(_k('new-party-name')),
            controller: name,
            decoration: InputDecoration(labelText: l10n.t('vfName')),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('commonCancel')),
            ),
            TextButton(
              key: ValueKey<String>(_k('new-party-create')),
              onPressed: () => Navigator.of(context).pop(name.text.trim()),
              child: Text(l10n.t('commonCreate')),
            ),
          ],
        );
      },
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
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.t('vfNewItem')),
          content: TextField(
            key: ValueKey<String>(_k('new-item-name')),
            controller: name,
            decoration: InputDecoration(labelText: l10n.t('piUnitName')),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('commonCancel')),
            ),
            TextButton(
              key: ValueKey<String>(_k('new-item-create')),
              onPressed: () => Navigator.of(context).pop(name.text.trim()),
              child: Text(l10n.t('commonCreate')),
            ),
          ],
        );
      },
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

  String? _validate(AppLocalizations l10n) {
    if (_party == null) return l10n.t(_cfg.selectFirstKey);
    if (_lines.isEmpty) return l10n.t('vfNeedItemLine');
    if (_godownId == null) return l10n.t('vfNeedGodown');
    for (int i = 0; i < _lines.length; i++) {
      final _DraftLine l = _lines[i];
      if (_parseQty(l.qty.text) <= 0) {
        return l10n.numberedLine(i + 1, l10n.t('vfQtyPositive'));
      }
      if (_parsePaise(l.rate.text) < 0) {
        return l10n.numberedLine(i + 1, l10n.t('vfRateNonNeg'));
      }
      if (_parsePaise(l.discAmt.text) < 0) {
        return l10n.numberedLine(i + 1, l10n.t('vfDiscAmtNonNeg'));
      }
      if (_parseBps(l.discRate.text) < 0) {
        return l10n.numberedLine(i + 1, l10n.t('vfDiscPctRange'));
      }
    }
    try {
      NiavDate(_date.text.trim());
    } on ArgumentError {
      return l10n.t('lvBadDate');
    }
    if (_voucherType == null) {
      return l10n.noTypeRegistered(_cfg.typeCanonical);
    }
    if (_series == null && _manualNo.text.trim().isEmpty) {
      return l10n.t('vfNeedVoucherNo');
    }
    return null;
  }

  Future<void> _post() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? problem = _validate(l10n);
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
      _fail('${l10n.errorFor(e.code)}${l10n.t('vfSavedAsDraft')}');
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? problem = _validate(l10n);
    if (problem != null) {
      _fail(problem);
      return;
    }
    final ({int gross, int net}) totals = _draftTotals();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        final NiavFormat fmt = NiavFormat(l10n.localeCode);
        return AlertDialog(
          key: ValueKey<String>(_k('confirm-dialog')),
          title: Text(l10n.confirmPost(_cfg.typeCanonical)),
          content: Text(
            '${l10n.t(_cfg.partyWordKey)}: ${_party?.name ?? '—'}\n'
            '${l10n.linesCount(_lines.length)}\n'
            '${l10n.grossNet(fmt.paise(totals.gross), fmt.paise(totals.net))}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.t('commonReview')),
            ),
            TextButton(
              key: ValueKey<String>(_k('confirm-post')),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.t('commonPost')),
            ),
          ],
        );
      },
    );
    if (go == true && mounted) await _post();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
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
      appBar: AppBar(title: Text(l10n.t(_cfg.titleKey))),
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
          Text(l10n.t(_cfg.partyWordKey)),
          if (_party == null) ...<Widget>[
            TextField(
              key: ValueKey<String>(_k('customer-field')),
              controller: _partyQuery,
              decoration:
                  InputDecoration(labelText: l10n.t(_cfg.searchHintKey)),
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
              child: Text(l10n.t(_cfg.newPartyKey)),
            ),
          ] else
            ListTile(
              key: ValueKey<String>(_k('customer-set')),
              title: Text(_party!.name),
              trailing: TextButton(
                key: ValueKey<String>(_k('customer-change')),
                onPressed: () => setState(() => _party = null),
                child: Text(l10n.t('commonChange')),
              ),
            ),
          const Divider(),
          Text(l10n.t('vfItems')),
          TextField(
            key: ValueKey<String>(_k('item-field')),
            controller: _itemQuery,
            decoration:
                InputDecoration(labelText: l10n.t('vfSearchItem')),
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
            child: Text(l10n.t('vfNewItem')),
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
          Text(l10n.t('wordGodown')),
          DropdownButton<EntityId>(
            key: ValueKey<String>(_k('godown')),
            value: _godownId,
            hint: Text(l10n.t('vfSelectGodown')),
            items: <DropdownMenuItem<EntityId>>[
              for (final Godown g in godowns)
                DropdownMenuItem<EntityId>(value: g.id, child: Text(g.name)),
            ],
            onChanged: (EntityId? v) => setState(() => _godownId = v),
          ),
          const Divider(),
          Text(l10n.t('vfNumbering')),
          if (matching.isEmpty)
            Text(
              '${l10n.noTypeRegistered(_cfg.typeCanonical)} '
              '${l10n.t('vfRegisterAuto')}',
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
              Text(l10n.autoNumbered(_series?.name ?? '')),
            if (autoSeries.isEmpty)
              TextField(
                key: ValueKey<String>(_k('manual-no')),
                controller: _manualNo,
                decoration:
                    InputDecoration(labelText: l10n.t('vfVoucherNo')),
              ),
          ],
          if (matching.isEmpty)
            TextField(
              key: ValueKey<String>(_k('manual-no')),
              controller: _manualNo,
              decoration: InputDecoration(labelText: l10n.t('vfVoucherNo')),
            ),
          TextField(
            key: ValueKey<String>(_k('date')),
            controller: _date,
            decoration: InputDecoration(labelText: l10n.t('vfDate')),
          ),
          TextField(
            key: ValueKey<String>(_k('narration')),
            controller: _narration,
            decoration: InputDecoration(labelText: l10n.t('vfNarrationOpt')),
          ),
          const Divider(),
          Text(l10n.t('vfNegStock')),
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
            l10n.grossNet(fmt.paise(totals.gross), fmt.paise(totals.net)),
            key: ValueKey<String>(_k('totals')),
          ),
          Text(l10n.t('vfGstNoteFull')),
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
            child: Text(
                _posting ? l10n.t('vfPosting') : l10n.t('vfPreviewPost')),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
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
                  tooltip: l10n.t('commonDuplicate'),
                  onPressed: onDuplicate,
                ),
                IconButton(
                  key: ValueKey<String>('$prefix-line-remove-$index'),
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.t('commonDeleteRow'),
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
                        InputDecoration(labelText: l10n.t('vfQty')),
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
                    decoration: InputDecoration(
                        labelText: l10n.t('vfRate')),
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
                    decoration: InputDecoration(
                        labelText: l10n.t('vfDiscAmt')),
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
                    decoration: InputDecoration(
                        labelText: l10n.t('vfDiscPct')),
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
