// New sales invoice entry — thin configuration over the shared voucher
// draft form (voucher_form_screen.dart). Keys stay `sale-*`.
// Traceability: FR-M05-001; FR-M04-001/002; D-M4; FR-M13-001.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/billing/voucher_form_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// New sales invoice for [companyId].
class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({
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
      config: saleFormConfig,
    );
  }
}
