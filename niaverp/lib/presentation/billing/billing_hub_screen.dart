// Billing hub — navigation slice (OD-UI-001, G1).
// Read-only bill list over the real [OutstandingReport]: every open bill
// with its open amount, state and age, plus entry points to the five live
// document forms. Loading/error states ride a FutureBuilder like the other
// reports (the open-balance reads can throw on impossible history).
// Traceability: OD-UI-001 (Billing destination); FR-M14-001.

import 'package:flutter/material.dart';

import 'package:niaverp/application/formatting/niav_format.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/billing/ledger_voucher_form_screen.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
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
                  child: Text(l10n.t('hubNewSale')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-purchase'),
                  onPressed: () => _open(NewPurchaseScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: Text(l10n.t('hubNewPurchase')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-delivery'),
                  onPressed: () => _open(NewDeliveryScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: Text(l10n.t('hubDelivery')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-transfer'),
                  onPressed: () => _open(NewTransferScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: Text(l10n.t('hubTransfer')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-journal'),
                  onPressed: () => _open(NewStockJournalScreen(
                    companyId: _company,
                    scope: _scope,
                  )),
                  child: Text(l10n.t('hubStockJournal')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-receipt'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: receiptFormConfig,
                  )),
                  child: Text(l10n.t('hubReceipt')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-payment'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: paymentFormConfig,
                  )),
                  child: Text(l10n.t('hubPayment')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-contra'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: contraFormConfig,
                  )),
                  child: Text(l10n.t('hubContra')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-ledger-journal'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: journalFormConfig,
                  )),
                  child: Text(l10n.t('hubJournal')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-debit-note'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: debitNoteFormConfig,
                  )),
                  child: Text(l10n.t('hubDebitNote')),
                ),
                FilledButton(
                  key: const ValueKey<String>('billing-new-credit-note'),
                  onPressed: () => _open(LedgerVoucherFormScreen(
                    companyId: _company,
                    scope: _scope,
                    config: creditNoteFormConfig,
                  )),
                  child: Text(l10n.t('hubCreditNote')),
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
                        Text(l10n.t('errLoadBills')),
                        TextButton(
                          onPressed: _refresh,
                          child: Text(l10n.t('commonRetry')),
                        ),
                      ],
                    ),
                  );
                }
                final List<OutstandingBill> held = snap.data ?? <OutstandingBill>[];
                if (held.isEmpty) {
                  return Center(
                    key: const ValueKey<String>('billing-empty'),
                    child: Text(l10n.t('hubNoOpenBills')),
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
                      trailing: Text(fmt.paise(b.openPaise)),
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
