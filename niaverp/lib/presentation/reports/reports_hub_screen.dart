// Reports hub — navigation slice (OD-UI-001, G1).
// Three real destinations, all live screens over real queries: the stock
// report (balances + book values), the outstanding report (open bills +
// totals) and the books report (day book / voucher register, trial balance,
// ledger account). Tapping a row pushes the screen with the scoped company
// bound. Every report is a projection of posted transactions — no report
// carries its own arithmetic.
// Traceability: OD-UI-001 (Reports destination); UI-009/UI-010;
// FR-M14-001; M14.1/14.2/14.6.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/reports/books_report_screen.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ListView(
        key: const ValueKey<String>('reports-hub'),
        children: <Widget>[
        ListTile(
          key: const ValueKey<String>('reports-hub-stock'),
          title: Text(l10n.t('reportsStock')),
          subtitle: Text(l10n.t('reportsStockSub')),
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
          title: Text(l10n.t('reportsOutstanding')),
          subtitle: Text(l10n.t('reportsOutstandingSub')),
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
        ListTile(
          key: const ValueKey<String>('reports-hub-books'),
          title: Text(l10n.t('reportsBooks')),
          subtitle: Text(l10n.t('reportsBooksSub')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => BooksReportScreen(
                companyId: companyId,
                books: scope.books,
                ledgers: scope.ledgers,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
