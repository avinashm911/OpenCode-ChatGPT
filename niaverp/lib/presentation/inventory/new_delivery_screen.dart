// New delivery note entry — thin configuration over the shared voucher
// draft form (voucher_form_screen.dart). Keys are `dn-*`; the customer is
// picked with role 'customer'; stock moves out of the godown at post time.
// Delivery notes convert to invoices (M09) rather than settling, so the
// invoice view offers no settlement button afterwards.
// Traceability: FR-M07-001; FR-M04-001/002; D-M4; FR-M13-001.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/billing/voucher_form_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// New delivery note for [companyId].
class NewDeliveryScreen extends StatelessWidget {
  const NewDeliveryScreen({
    super.key,
    required this.companyId,
    required this.scope,
  });

  final CompanyId companyId;
  final CompanyScope scope;

  @override
  Widget build(BuildContext context) {
    return VoucherFormScreen(
      companyId: companyId,
      scope: scope,
      config: deliveryFormConfig,
    );
  }
}
