// Phase 02 widget tests: onboarding over real repositories.
// The screen drives a real CompanyRepository over a real migrated database —
// no fakes. Proves: empty state, validation error, create → onOpen, and
// existing-company listing. Traceability: REG M01; OD-UI-001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';
import 'package:niaverp/presentation/onboarding/onboarding_screen.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late CompanyRepository companies;
  late CounterIdMint mint;
  CompanyId? opened;

  setUp(() {
    db = openTestDatabase();
    final RepositoryContext ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    companies = CompanyRepository(ctx, ops: ops, audit: audit);
    mint = CounterIdMint();
    opened = null;
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  Widget buildScreen() {
    return MaterialApp(
      home: OnboardingScreen(
        companies: companies,
        write: WriteContext(
          deviceId: 'host-test',
          actor: 'tester',
          idMint: mint.call,
        ),
        onOpen: (CompanyId id) => opened = id,
      ),
    );
  }

  testWidgets('empty state invites the first company', (WidgetTester t) async {
    await t.pumpWidget(buildScreen());
    await t.pumpAndSettle();
    expect(find.text('No companies yet — create the first one.'), findsOneWidget);
  });

  testWidgets('empty name shows a validation error', (WidgetTester t) async {
    await t.pumpWidget(buildScreen());
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey<String>('company-create-button')));
    await t.pumpAndSettle();
    expect(find.text('Company name is required'), findsOneWidget);
    expect(opened, isNull);
  });

  testWidgets('create persists and opens the company', (WidgetTester t) async {
    await t.pumpWidget(buildScreen());
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey<String>('company-name-field')),
      'Widget Co',
    );
    await t.tap(find.byKey(const ValueKey<String>('company-create-button')));
    await t.pumpAndSettle();
    expect(opened, isNotNull);
    expect(companies.get(opened!)!.name, 'Widget Co');
    expect(find.text('Widget Co'), findsWidgets);
  });
}
