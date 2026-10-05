// NiAvERP unit + item-group repositories — Phase 02 (M03.7/M03.9, G1).
// Units carry the documented conversion shape (base unit, factor, scale per
// DSS §3); conversion ARITHMETIC is later policy (prompt 04) — this slice
// stores and validates the shape only. Name uniqueness per company is
// DB-enforced (uq_unit_company_name / group UNIQUE). Item groups form an
// optional tree (parent_id, M03.7 hierarchical grouping).
// Traceability: REG M03.7/M03.9; DSS §3; DB §3; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One unit row. [factor] counts base-unit multiples (e.g. Box of 12 Nos →
/// factor 12 against the Nos row); [scale] is display decimals 0–4.
/// Conversion use is later policy — stored, not applied, here.
class Unit {
  const Unit({
    required this.id,
    required this.companyId,
    required this.name,
    this.baseUnitId,
    required this.factor,
    this.scale,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String name;
  final EntityId? baseUnitId;
  final int factor;
  final int? scale;
  final int createdAt;

  static Unit fromRow(Map<String, Object?> r) => Unit(
        id: EntityId(r['unit_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        name: r['name'] as String,
        baseUnitId: r['base_unit_id'] == null
            ? null
            : EntityId(r['base_unit_id'] as String),
        factor: r['factor'] as int,
        scale: r['scale'] as int?,
        createdAt: r['created_at'] as int,
      );
}

/// One item-group row (M03.7 hierarchical grouping).
class ItemGroup {
  const ItemGroup({
    required this.id,
    required this.companyId,
    this.parentId,
    required this.name,
    this.costMethod,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId? parentId;
  final String name;

  /// Group valuation default ('fifo'/'wa'/null = unset, D-M5).
  final String? costMethod;
  final int createdAt;

  static ItemGroup fromRow(Map<String, Object?> r) => ItemGroup(
        id: EntityId(r['group_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        parentId: r['parent_id'] == null
            ? null
            : EntityId(r['parent_id'] as String),
        name: r['name'] as String,
        costMethod: r.containsKey('cost_method')
            ? r['cost_method'] as String?
            : null,
        createdAt: r['created_at'] as int,
      );
}

class UnitRepository {
  UnitRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'unit_id, company_id, name, base_unit_id, factor, scale, created_at';

  Result<Unit> create({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    EntityId? baseUnitId,
    int factor = 1,
    int? scale,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'unit name and device id must not be empty');
    }
    if (factor <= 0) {
      return err('validation', 'unit factor must be > 0');
    }
    if (scale != null && (scale < 0 || scale > 4)) {
      return err('validation', 'unit scale must be 0..4');
    }
    Unit? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO unit (unit_id, company_id, name, base_unit_id, '
          'factor, scale, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            name,
            baseUnitId?.value,
            factor,
            scale,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'unit_id': id.value,
          'company_id': companyId.value,
          'name': name,
          'factor': factor,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'unit',
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
          entity: 'unit',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = Unit(
          id: id,
          companyId: companyId,
          name: name,
          baseUnitId: baseUnitId,
          factor: factor,
          scale: scale,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'unit-create');
      return err(be.code, be.message);
    }
  }

  Unit? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM unit WHERE company_id = ? AND unit_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return Unit.fromRow(rows.first);
  }

  List<Unit> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM unit WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <Unit>[for (final Map<String, Object?> r in rows) Unit.fromRow(r)];
  }
}

class ItemGroupRepository {
  ItemGroupRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'group_id, company_id, parent_id, name, cost_method, created_at';

  /// Maximum ancestor hops followed when validating a parent link. Bounds
  /// the walk so a corrupt pre-existing chain can never hang creation.
  static const int _maxHierarchyDepth = 64;

  /// Parent row in the same company, or null when absent there. The SQL FK
  /// alone cannot enforce company scope on `parent_id`, so this pre-check
  /// keeps cross-company parents out (DSS-C-001).
  Map<String, Object?>? _parentRow(CompanyId companyId, EntityId parentId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT group_id, parent_id FROM item_group '
      'WHERE company_id = ? AND group_id = ?',
      <Object?>[companyId.value, parentId.value],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Result<ItemGroup> create({
    required EntityId id,
    required CompanyId companyId,
    EntityId? parentId,
    required String name,
    String? costMethod,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'group name and device id must not be empty');
    }
    if (costMethod != null && costMethod != 'fifo' && costMethod != 'wa') {
      return err('validation', 'cost method must be fifo or wa');
    }
    if (parentId != null) {
      // No circular hierarchy (FR-M03-001): a group must not be its own
      // ancestor. Fresh ids can only self-reference, but the walk below
      // also guards pre-existing corrupt chains.
      if (parentId == id) {
        return err('validation', 'group must not be its own parent');
      }
      Map<String, Object?>? current = _parentRow(companyId, parentId);
      if (current == null) {
        return err('foreign-key', 'referenced parent row is missing');
      }
      final Set<String> seen = <String>{id.value, parentId.value};
      int hops = 0;
      while (current!['parent_id'] != null) {
        hops += 1;
        if (hops > _maxHierarchyDepth) {
          return err('validation', 'group hierarchy is too deep or cyclic');
        }
        final String next = current['parent_id'] as String;
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
    ItemGroup? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO item_group (group_id, company_id, parent_id, name, '
          'cost_method, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            parentId?.value,
            name,
            costMethod,
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
          entity: 'item_group',
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
          entity: 'item_group',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = ItemGroup(
          id: id,
          companyId: companyId,
          parentId: parentId,
          name: name,
          costMethod: costMethod,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'item-group-create');
      return err(be.code, be.message);
    }
  }

  ItemGroup? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM item_group WHERE company_id = ? AND group_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return ItemGroup.fromRow(rows.first);
  }

  List<ItemGroup> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM item_group WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <ItemGroup>[
      for (final Map<String, Object?> r in rows) ItemGroup.fromRow(r),
    ];
  }
}
