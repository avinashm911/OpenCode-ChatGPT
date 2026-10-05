// Home dashboard — navigation slice (OD-UI-001, G1).
// Read-only company overview over real repositories/queries: company name,
// master counts (parties, items) and the outstanding position (open bills +
// open total). No actions, no writes, no fake data: every figure is a live
// query over the scoped company.
// Traceability: OD-UI-001 (Home destination); FR-M14-001 (open position).

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
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

  Future<_HomeData> _load() async {
    await Future<void>.delayed(Duration.zero);
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

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_HomeData>(
        future: _load(),
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
                  Text('Could not load home: ${snap.error}'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
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
                subtitle: const Text('Active company'),
              ),
              ListTile(
                title: const Text('Parties'),
                trailing: Text('${d.partyCount}',
                    key: const ValueKey<String>('home-party-count')),
              ),
              ListTile(
                title: const Text('Items'),
                trailing: Text('${d.itemCount}',
                    key: const ValueKey<String>('home-item-count')),
              ),
              ListTile(
                title: const Text('Open bills'),
                subtitle: Text(
                    '₹${MoneyPaise(d.openTotal).toRupeesString()} outstanding'),
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
