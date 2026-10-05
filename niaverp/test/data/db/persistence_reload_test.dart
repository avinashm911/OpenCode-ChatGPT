// Phase 02 tests: file-backed persistence reload (M03/M12 slice).
// Uses a temporary FILE database (not in-memory): writes a company + party +
// item, closes the connection, reopens the same file, and proves the rows
// survive. This is host-level reload semantics — not an app-restart, device,
// or production-encryption claim (P-SQLIB/P-KEYSTORE remain downstream).
// Traceability: strategy Slice 2 exit (persisted slice); DSS §6.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../../helpers/test_database.dart';

void main() {
  test('rows written before close are visible after reopen', () async {
    final Directory tmp =
        await Directory.systemTemp.createTemp('niav-reload-');
    try {
      final String path = '${tmp.path}${Platform.pathSeparator}store.db';

      NiavDatabase openAt(String p) {
        final Database raw = sqlite3.open(p);
        raw.execute('PRAGMA foreign_keys = ON');
        final TestDatabase engine = TestDatabase.open(raw);
        final NiavDatabase db =
            NiavDatabase(engine, clock: testClock());
        db.sqlByVersion = loadMigrationSql();
        db.bootstrap();
        return db;
      }

      final NiavDatabase first = openAt(path);
      final RepositoryContext ctx1 = RepositoryContext(
        db: first,
        clock: testClock(),
      );
      final OperationLog ops1 = OperationLog(ctx1);
      final AuditLog audit1 = AuditLog(ctx1);
      final CompanyRepository companies =
          CompanyRepository(ctx1, ops: ops1, audit: audit1);
      final PartyRepository parties =
          PartyRepository(ctx1, ops: ops1, audit: audit1);
      final ItemRepository items =
          ItemRepository(ctx1, ops: ops1, audit: audit1);
      expect(
        companies
            .create(
              id: CompanyId('c-r'),
              name: 'Reload Co',
              deviceId: 'host-test',
              opId: 'op-cr',
              eventId: 'ev-cr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        parties
            .create(
              id: EntityId('p-r'),
              companyId: CompanyId('c-r'),
              name: 'Reload Party',
              role: 'customer',
              deviceId: 'host-test',
              opId: 'op-pr',
              eventId: 'ev-pr',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(
        items
            .create(
              id: EntityId('i-r'),
              companyId: CompanyId('c-r'),
              name: 'Reload Item',
              deviceId: 'host-test',
              opId: 'op-ir',
              eventId: 'ev-ir',
              actor: 'tester',
            )
            .isOk,
        isTrue,
      );
      expect(first.schemaVersion, kLatestVersion);
      (first.engine as TestDatabase).close();

      final NiavDatabase second = openAt(path);
      final RepositoryContext ctx2 = RepositoryContext(
        db: second,
        clock: testClock(),
      );
      final OperationLog ops2 = OperationLog(ctx2);
      final AuditLog audit2 = AuditLog(ctx2);
      final PartyRepository parties2 =
          PartyRepository(ctx2, ops: ops2, audit: audit2);
      final ItemRepository items2 =
          ItemRepository(ctx2, ops: ops2, audit: audit2);
      expect(second.schemaVersion, kLatestVersion);
      expect(
        parties2.get(CompanyId('c-r'), EntityId('p-r'))!.name,
        'Reload Party',
      );
      expect(
        items2.get(CompanyId('c-r'), EntityId('i-r'))!.name,
        'Reload Item',
      );
      (second.engine as TestDatabase).close();
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
