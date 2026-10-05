// Billing hub — navigation slice (OD-UI-001, G1).
// Read-only bill list over the real [OutstandingReport]: every open bill
// with its open amount, state and age, plus entry points to the five live
// document forms. Loading/error states ride a FutureBuilder like the other
// reports (the open-balance reads can throw on impossible history).
// Traceability: OD-UI-001 (Billing destination); FR-M14-001.

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
import 'package:niaverp/presentation/billing/new_purchase_screen.dart';
import 'package:niaverp/presentation/billing/new_sale_screen.dart';
import 'package:niaverp/presentation/inventory/new_delivery_screen.dart';
import 'package:niaverp/presentation/inventory/new_stock_journal_screen.dart';
import 'package:niaverp/presentation/inventory/new_transfer_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// Open bills for [companyId]. Read-only.
class BillingHubScreen extends StatefulWidget {
  const BillingHubScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  State<BillingHubScreen> createState() => BillingHubScreenState();
}

class BillingHubScreenState extends State<BillingHubScreen> {
  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;

  Future<List<OutstandingBill>> _load() async {
    await Future<void>.delayed(Duration.zero);
    return _scope.outstanding.bills(_company, asOf: _scope.today);
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: <Widget>[
                FilledButton(
                  key: const ValueKey<String>('billing-new-sale'),
                  onPressed: () => _open(NewSaleScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: const Text('New Sale'),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-purchase'),
                  onPressed: () => _open(NewPurchaseScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: const Text('New Purchase'),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-delivery'),
                  onPressed: () => _open(NewDeliveryScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: const Text('Delivery'),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-transfer'),
                  onPressed: () => _open(NewTransferScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: const Text('Transfer'),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-journal'),
                  onPressed: () => _open(NewStockJournalScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: const Text('Stock Journal'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OutstandingBill>>(
              future: _load(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<OutstandingBill>> snap,
              ) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Could not load bills: ${snap.error}'),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final List<OutstandingBill> held = snap.data ?? <OutstandingBill>[];
                if (held.isEmpty) {
                  return const Center(
                    key: ValueKey<String>('billing-empty'),
                    child: Text('No open bills.'),
                  );
                }
                return ListView.builder(
                  key: const ValueKey<String>('billing-bills-list'),
                  itemCount: held.length,
                  itemBuilder: (BuildContext context, int i) {
                    final OutstandingBill b = held[i];
                    return ListTile(
                      title: Text('${b.voucherNo} · ${b.voucherType}'),
                      subtitle: Text('${b.state} · ${b.ageDays}d'),
                      trailing: Text(
                          '₹${MoneyPaise(b.openPaise).toRupeesString()}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
