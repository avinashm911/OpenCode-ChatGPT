// NiAvERP outstanding report screen — settlement slice (FR-M14-001, G1).
// Read-only bill-wise settlement report over the real [OutstandingReport]
// query: one row per open bill (voucher no/type, open ₹, state, age) plus a
// totals header (bill count + open total). States: loading, empty, success,
// recoverable-error with retry (FutureBuilder + error block, onboarding
// pattern). Validation/locked states are N/A: this screen takes no input
// and posts nothing. Main-app wiring waits on the production database
// engine (P-SQLIB), like the other report screens.
// Traceability: FR-M14-001 (outstanding reports); FR-M06-001/002.

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';

/// One rendered bill row (open amount, state and age).
class OutstandingBillRow {
  const OutstandingBillRow({
    required this.voucherNo,
    required this.voucherType,
    required this.openPaise,
    required this.state,
    required this.ageDays,
  });

  final String voucherNo;
  final String voucherType;
  final int openPaise;
  final String state;
  final int ageDays;

  String get openText => '₹${MoneyPaise(openPaise).toRupeesString()}';
  String get metaText => '$voucherType · $state · ${ageDays}d';
}

/// Company outstanding bills, read from posted vouchers and allocations.
class OutstandingReportScreen extends StatefulWidget {
  const OutstandingReportScreen({
    super.key,
    required this.companyId,
    required this.report,
    required this.asOf,
  });

  final CompanyId companyId;
  final OutstandingReport report;
  final NiavDate asOf;

  @override
  State<OutstandingReportScreen> createState() =>
      OutstandingReportScreenState();
}

class OutstandingReportScreenState
    extends State<OutstandingReportScreen> {
  late Future<List<OutstandingBillRow>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<OutstandingBillRow>> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return <OutstandingBillRow>[];
    final List<OutstandingBill> bills =
        widget.report.bills(widget.companyId, asOf: widget.asOf);
    return <OutstandingBillRow>[
      for (final OutstandingBill b in bills)
        OutstandingBillRow(
          voucherNo: b.voucherNo,
          voucherType: b.voucherType,
          openPaise: b.openPaise,
          state: b.state,
          ageDays: b.ageDays,
        ),
    ];
  }

  Future<void> _refresh() async {
    final Future<List<OutstandingBillRow>> next = _load();
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
        title: const Text('Outstanding report'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('outstanding-refresh-button'),
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<OutstandingBillRow>>(
        future: _rows,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<OutstandingBillRow>> snap,
        ) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ReportErrorBlock(
              message: 'Could not load outstanding',
              onRetry: _refresh,
            );
          }
          final List<OutstandingBillRow> rows = snap.data ?? <OutstandingBillRow>[];
          if (rows.isEmpty) {
            return const Center(
              key: ValueKey<String>('outstanding-empty'),
              child: Text('No outstanding bills.'),
            );
          }
          final int total =
              rows.fold(0, (int s, OutstandingBillRow r) => s + r.openPaise);
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${rows.length} bills · '
                  '₹${MoneyPaise(total).toRupeesString()} open',
                  key: const ValueKey<String>('outstanding-total'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey<String>('outstanding-bills-list'),
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int i) {
                    final OutstandingBillRow r = rows[i];
                    return ListTile(
                      title: Text(r.voucherNo),
                      subtitle: Text(r.metaText),
                      trailing: Text(r.openText),
                    );
                  },
                ),
              ),
            ],
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
