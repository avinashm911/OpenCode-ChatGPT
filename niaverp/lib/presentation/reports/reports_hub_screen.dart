// Reports hub — navigation slice (OD-UI-001, G1).
// Two real destinations, both live screens over real queries: the stock
// report (balances + book values) and the outstanding report (open bills +
// totals). Tapping a row pushes the screen with the scoped company bound.
// Traceability: OD-UI-001 (Reports destination); UI-009/UI-010; FR-M14-001.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/reports/outstanding_report_screen.dart';
import 'package:niaverp/presentation/reports/stock_report_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// Report picker for [companyId].
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        key: const ValueKey<String>('reports-hub'),
        children: <Widget>[
        ListTile(
          key: const ValueKey<String>('reports-hub-stock'),
          title: const Text('Stock report'),
          subtitle: const Text('Balances and book values'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => StockReportScreen(
                companyId: companyId,
                levels: scope.stock,
                items: scope.items,
                godowns: scope.godowns,
              ),
            ),
          ),
        ),
        ListTile(
          key: const ValueKey<String>('reports-hub-outstanding'),
          title: const Text('Outstanding report'),
          subtitle: const Text('Open bills and totals'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => OutstandingReportScreen(
                companyId: companyId,
                report: scope.outstanding,
                asOf: scope.today,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
