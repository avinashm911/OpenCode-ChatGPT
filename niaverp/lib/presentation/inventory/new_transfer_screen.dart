// New stock transfer form — inventory slice (M07, G1).
// Paired-leg entry over the real posting engine: each row names an item, a
// source godown, a destination godown and a quantity; posting writes one
// OUT leg (negative qty, source) and one IN leg (positive qty, destination)
// per row at zero rate — value flows from the book, so transfers preserve
// it. Source ≠ destination and balanced legs are validated here for fast
// feedback and enforced by the engine at post (FR-M07-002). Series numbering
// follows the registered Stock Transfer type (auto) or manual entry.
// Traceability: FR-M07-002 (transfer from/to locations); FR-M04-001/002;
// FR-M13-001 (explicit policy); D-M5 (value preservation).

import 'package:flutter/material.dart';

import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/core/value_objects/quantity.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// One transfer row (ephemeral draft state; the posted legs are the record).
class _TransferRow {
  _TransferRow({required this.item, this.fromId, this.toId});

  final Item item;
  EntityId? fromId;
  EntityId? toId;
  final TextEditingController qty = TextEditingController(text: '1');

  void dispose() => qty.dispose();
}

/// Posted transfer legs for one row (for the success view).
class PostedLeg {
  const PostedLeg({
    required this.itemName,
    required this.fromName,
    required this.toName,
    required this.qtyQ4,
  });

  final String itemName;
  final String fromName;
  final String toName;
  final int qtyQ4;
}

/// New stock transfer for [companyId].
class NewTransferScreen extends StatefulWidget {
  const NewTransferScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  State<NewTransferScreen> createState() => NewTransferScreenState();
}

class NewTransferScreenState extends State<NewTransferScreen> {
  final TextEditingController _itemQuery = TextEditingController();
  final List<_TransferRow> _rows = <_TransferRow>[];
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
    _itemQuery.dispose();
    for (final _TransferRow r in _rows) {
      r.dispose();
    }
    _manualNo.dispose();
    _date.dispose();
    _narration.dispose();
    super.dispose();
  }

  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;
  String _mint(String prefix) => _scope.write.idMint(prefix);

  List<VoucherType> _transferTypes() {
    final List<VoucherType> out = <VoucherType>[];
    for (final VoucherType t in _scope.types.listByCompany(_company)) {
      if (t.baseType == 'Stock Transfer' ||
          t.baseType == voucherBaseSlug('Stock Transfer') ||
          t.name == 'Stock Transfer') {
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

  String _godownName(EntityId? id, List<Godown> godowns) {
    if (id == null) return '—';
    for (final Godown g in godowns) {
      if (g.id == id) return g.name;
    }
    return id.value;
  }

  String? _validate() {
    if (_rows.isEmpty) return 'Add at least one transfer row.';
    for (int i = 0; i < _rows.length; i++) {
      final _TransferRow r = _rows[i];
      if (_parseQty(r.qty.text) <= 0) {
        return 'Row ${i + 1}: quantity must be a positive number.';
      }
      if (r.fromId == null || r.toId == null) {
        return 'Row ${i + 1}: select source and destination godowns.';
      }
      if (r.fromId == r.toId) {
        return 'Row ${i + 1}: source must differ from destination.';
      }
    }
    try {
      NiavDate(_date.text.trim());
    } on ArgumentError {
      return 'Date must be YYYY-MM-DD.';
    }
    if (_voucherType == null) return 'No Stock Transfer type is registered.';
    if (_series == null && _manualNo.text.trim().isEmpty) {
      return 'Enter the voucher number.';
    }
    return null;
  }

  Future<void> _quickAddItem() async {
    final TextEditingController name = TextEditingController();
    final String? created = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('New item'),
        content: TextField(
          key: const ValueKey<String>('transfer-new-item-name'),
          controller: name,
          decoration: const InputDecoration(labelText: 'Name (unit pcs)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey<String>('transfer-new-item-create'),
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
    final Item item = (r as Ok<Item>).value;
    final List<Godown> godowns = _scope.godowns.listByCompany(_company);
    setState(() {
      _rows.add(_TransferRow(
        item: item,
        fromId: godowns.isEmpty ? null : godowns.first.id,
        toId: godowns.length > 1 ? godowns[1].id : null,
      ));
      _error = null;
    });
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
    for (final _TransferRow r in _rows) {
      final int qty = _parseQty(r.qty.text);
      // OUT leg first (negative qty, source), then the IN leg — both at
      // zero rate so value flows from the book (engine requirement).
      for (final (EntityId? godown, int signed) in <(EntityId?, int)>[
        (r.fromId, -qty),
        (r.toId, qty),
      ]) {
        lineNo += 1;
        final Result<VoucherLine> added = _scope.vouchers.addLine(
          lineId: EntityId(_mint('line')),
          voucherId: voucherId,
          companyId: _company,
          lineNo: lineNo,
          itemId: r.item.id,
          godownId: godown,
          qtyQ4: signed,
          ratePaise: 0,
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
    final List<Godown> godowns = _scope.godowns.listByCompany(_company);
    final List<PostedLeg> legs = <PostedLeg>[
      for (final _TransferRow r in _rows)
        PostedLeg(
          itemName: r.item.name,
          fromName: _godownName(r.fromId, godowns),
          toName: _godownName(r.toId, godowns),
          qtyQ4: _parseQty(r.qty.text),
        ),
    ];
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TransferViewScreen(
          voucherNo: voucherNo,
          dateIso: _date.text.trim(),
          legs: legs,
          warnings: pr.warnings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<VoucherType> transferTypes = _transferTypes();
    if (_voucherType != null) {
      final String want = _voucherType!.id.value;
      _voucherType = null;
      for (final VoucherType t in transferTypes) {
        if (t.id.value == want) _voucherType = t;
      }
      if (_voucherType == null) _series = null;
    }
    _voucherType ??=
        transferTypes.isEmpty ? null : transferTypes.first;
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
      appBar: AppBar(title: const Text('New Stock Transfer')),
      body: ListView(
        key: const ValueKey<String>('transfer-form-list'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Container(
                key: const ValueKey<String>('transfer-error'),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(_error!),
              ),
            ),
          const Text('Items (legs carry no price; value moves with the goods)'),
          TextField(
            key: const ValueKey<String>('transfer-item-field'),
            controller: _itemQuery,
            decoration:
                const InputDecoration(labelText: 'Search item by name/code'),
            onChanged: (_) => setState(() {}),
          ),
          for (final Item item in itemHits)
            ListTile(
              key: ValueKey<String>('transfer-item-option-${item.id.value}'),
              title: Text(item.name),
              onTap: () => setState(() {
                _rows.add(_TransferRow(
                  item: item,
                  fromId: godowns.isEmpty ? null : godowns.first.id,
                  toId: godowns.length > 1 ? godowns[1].id : null,
                ));
                _itemQuery.clear();
              }),
            ),
          TextButton(
            key: const ValueKey<String>('transfer-new-item'),
            onPressed: _quickAddItem,
            child: const Text('New item'),
          ),
          for (int i = 0; i < _rows.length; i++)
            _TransferRowEditor(
              index: i,
              row: _rows[i],
              godowns: godowns,
              onRemove: () => setState(() {
                _rows[i].dispose();
                _rows.removeAt(i);
              }),
              onDuplicate: () => setState(() {
                final _TransferRow src = _rows[i];
                final _TransferRow copy = _TransferRow(
                  item: src.item,
                  fromId: src.fromId,
                  toId: src.toId,
                );
                copy.qty.text = src.qty.text;
                _rows.insert(i + 1, copy);
              }),
              onChanged: () => setState(() {}),
            ),
          const Divider(),
          const Text('Numbering'),
          if (transferTypes.isEmpty)
            const Text(
              'No Stock Transfer type is registered. Register one with an '
              'auto series (or enter the number manually).',
            )
          else ...<Widget>[
            DropdownButton<VoucherType>(
              key: const ValueKey<String>('transfer-type'),
              value: _voucherType,
              items: <DropdownMenuItem<VoucherType>>[
                for (final VoucherType t in transferTypes)
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
                key: const ValueKey<String>('transfer-series'),
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
                key: const ValueKey<String>('transfer-manual-no'),
                controller: _manualNo,
                decoration:
                    const InputDecoration(labelText: 'Voucher number'),
              ),
          ],
          if (transferTypes.isEmpty)
            TextField(
              key: const ValueKey<String>('transfer-manual-no'),
              controller: _manualNo,
              decoration: const InputDecoration(labelText: 'Voucher number'),
            ),
          TextField(
            key: const ValueKey<String>('transfer-date'),
            controller: _date,
            decoration:
                const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
          ),
          TextField(
            key: const ValueKey<String>('transfer-narration'),
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
                    key: ValueKey<String>('transfer-policy-${p.name}'),
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
            key: const ValueKey<String>('transfer-post'),
            onPressed: _posting ? null : _post,
            child: Text(_posting ? 'Posting…' : 'Post transfer'),
          ),
        ),
      ),
    );
  }
}

/// Source/destination/quantity editor for one transfer row.
class _TransferRowEditor extends StatelessWidget {
  const _TransferRowEditor({
    required this.index,
    required this.row,
    required this.godowns,
    required this.onRemove,
    required this.onDuplicate,
    required this.onChanged,
  });

  final int index;
  final _TransferRow row;
  final List<Godown> godowns;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('transfer-row-$index'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(row.item.name)),
                IconButton(
                  key: ValueKey<String>('transfer-row-dupe-$index'),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate row',
                  onPressed: onDuplicate,
                ),
                IconButton(
                  key: ValueKey<String>('transfer-row-remove-$index'),
                  icon: const Icon(Icons.delete),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButton<EntityId>(
                    key: ValueKey<String>('transfer-from-$index'),
                    value: row.fromId,
                    hint: const Text('From'),
                    items: <DropdownMenuItem<EntityId>>[
                      for (final Godown g in godowns)
                        DropdownMenuItem<EntityId>(
                            value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (EntityId? v) {
                      row.fromId = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<EntityId>(
                    key: ValueKey<String>('transfer-to-$index'),
                    value: row.toId,
                    hint: const Text('To'),
                    items: <DropdownMenuItem<EntityId>>[
                      for (final Godown g in godowns)
                        DropdownMenuItem<EntityId>(
                            value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (EntityId? v) {
                      row.toId = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            TextField(
              key: ValueKey<String>('transfer-qty-$index'),
              controller: row.qty,
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Posted transfer record: legs moved plus posting warnings.
class TransferViewScreen extends StatelessWidget {
  const TransferViewScreen({
    super.key,
    required this.voucherNo,
    required this.dateIso,
    required this.legs,
    this.warnings = const <String>[],
  });

  final String voucherNo;
  final String dateIso;
  final List<PostedLeg> legs;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer $voucherNo')),
      body: ListView(
        key: const ValueKey<String>('transfer-view'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('No: $voucherNo · Date: $dateIso'),
          for (final String w in warnings) Text('Note: $w'),
          const Divider(),
          for (int i = 0; i < legs.length; i++)
            ListTile(
              key: ValueKey<String>('transfer-leg-$i'),
              title: Text(legs[i].itemName),
              subtitle:
                  Text('${legs[i].fromName} → ${legs[i].toName}'),
              trailing:
                  Text(QuantityQ4(legs[i].qtyQ4).format()),
            ),
        ],
      ),
    );
  }
}
