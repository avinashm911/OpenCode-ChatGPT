// New stock journal form — inventory slice (M07, G1).
// Adjustment entry over the real posting engine: each row names an item, a
// godown, a direction (stock in/out, FR-M07-003 "qty in/out"), a quantity
// and a rate. IN rows layer at line cost (surplus found, physical
// reconciliation); OUT rows consume the book per the valuation method
// (wastage, breakage, samples) and carry zero rate — a nonzero rate on an
// OUT row cannot be stored (the G0 amount CHECK) and is refused here for
// fast feedback. Series numbering follows the registered Stock Journal
// type (auto) or manual entry.
// Traceability: FR-M07-003 (adjustment/transform, wastage/breakage/samples,
// reconciliation); FR-M04-001/002; FR-M13-001 (explicit policy); D-M5.

import 'package:flutter/material.dart';

import 'package:niaverp/application/parsing/entry_parsing.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/core/value_objects/quantity.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// One journal row (ephemeral draft state; the posted lines are the record).
class _JournalRow {
  _JournalRow({required this.item, this.godownId});

  final Item item;
  EntityId? godownId;
  bool stockIn = true;
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController rate = TextEditingController();

  void dispose() {
    qty.dispose();
    rate.dispose();
  }
}

/// Posted journal row (for the success view).
class PostedAdjustment {
  const PostedAdjustment({
    required this.itemName,
    required this.godownName,
    required this.stockIn,
    required this.qtyQ4,
    required this.valuePaise,
  });

  final String itemName;
  final String godownName;
  final bool stockIn;
  final int qtyQ4;
  final int valuePaise;
}

/// New stock journal for [companyId].
class NewStockJournalScreen extends StatefulWidget {
  const NewStockJournalScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  State<NewStockJournalScreen> createState() => NewStockJournalScreenState();
}

class NewStockJournalScreenState extends State<NewStockJournalScreen> {
  final TextEditingController _itemQuery = TextEditingController();
  final List<_JournalRow> _rows = <_JournalRow>[];
  VoucherType? _voucherType;
  VoucherSeries? _series;
  final TextEditingController _manualNo = TextEditingController();
  late TextEditingController _date;
  final TextEditingController _narration = TextEditingController();
  final TextEditingController _reason = TextEditingController();
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
    _itemQuery.dispose();
    for (final _JournalRow r in _rows) {
      r.dispose();
    }
    _manualNo.dispose();
    _date.dispose();
    _narration.dispose();
    _reason.dispose();
    super.dispose();
  }

  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;
  String _mint(String prefix) => _scope.write.idMint(prefix);

  List<VoucherType> _journalTypes() {
    final List<VoucherType> out = <VoucherType>[];
    for (final VoucherType t in _scope.types.listByCompany(_company)) {
      if (t.baseType == 'Stock Journal' ||
          t.baseType == voucherBaseSlug('Stock Journal') ||
          t.name == 'Stock Journal') {
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

  String _godownName(EntityId? id, List<Godown> godowns) {
    if (id == null) return '—';
    for (final Godown g in godowns) {
      if (g.id == id) return g.name;
    }
    return id.value;
  }

  String? _validate(AppLocalizations l10n) {
    if (_rows.isEmpty) return l10n.t('invNeedRow');
    for (int i = 0; i < _rows.length; i++) {
      final _JournalRow r = _rows[i];
      if (_parseQty(r.qty.text) <= 0) {
        return l10n.numberedRow(i + 1, l10n.t('vfQtyPositive'));
      }
      if (r.godownId == null) {
        return l10n.numberedRow(i + 1, l10n.t('invGodownSel'));
      }
      final int rate = _parsePaise(r.rate.text);
      if (rate < 0) {
        return l10n.numberedRow(i + 1, l10n.t('vfRateNonNeg'));
      }
      // OUT rows consume book value; a nonzero rate would price nothing
      // (and a negative line amount violates the G0 amount CHECK).
      if (!r.stockIn && rate != 0) {
        return l10n.numberedRow(i + 1, l10n.t('invNoPrice'));
      }
    }
    try {
      NiavDate(_date.text.trim());
    } on ArgumentError {
      return l10n.t('lvBadDate');
    }
    if (_voucherType == null) {
      return l10n.noTypeRegistered('Stock Journal');
    }
    if (_series == null && _manualNo.text.trim().isEmpty) {
      return l10n.t('vfNeedVoucherNo');
    }
    return null;
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
            key: const ValueKey<String>('journal-new-item-name'),
            controller: name,
            decoration: InputDecoration(labelText: l10n.t('piUnitName')),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('commonCancel')),
            ),
            TextButton(
              key: const ValueKey<String>('journal-new-item-create'),
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
    final List<Godown> godowns = _scope.godowns.listByCompany(_company);
    setState(() {
      _rows.add(_JournalRow(
        item: (r as Ok<Item>).value,
        godownId: godowns.isEmpty ? null : godowns.first.id,
      ));
      _error = null;
    });
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
    final String? reason =
        _reason.text.trim().isEmpty ? null : _reason.text.trim();
    final EntityId voucherId = EntityId(_mint('voucher'));
    final Result<Voucher> created = _scope.vouchers.create(
      id: voucherId,
      companyId: _company,
      type: _voucherType!.name,
      series: seriesName,
      no: voucherNo,
      date: NiavDate(_date.text.trim()),
      narration: <String?>[
        reason,
        _narration.text.trim().isEmpty ? null : _narration.text.trim(),
      ].whereType<String>().join(' · '),
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
    for (final _JournalRow r in _rows) {
      lineNo += 1;
      final int qty = _parseQty(r.qty.text);
      final Result<VoucherLine> added = _scope.vouchers.addLine(
        lineId: EntityId(_mint('line')),
        voucherId: voucherId,
        companyId: _company,
        lineNo: lineNo,
        itemId: r.item.id,
        godownId: r.godownId,
        qtyQ4: r.stockIn ? qty : -qty,
        ratePaise: _parsePaise(r.rate.text),
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
    final List<Godown> godowns = _scope.godowns.listByCompany(_company);
    final List<PostedAdjustment> rows = <PostedAdjustment>[
      for (final _JournalRow r in _rows)
        PostedAdjustment(
          itemName: r.item.name,
          godownName: _godownName(r.godownId, godowns),
          stockIn: r.stockIn,
          qtyQ4: _parseQty(r.qty.text),
          valuePaise: r.stockIn
              ? (_parseQty(r.qty.text) * _parsePaise(r.rate.text)) ~/ 10000
              : 0,
        ),
    ];
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => StockJournalViewScreen(
          voucherNo: voucherNo,
          dateIso: _date.text.trim(),
          rows: rows,
          warnings: pr.warnings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<VoucherType> journalTypes = _journalTypes();
    if (_voucherType != null) {
      final String want = _voucherType!.id.value;
      _voucherType = null;
      for (final VoucherType t in journalTypes) {
        if (t.id.value == want) _voucherType = t;
      }
      if (_voucherType == null) _series = null;
    }
    _voucherType ??=
        journalTypes.isEmpty ? null : journalTypes.first;
    final List<VoucherSeries> autoSeries = _voucherType == null
        ? <VoucherSeries>[]
        : _autoSeries(_voucherType!);
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
    final List<Item> itemHits =
        _scope.search.searchItems(_company, _itemQuery.text);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('invNewJournal'))),
      body: ListView(
        key: const ValueKey<String>('journal-form-list'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Container(
                key: const ValueKey<String>('journal-error'),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(_error!),
              ),
            ),
          Text(l10n.t('invJournalNote')),
          TextField(
            key: const ValueKey<String>('journal-item-field'),
            controller: _itemQuery,
            decoration:
                InputDecoration(labelText: l10n.t('vfSearchItem')),
            onChanged: (_) => setState(() {}),
          ),
          for (final Item item in itemHits)
            ListTile(
              key: ValueKey<String>('journal-item-option-${item.id.value}'),
              title: Text(item.name),
              onTap: () => setState(() {
                _rows.add(_JournalRow(
                  item: item,
                  godownId: godowns.isEmpty ? null : godowns.first.id,
                ));
                _itemQuery.clear();
              }),
            ),
          TextButton(
            key: const ValueKey<String>('journal-new-item'),
            onPressed: _quickAddItem,
            child: Text(l10n.t('vfNewItem')),
          ),
          for (int i = 0; i < _rows.length; i++)
            _JournalRowEditor(
              index: i,
              row: _rows[i],
              godowns: godowns,
              onRemove: () => setState(() {
                _rows[i].dispose();
                _rows.removeAt(i);
              }),
              onDuplicate: () => setState(() {
                final _JournalRow src = _rows[i];
                final _JournalRow copy = _JournalRow(
                  item: src.item,
                  godownId: src.godownId,
                );
                copy.stockIn = src.stockIn;
                copy.qty.text = src.qty.text;
                copy.rate.text = src.rate.text;
                _rows.insert(i + 1, copy);
              }),
              onChanged: () => setState(() {}),
            ),
          const Divider(),
          Text(l10n.t('vfNumbering')),
          if (journalTypes.isEmpty)
            Text(
              '${l10n.noTypeRegistered('Stock Journal')} '
              "${l10n.t('vfRegisterAuto')}",
            )
          else ...<Widget>[
            DropdownButton<VoucherType>(
              key: const ValueKey<String>('journal-type'),
              value: _voucherType,
              items: <DropdownMenuItem<VoucherType>>[
                for (final VoucherType t in journalTypes)
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
                key: const ValueKey<String>('journal-series'),
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
                key: const ValueKey<String>('journal-manual-no'),
                controller: _manualNo,
                decoration:
                    InputDecoration(labelText: l10n.t('vfVoucherNo')),
              ),
          ],
          if (journalTypes.isEmpty)
            TextField(
              key: const ValueKey<String>('journal-manual-no'),
              controller: _manualNo,
              decoration: InputDecoration(labelText: l10n.t('vfVoucherNo')),
            ),
          TextField(
            key: const ValueKey<String>('journal-date'),
            controller: _date,
            decoration:
                InputDecoration(labelText: l10n.t('vfDate')),
          ),
          TextField(
            key: const ValueKey<String>('journal-reason'),
            controller: _reason,
            decoration: InputDecoration(
                labelText: l10n.t('invReason')),
          ),
          TextField(
            key: const ValueKey<String>('journal-narration'),
            controller: _narration,
            decoration:
                InputDecoration(labelText: l10n.t('vfNarrationOpt')),
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
                    key: ValueKey<String>('journal-policy-${p.name}'),
                    title: Text(p.name),
                    value: p,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      // Sticky primary action (UX-001): always visible above the fold.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const ValueKey<String>('journal-post'),
            onPressed: _posting ? null : _post,
            child: Text(_posting
                ? l10n.t('vfPosting')
                : l10n.t('invPostJournal')),
          ),
        ),
      ),
    );
  }
}

/// Direction/godown/quantity editor for one journal row.
class _JournalRowEditor extends StatelessWidget {
  const _JournalRowEditor({
    required this.index,
    required this.row,
    required this.godowns,
    required this.onRemove,
    required this.onDuplicate,
    required this.onChanged,
  });

  final int index;
  final _JournalRow row;
  final List<Godown> godowns;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey<String>('journal-row-$index'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(row.item.name)),
                IconButton(
                  key: ValueKey<String>('journal-row-dupe-$index'),
                  icon: const Icon(Icons.copy),
                  tooltip: l10n.t('commonDuplicate'),
                  onPressed: onDuplicate,
                ),
                IconButton(
                  key: ValueKey<String>('journal-row-remove-$index'),
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.t('commonDeleteRow'),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButton<bool>(
                    key: ValueKey<String>('journal-direction-$index'),
                    value: row.stockIn,
                    items: <DropdownMenuItem<bool>>[
                      DropdownMenuItem<bool>(
                          value: true,
                          child: Text(l10n.t('invStockIn'))),
                      DropdownMenuItem<bool>(
                          value: false,
                          child: Text(l10n.t('invStockOut'))),
                    ],
                    onChanged: (bool? v) {
                      row.stockIn = v ?? true;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<EntityId>(
                    key: ValueKey<String>('journal-godown-$index'),
                    value: row.godownId,
                    hint: Text(l10n.t('wordGodown')),
                    items: <DropdownMenuItem<EntityId>>[
                      for (final Godown g in godowns)
                        DropdownMenuItem<EntityId>(
                            value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (EntityId? v) {
                      row.godownId = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('journal-qty-$index'),
                    controller: row.qty,
                    decoration: InputDecoration(labelText: l10n.t('vfQty')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('journal-rate-$index'),
                    controller: row.rate,
                    decoration: InputDecoration(
                        labelText: l10n.t('invRateRows')),
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

/// Posted journal record: rows adjusted plus posting warnings.
class StockJournalViewScreen extends StatelessWidget {
  const StockJournalViewScreen({
    super.key,
    required this.voucherNo,
    required this.dateIso,
    required this.rows,
    this.warnings = const <String>[],
  });

  final String voucherNo;
  final String dateIso;
  final List<PostedAdjustment> rows;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.journalTitle(voucherNo))),
      body: ListView(
        key: const ValueKey<String>('journal-view'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.noDate(voucherNo, dateIso)),
          for (final String w in warnings) Text(l10n.noteLine(w)),
          const Divider(),
          for (int i = 0; i < rows.length; i++)
            ListTile(
              key: ValueKey<String>('journal-row-view-$i'),
              title: Text(rows[i].itemName),
              subtitle: Text(
                  '${rows[i].stockIn ? l10n.t('invIn') : l10n.t('invOut')} · ${rows[i].godownName}'),
              trailing: Text(
                  '${rows[i].stockIn ? '+' : '−'}${QuantityQ4(rows[i].qtyQ4).format()}'),
            ),
        ],
      ),
    );
  }
}
