// Negative test: audit events are append-only (FR-M18-002).
// Proves no ordinary-user path can silently edit or delete audit history:
// no UPDATE/DELETE statement targets audit_event anywhere in lib/, the
// AuditLog API exposes only append + read, and appended events persist
// intact. Review-screen UI lands with the frontend slice (prompt 11).
// Traceability: FR-M18-002 (append-only event; not silently editable or
// deletable); OD-DB-004; DSS-C-003.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/repositories/audit_log.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/operation_log.dart';
import 'package:niaverp/data/repositories/repository.dart';

import '../helpers/test_database.dart';

/// All Dart sources under lib/ (package root is the `flutter test` cwd).
List<File> _libSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  group('audit append-only (FR-M18-002, negative)', () {
    test('no UPDATE/DELETE statement targets audit_event in lib/', () {
      final RegExp auditRef = RegExp(r'audit_event');
      final RegExp mutating = RegExp(r'\b(UPDATE|DELETE)\b', caseSensitive: false);
      final List<String> hits = <String>[];
      for (final File f in _libSources()) {
        for (final String line in f.readAsLinesSync()) {
          if (auditRef.hasMatch(line) && mutating.hasMatch(line)) {
            hits.add('${f.path}: $line');
          }
        }
      }
      expect(hits, isEmpty, reason: 'audit mutation found: $hits');
    });

    test('AuditLog exposes only append and read methods', () {
      final RegExp def = RegExp(
          r'^\s*(Result<[^>]*>|List<[^>]*>|void)\s+(\w+)\s*\(');
      const Set<String> forbidden = <String>{
        'update',
        'delete',
        'remove',
        'purge',
        'edit',
        'clear',
      };
      final Set<String> names = <String>{};
      for (final String line
          in File('lib/data/repositories/audit_log.dart').readAsLinesSync()) {
        final RegExpMatch? m = def.firstMatch(line);
        if (m != null) names.add(m.group(2)!);
      }
      expect(names, contains('append'));
      expect(names, contains('forEntity'));
      expect(names.intersection(forbidden), isEmpty);
    });

    test('appended events persist intact; empty actor rejected', () {
      final NiavDatabase db = openTestDatabase();
      try {
        final RepositoryContext ctx = testContext(db);
        final OperationLog ops = OperationLog(ctx);
        final AuditLog audit = AuditLog(ctx);
        final CompanyRepository companies =
            CompanyRepository(ctx, ops: ops, audit: audit);
        expect(
          companies
              .create(
                id: CompanyId('c-a'),
                name: 'Audit Co',
                deviceId: 'host-test',
                opId: 'op-ca',
                eventId: 'ev-ca',
                actor: 'tester',
              )
              .isOk,
          isTrue,
        );
        final Result<AuditEvent> r = audit.append(
          eventId: 'ev-1',
          companyId: 'c-a',
          entity: 'voucher',
          entityId: 'v-1',
          oldRow: const <String, Object?>{'status': 'draft'},
          newRow: const <String, Object?>{'status': 'posted'},
          actor: 'tester',
        );
        expect(r.isOk, isTrue);
        final List<AuditEvent> back =
            audit.forEntity('c-a', 'voucher', 'v-1');
        expect(back, hasLength(1));
        expect(back.first.oldData, contains('draft'));
        expect(back.first.newData, contains('posted'));
        expect(back.first.actor, 'tester');
        final Result<AuditEvent> bad = audit.append(
          eventId: 'ev-2',
          companyId: 'c-a',
          entity: 'voucher',
          entityId: 'v-1',
          actor: '',
        );
        expect(bad.isErr, isTrue);
        expect((bad as Err<AuditEvent>).error.code, 'validation');
        expect(
          audit.forEntity('c-a', 'voucher', 'v-1'),
          hasLength(1),
        );
      } finally {
        rawEngineOf(db).close();
      }
    });
  });
}
