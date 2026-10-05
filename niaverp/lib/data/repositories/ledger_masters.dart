// NiAvERP ledger-master repositories — posting slice (FR-M03-002, G1).
// Storage for the m013 tables (DB §3 exact shape): account_group self-tree
// and ledger identity + group + opening side/value + bill-wise flag.
// Balances are derived by query (DSS projection model), never stored here.
// Group guards mirror the item-group precedent (self-parent, same-company
// parent, bounded ancestor walk). Duplicate ledger names collide per
// company (FR-M03-002). An opening amount without a side is ambiguous and
// rejected; zero openings may leave the side null. Contact/address/bank/
// GST detail columns wait on their specs. Every write carries operation +
// audit lineage. Traceability: FR-M03-002; DB §3; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One account-group row.
class AccountGroup {
  const AccountGroup({
    required this.id,
    required this.companyId,
    this.parentId,
    required this.name,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId? parentId;
  final String name;
  final int createdAt;

  static AccountGroup fromRow(Map<String, Object?> r) => AccountGroup(
        id: EntityId(r['group_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        parentId: r['parent_group_id'] == null
            ? null
            : EntityId(r['parent_group_id'] as String),
        name: r['name'] as String,
        createdAt: r['created_at'] as int,
      );
}

/// One ledger row.
class Ledger {
  const Ledger({
    required this.id,
    required this.companyId,
    required this.groupId,
    required this.name,
    this.openingSide,
    required this.openingPaise,
    required this.billwise,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId groupId;
  final String name;
  final String? openingSide;
  final int openingPaise;
  final bool billwise;
  final int createdAt;

  /// Signed opening for balance math: Dr positive, Cr negative, none zero.
  int get signedOpening =>
      openingSide == 'Cr' ? -openingPaise : openingPaise;

  static Ledger fromRow(Map<String, Object?> r) => Ledger(
        id: EntityId(r['ledger_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        groupId: EntityId(r['group_id'] as String),
        name: r['name'] as String,
        openingSide: r['opening_side'] as String?,
        openingPaise: r['opening_paise'] as int,
        billwise: (r['billwise'] as int) != 0,
        createdAt: r['created_at'] as int,
      );
}

class AccountGroupRepository {
  AccountGroupRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const int _maxDepth = 64;

  Map<String, Object?>? _parentRow(CompanyId companyId, EntityId parentId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT group_id, parent_group_id FROM account_group '
      'WHERE company_id = ? AND group_id = ?',
      <Object?>[companyId.value, parentId.value],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Result<AccountGroup> create({
    required EntityId id,
    required CompanyId companyId,
    EntityId? parentId,
    required String name,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'group name and device id must not be empty');
    }
    if (parentId != null) {
      if (parentId == id) {
        return err('validation', 'group must not be its own parent');
      }
      Map<String, Object?>? current = _parentRow(companyId, parentId);
      if (current == null) {
        return err('foreign-key', 'referenced parent row is missing');
      }
      final Set<String> seen = <String>{id.value, parentId.value};
      int hops = 0;
      while (current!['parent_group_id'] != null) {
        hops += 1;
        if (hops > _maxDepth) {
          return err('validation', 'group hierarchy is too deep or cyclic');
        }
        final String next = current['parent_group_id'] as String;
        if (!seen.add(next)) {
          return err(
              'validation', 'group hierarchy must not contain a cycle');
        }
        current = _parentRow(companyId, EntityId(next));
        if (current == null) {
          return err('foreign-key', 'referenced parent row is missing');
        }
      }
    }
    AccountGroup? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO account_group (group_id, company_id, parent_group_id, '
          'name, created_at) VALUES (?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            parentId?.value,
            name,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'group_id': id.value,
          'company_id': companyId.value,
          'name': name,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'account_group',
          entityId: id.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'account_group',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = AccountGroup(
          id: id,
          companyId: companyId,
          parentId: parentId,
          name: name,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'account-group-create');
      return err(be.code, be.message);
    }
  }

  AccountGroup? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT group_id, company_id, parent_group_id, name, created_at '
      'FROM account_group WHERE company_id = ? AND group_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return AccountGroup.fromRow(rows.first);
  }

  List<AccountGroup> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT group_id, company_id, parent_group_id, name, created_at '
      'FROM account_group WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <AccountGroup>[
      for (final Map<String, Object?> r in rows) AccountGroup.fromRow(r),
    ];
  }
}

class LedgerRepository {
  LedgerRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'ledger_id, company_id, group_id, name, opening_side, opening_paise, '
      'billwise, created_at';

  Result<Ledger> create({
    required EntityId id,
    required CompanyId companyId,
    required EntityId groupId,
    required String name,
    String? openingSide,
    int openingPaise = 0,
    bool billwise = false,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'ledger name and device id must not be empty');
    }
    if (openingSide != null && openingSide != 'Dr' && openingSide != 'Cr') {
      return err('validation', 'opening side must be Dr or Cr');
    }
    if (openingPaise < 0) {
      return err('validation', 'opening amount must be >= 0');
    }
    if (openingPaise > 0 && openingSide == null) {
      return err('validation', 'a nonzero opening needs an explicit side');
    }
    final List<Map<String, Object?>> group = _db.queryArgs(
      'SELECT group_id FROM account_group WHERE company_id = ? AND group_id = ?',
      <Object?>[companyId.value, groupId.value],
    );
    if (group.isEmpty) {
      return err('foreign-key', 'ledger group must exist in this company');
    }
    Ledger? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
          'opening_side, opening_paise, billwise, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            groupId.value,
            name,
            openingSide,
            openingPaise,
            billwise ? 1 : 0,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'ledger_id': id.value,
          'company_id': companyId.value,
          'group_id': groupId.value,
          'name': name,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'ledger',
          entityId: id.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'ledger',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = Ledger(
          id: id,
          companyId: companyId,
          groupId: groupId,
          name: name,
          openingSide: openingSide,
          openingPaise: openingPaise,
          billwise: billwise,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'ledger-create');
      return err(be.code, be.message);
    }
  }

  Ledger? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM ledger WHERE company_id = ? AND ledger_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return Ledger.fromRow(rows.first);
  }

  List<Ledger> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM ledger WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <Ledger>[for (final Map<String, Object?> r in rows) Ledger.fromRow(r)];
  }
}
