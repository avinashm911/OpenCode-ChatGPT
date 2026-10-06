// Home dashboard — navigation slice (OD-UI-001, G1), D4 cached.
// Read-only company overview over real repositories/queries: company name,
// master counts (parties, items) and the outstanding position (open bills +
// open total). No actions, no writes, no fake data: every figure is a live
// query over the scoped company.
// D4-C1: the query future is cached in state and refreshed only explicitly,
// so rebuilds (locale change, parent setState) never re-run queries.
// All labels resolve through [AppLocalizations] (M02.1); amounts render
// through the single [NiavFormat] formatter (M02.6).
// Traceability: OD-UI-001 (Home destination); FR-M14-001 (open position).

import 'package:flutter/material.dart';

import 'package:niaverp/application/formatting/niav_format.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// Company home: counts and the open position for [companyId].
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  State<HomeDashboardScreen> createState() => HomeDashboardScreenState();
}

class _HomeData {
  const _HomeData({
    required this.companyName,
    required this.partyCount,
    required this.itemCount,
    required this.openBills,
    required this.openTotal,
  });

  final String companyName;
  final int partyCount;
  final int itemCount;
  final int openBills;
  final int openTotal;
}

class HomeDashboardScreenState extends State<HomeDashboardScreen> {
  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;

  /// Cached query future (D4-C1): built once in initState, rebuilt only by
  /// [refresh]. Rebuilds reuse this future — no re-query.
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _query();
  }

  Future<_HomeData> _query() async {
    final String companyName =
        _scope.companies.get(_company)?.name ?? _company.value;
    final int partyCount =
        _scope.parties.listByCompany(_company).length;
    final int itemCount = _scope.items.listByCompany(_company).length;
    final List<OutstandingBill> held =
        _scope.outstanding.bills(_company, asOf: _scope.today);
    final int openTotal =
        held.fold(0, (int s, OutstandingBill b) => s + b.openPaise);
    return _HomeData(
      companyName: companyName,
      partyCount: partyCount,
      itemCount: itemCount,
      openBills: held.length,
      openTotal: openTotal,
    );
  }

  /// Explicit refresh (pulls fresh queries).
  Future<void> refresh() async {
    setState(() {
      _data = _query();
    });
    await _data;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
    return Scaffold(
      body: FutureBuilder<_HomeData>(
        future: _data,
        builder: (
          BuildContext context,
          AsyncSnapshot<_HomeData> snap,
        ) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.t('errLoadHome')),
                  TextButton(
                    onPressed: refresh,
                    child: Text(l10n.t('commonRetry')),
                  ),
                ],
              ),
            );
          }
          final _HomeData d = snap.data!;
          return ListView(
            key: const ValueKey<String>('home-dashboard'),
            children: <Widget>[
              ListTile(
                title: Text(d.companyName,
                    key: const ValueKey<String>('home-company')),
                subtitle: Text(l10n.t('homeActiveCompany')),
              ),
              ListTile(
                title: Text(l10n.t('homeParties')),
                trailing: Text('${d.partyCount}',
                    key: const ValueKey<String>('home-party-count')),
              ),
              ListTile(
                title: Text(l10n.t('homeItems')),
                trailing: Text('${d.itemCount}',
                    key: const ValueKey<String>('home-item-count')),
              ),
              ListTile(
                title: Text(l10n.t('homeOpenBills')),
                subtitle: Text(
                    '${fmt.paise(d.openTotal)} ${l10n.t('wordOutstanding')}'),
                trailing: Text('${d.openBills}',
                    key: const ValueKey<String>('home-open-count')),
              ),
            ],
          );
        },
      ),
    );
  }
}
