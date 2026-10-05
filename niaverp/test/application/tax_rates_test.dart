// Prompt-07 tests: effective-dated HSN rate lookup (FR-M16-001 structure).
// Disposable in-memory databases only (rate rows are synthetic fixtures, not
// statutory values — the table ships empty pending G3 verification).
// Proves: latest covering row wins, range ends are inclusive, gaps/unknown
// codes/empty tables yield null, company isolation holds, and negative rates
// are refused by the schema CHECK.
// Traceability: FR-M16-001; G0-SCH-004; OD-DB-003; DSS-O03 (values pending).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/queries/tax_rates.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;
  late RepositoryContext ctx;

  setUp(() {
    db = openTestDatabase();
    ctx = testContext(db);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final CompanyRepository companies =
        CompanyRepository(ctx, ops: ops, audit: audit);
    for (final String c in <String>['c-t', 'c-other']) {
      expect(
        companies
            .create(
              id: CompanyId(c),
              name: 'Co $c',
              deviceId: 'host-test',
              opId: 'op-$c',
              eventId: 'ev-$c',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
    }
  });

  tearDown(() {
    rawEngineOf(db).close();
  });

  void insertRate(
    String id,
    String company,
    String hsn,
    int bps,
    String from,
    String? to,
  ) {
    db.executeArgs(
      'INSERT INTO tax_rate_hsn (rate_id, company_id, hsn_code, rate_bps, '
      'effective_from, effective_to) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[id, company, hsn, bps, from, to],
    );
  }

  group('HSN rate lookup (FR-M16-001 structure)', () {
    test('latest covering row wins; ends inclusive', () {
      insertRate('r-1', 'c-t', '3004', 1200, '2023-01-01', null);
      insertRate('r-2', 'c-t', '3004', 1800, '2024-06-01', '2025-05-31');
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2023-06-01'), 1200);
      // New row effective: later from wins while both cover.
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2024-06-01'), 1800);
      // effective_to inclusive; day after falls back to open row.
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2025-05-31'), 1800);
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2025-06-01'), 1200);
    });

    test('gaps, unknown codes and empty tables yield null', () {
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2026-01-01'), isNull);
      insertRate('r-1', 'c-t', '3004', 1800, '2024-01-01', '2024-12-31');
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2023-12-31'), isNull);
      expect(hsnRateBps(db, CompanyId('c-t'), '9999', '2024-06-01'), isNull);
    });

    test('lookup stays within the requesting company', () {
      insertRate('r-1', 'c-other', '3004', 2800, '2024-01-01', null);
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2024-06-01'), isNull);
      expect(
        hsnRateBps(db, CompanyId('c-other'), '3004', '2024-06-01'),
        2800,
      );
    });

    test('negative rates are refused by the schema CHECK', () {
      expect(
        () => insertRate('r-bad', 'c-t', '3004', -100, '2024-01-01', null),
        throwsException,
      );
      expect(hsnRateBps(db, CompanyId('c-t'), '3004', '2024-06-01'), isNull);
    });
  });
}
