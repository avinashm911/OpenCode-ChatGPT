// NiAvERP item repository — implementation Phase 01.
// Minimal CRUD over the m001 `item` parent (item_id, company_id, name,
// unit, created_at). Full master-data scope (HSN/tax refs, units catalogue,
// aliases, search indexes) belongs to prompt 02 (M03); this repository
// exposes only columns that exist in the migrated schema — nothing invented.
// Traceability: DB v0.4 §3; DSS-C-001; DSS-C-004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One item row (minimal m001 shape).
/// One item row: m001 base plus the nullable M03.8 master columns (v9).
/// Price/stock-level/opening columns belong to Slice 4 and are absent here.
class Item {
  const Item({
    required this.id,
    required this.companyId,
    required this.name,
    required this.unit,
    required this.createdAt,
    this.code,
    this.barcode,
    this.hsnCode,
    this.gstRateBps,
    this.taxRateId,
    this.groupId,
    this.unitId,
  });

  final EntityId id;
  final CompanyId companyId;
  final String name;
  final String unit;
  final int createdAt;

  /// M03.8 (REG): item code, barcode, HSN/SAC (free text; verified schemas
  /// pending G3), GST rate snapshot in bps, link to a tax_rate_hsn row,
  /// item-group link, unit-table link.
  final String? code;
  final String? barcode;
  final String? hsnCode;
  final int? gstRateBps;
  final String? taxRateId;
  final EntityId? groupId;
  final EntityId? unitId;

  static Item fromRow(Map<String, Object?> r) => Item(
        id: EntityId(r['item_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        name: r['name'] as String,
        unit: r['unit'] as String,
        createdAt: r['created_at'] as int,
        code: r['code'] as String?,
        barcode: r['barcode'] as String?,
        hsnCode: r['hsn_code'] as String?,
        gstRateBps: r['gst_rate_bps'] as int?,
        taxRateId: r['tax_rate_id'] as String?,
        groupId: r['group_id'] == null
            ? null
            : EntityId(r['group_id'] as String),
        unitId: r['unit_id'] == null
            ? null
            : EntityId(r['unit_id'] as String),
      );
}

class ItemRepository {
  ItemRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  /// Create an item under [companyId] with operation + audit lineage.
  Result<Item> create({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    String unit = 'pcs',
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || unit.isEmpty || deviceId.isEmpty) {
      return err('validation', 'item name, unit and device id must not be empty');
    }
    Item? created;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO item (item_id, company_id, name, unit, created_at) '
          'VALUES (?, ?, ?, ?, ?)',
          <Object?>[id.value, companyId.value, name, unit, now],
        );
        final Map<String, Object?> row = <String, Object?>{
          'item_id': id.value,
          'company_id': companyId.value,
          'name': name,
          'unit': unit,
        };
        final String hash = auditPayloadHash(row);
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'item',
          entityId: id.value,
          action: 'create',
          payloadHash: hash,
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'item',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        created = Item(
          id: id,
          companyId: companyId,
          name: name,
          unit: unit,
          createdAt: now,
        );
      });
      return ok(created!);
    } on RepositoryAbort {
      // txFailure is always set before the sentinel is thrown.
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'item-create');
      return err(be.code, be.message);
    }
  }

  static const String _cols =
      'item_id, company_id, name, unit, created_at, code, barcode, hsn_code, '
      'gst_rate_bps, tax_rate_id, group_id, unit_id';

  /// Fetch one item within its company (null when absent or foreign).
  Item? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM item WHERE company_id = ? AND item_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return Item.fromRow(rows.first);
  }

  /// All items of one company, by name.
  List<Item> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM item WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <Item>[for (final Map<String, Object?> r in rows) Item.fromRow(r)];
  }

  /// Rename a base row (name/unit text) with old/new audit lineage.
  Result<Item> rename({
    required CompanyId companyId,
    required EntityId id,
    required String name,
    required String unit,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || unit.isEmpty || deviceId.isEmpty) {
      return err('validation', 'item name, unit and device id must not be empty');
    }
    final Item? before = get(companyId, id);
    if (before == null) {
      return err('not-found', 'item is absent in this company');
    }
    Item? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        _db.executeArgs(
          'UPDATE item SET name = ?, unit = ? '
          'WHERE company_id = ? AND item_id = ?',
          <Object?>[name, unit, companyId.value, id.value],
        );
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'item',
          entityId: id.value,
          action: 'update',
          payloadHash: auditPayloadHash(<String, Object?>{
            'item_id': id.value,
            'name': name,
          }),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'item',
          entityId: id.value,
          oldRow: <String, Object?>{
            'item_id': id.value,
            'name': before.name,
          },
          newRow: <String, Object?>{
            'item_id': id.value,
            'name': name,
          },
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = get(companyId, id);
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'item-rename');
      return err(be.code, be.message);
    }
  }

  /// Set the M03.8 master columns (full replacement of the nullable set)
  /// with old/new audit lineage. Group/unit/tax links must reference rows
  /// in this company (DB FKs enforce; violations return 'foreign-key').
  Result<Item> updateMaster({
    required CompanyId companyId,
    required EntityId id,
    String? code,
    String? barcode,
    String? hsnCode,
    int? gstRateBps,
    String? taxRateId,
    EntityId? groupId,
    EntityId? unitId,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (deviceId.isEmpty) {
      return err('validation', 'device id must not be empty');
    }
    if (gstRateBps != null && (gstRateBps < 0 || gstRateBps > 10000)) {
      return err('validation', 'gst rate must be within 0..10000 bps');
    }
    final Item? before = get(companyId, id);
    if (before == null) {
      return err('not-found', 'item is absent in this company');
    }
    Item? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        _db.executeArgs(
          'UPDATE item SET code = ?, barcode = ?, hsn_code = ?, '
          'gst_rate_bps = ?, tax_rate_id = ?, group_id = ?, unit_id = ? '
          'WHERE company_id = ? AND item_id = ?',
          <Object?>[
            code,
            barcode,
            hsnCode,
            gstRateBps,
            taxRateId,
            groupId?.value,
            unitId?.value,
            companyId.value,
            id.value,
          ],
        );
        final Map<String, Object?> oldRow = <String, Object?>{
          'item_id': id.value,
          if (before.code case final String c) 'code': c,
          if (before.hsnCode case final String h) 'hsn_code': h,
        };
        final Map<String, Object?> newRow = <String, Object?>{
          'item_id': id.value,
          if (code case final String c) 'code': c,
          if (hsnCode case final String h) 'hsn_code': h,
          if (gstRateBps case final int b) 'gst_rate_bps': b,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'item',
          entityId: id.value,
          action: 'update',
          payloadHash: auditPayloadHash(newRow),
        );
        if (op.isErr) {
          txFailure = (op as Err<OperationRecord>).error;
          throw const RepositoryAbort();
        }
        final Result<AuditEvent> ev = audit.append(
          eventId: eventId,
          companyId: companyId.value,
          entity: 'item',
          entityId: id.value,
          oldRow: oldRow,
          newRow: newRow,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = get(companyId, id);
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'item-master-update');
      return err(be.code, be.message);
    }
  }
}
