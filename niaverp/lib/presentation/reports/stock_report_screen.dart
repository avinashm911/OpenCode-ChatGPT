// NiAvERP stock report screen — prompt 11 (UI-009/UI-010 P1 slice, G1).
// Read-only balances report over the real [StockLevels] query (M15): one row
// per (item, godown) with names resolved through the real item/godown
// repositories (ids shown when a master row is absent — never invented).
// States: loading, empty, success, recoverable-error with retry (FutureBuilder
// + error block, onboarding pattern). Validation/locked states are N/A: this
// screen takes no input and posts nothing. Main-app wiring waits on the
// production database engine (P-SQLIB), like the phase-02 screens.
// Traceability: UI-009 (stock view); UI-010 (report view); M15.

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/quantity.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

/// One rendered balance row (names resolved, quantities formatted).
class StockBalanceRow {
  const StockBalanceRow({
    required this.itemName,
    required this.godownName,
    required this.qtyQ4,
  });

  final String itemName;
  final String godownName;
  final int qtyQ4;

  /// Formatted quantity (integer ×10⁴, explicit scale — D-M4).
  String get qtyText => QuantityQ4(qtyQ4).format();
}

/// Company stock balances, read from persisted movements.
class StockReportScreen extends StatefulWidget {
  const StockReportScreen({
    super.key,
    required this.companyId,
    required this.levels,
    required this.items,
    required this.godowns,
  });

  final CompanyId companyId;
  final StockLevels levels;
  final ItemRepository items;
  final GodownRepository godowns;

  @override
  State<StockReportScreen> createState() => StockReportScreenState();
}

class StockReportScreenState extends State<StockReportScreen> {
  late Future<List<StockBalanceRow>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<StockBalanceRow>> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return <StockBalanceRow>[];
    final List<StockBalance> balances =
        widget.levels.balances(widget.companyId);
    final Map<String, String> godownNames = <String, String>{
      for (final Godown g in widget.godowns.listByCompany(widget.companyId))
        g.id.value: g.name,
    };
    return <StockBalanceRow>[
      for (final StockBalance b in balances)
        StockBalanceRow(
          itemName: widget.items
                  .get(widget.companyId, b.itemId)
                  ?.name ??
              b.itemId.value,
          godownName: godownNames[b.godownId.value] ?? b.godownId.value,
          qtyQ4: b.qtyQ4,
        ),
    ];
  }

  Future<void> _refresh() async {
    final Future<List<StockBalanceRow>> next = _load();
    setState(() {
      _rows = next;
    });
    try {
      await next;
    } catch (_) {
      // The failure is already routed to the error block through the
      // FutureBuilder; awaiting here must never rethrow into the caller.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock report'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('stock-refresh-button'),
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<StockBalanceRow>>(
        future: _rows,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<StockBalanceRow>> snap,
        ) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ReportErrorBlock(
              message: 'Could not load stock',
              onRetry: _refresh,
            );
          }
          final List<StockBalanceRow> rows = snap.data ?? <StockBalanceRow>[];
          if (rows.isEmpty) {
            return const Center(
              key: ValueKey<String>('stock-empty'),
              child: Text('No stock movements yet.'),
            );
          }
          return ListView.builder(
            key: const ValueKey<String>('stock-balances-list'),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int i) {
              final StockBalanceRow r = rows[i];
              return ListTile(
                title: Text(r.itemName),
                subtitle: Text(r.godownName),
                trailing: Text(r.qtyText),
              );
            },
          );
        },
      ),
    );
  }
}

/// Recoverable-error block with a retry action.
class _ReportErrorBlock extends StatelessWidget {
  const _ReportErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          TextButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}
