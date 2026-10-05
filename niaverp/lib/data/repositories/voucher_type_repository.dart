// NiAvERP voucher type/series registry + godown repositories — Phase 02,
// extended by prompt 04 (M04 P1 registry rules, gate G1).
// Voucher types/series store the M04 registry shape (base type, naming
// parts, numbering seeds) per DSS §3 / REG M03.16; NEXT-NUMBER COMPUTATION,
// restart-cycle semantics and gap reports stay a downstream boundary
// (FR-M04-002 scope rules TBD) — this slice enforces registry validity only
// (known base type, no duplicate series configuration in its scope).
// Godown enforces the documented per-company name uniqueness at repository
// level (uq_godown_company_name); the m001 table predates the UNIQUE clause,
// so the check lives here with an explicit boundary until a rebuild
// migration carries it.
// Traceability: REG M03.10/M03.16; FR-M04-001/002; DSS §3; DB §3;
// DSS-C-001/004; OD-DB-004; DECISIONS.md (19 voucher types).

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// Canonical predefined voucher types, exact names from the implementation
/// ledger (niaverp/DECISIONS.md voucher list). User-created types must derive
/// from one of these (FR-M04-001: base type must exist). No type may be
/// omitted silently: this list is exhaustive for V1.
const List<String> kCanonicalVoucherTypes = <String>[
  'Sales Invoice',
  'Purchase Invoice',
  'Sales Return / Credit Note with items',
  'Purchase Return / Debit Note with items',
  'Payment',
  'Receipt',
  'Contra',
  'Journal',
  'Debit Note without items',
  'Credit Note without items',
  'Delivery Note / Delivery Challan',
  'Material Issue to Party',
  'Material Receive from Party',
  'Stock Transfer',
  'Stock Journal',
  'Sales Quotation / Proforma Invoice',
  'Purchase Quotation',
  'Sales Order',
  'Purchase Order',
];

/// Mechanical slug of a canonical name: lowercase, every run of
/// non-alphanumeric characters becomes one `-`, trimmed. Documented encoding
/// only — the authoritative values remain the names above.
String voucherBaseSlug(String name) {
  final StringBuffer out = StringBuffer();
  bool dash = false;
  for (final int rune in name.toLowerCase().runes) {
    final bool alnum = (rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57);
    if (alnum) {
      out.writeCharCode(rune);
      dash = false;
    } else if (!dash) {
      out.write('-');
      dash = true;
    }
  }
  String slug = out.toString();
  while (slug.startsWith('-')) {
    slug = slug.substring(1);
  }
  while (slug.endsWith('-')) {
    slug = slug.substring(0, slug.length - 1);
  }
  return slug;
}

/// True when [baseType] is a canonical name or its mechanical slug.
bool isKnownVoucherBaseType(String baseType) {
  final String q = baseType.trim();
  if (q.isEmpty) return false;
  for (final String name in kCanonicalVoucherTypes) {
    if (q == name || q == voucherBaseSlug(name)) return true;
  }
  return false;
}

/// One voucher-type row. [baseType] must be a known canonical base
/// ([isKnownVoucherBaseType]); engine behavior families stay unresolved
/// here (downstream voucher-engine boundary).
class VoucherType {
  const VoucherType({
    required this.id,
    required this.companyId,
    required this.baseType,
    required this.name,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String baseType;
  final String name;
  final int createdAt;

  static VoucherType fromRow(Map<String, Object?> r) => VoucherType(
        id: EntityId(r['type_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        baseType: r['base_type'] as String,
        name: r['name'] as String,
        createdAt: r['created_at'] as int,
      );
}

/// One numbering-series row. Seed/shape storage only; generation lives in
/// the numbering engine (FR-M04-002). [mode] selects automatic numbering;
/// NULL/manual never generates (safe default). Separators are part of the
/// literal [prefix]/[suffix] (no separator column exists in either schema
/// doc). [restart] runs continuous when NULL/`never`; other cycles are
/// rejected by the engine until the vocabulary is decided.
class VoucherSeries {
  const VoucherSeries({
    required this.id,
    required this.companyId,
    required this.typeId,
    required this.name,
    this.prefix,
    this.suffix,
    required this.startNo,
    required this.width,
    this.restart,
    this.mode,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId typeId;
  final String name;
  final String? prefix;
  final String? suffix;
  final int startNo;
  final int width;
  final String? restart;
  final String? mode;
  final int createdAt;

  static VoucherSeries fromRow(Map<String, Object?> r) => VoucherSeries(
        id: EntityId(r['series_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        typeId: EntityId(r['type_id'] as String),
        name: r['name'] as String,
        prefix: r['prefix'] as String?,
        suffix: r['suffix'] as String?,
        startNo: r['start_no'] as int,
        width: r['width'] as int,
        restart: r['restart'] as String?,
        mode: r['mode'] as String?,
        createdAt: r['created_at'] as int,
      );
}

/// One godown row (m001 shape).
class Godown {
  const Godown({
    required this.id,
    required this.companyId,
    required this.name,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String name;
  final int createdAt;

  static Godown fromRow(Map<String, Object?> r) => Godown(
        id: EntityId(r['godown_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        name: r['name'] as String,
        createdAt: r['created_at'] as int,
      );
}

class VoucherTypeRepository {
  VoucherTypeRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  Result<VoucherType> create({
    required EntityId id,
    required CompanyId companyId,
    required String baseType,
    required String name,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (baseType.isEmpty || name.isEmpty || deviceId.isEmpty) {
      return err(
        'validation',
        'base type, name and device id must not be empty',
      );
    }
    // FR-M04-001: a derived type's base type must exist (canonical 19).
    if (!isKnownVoucherBaseType(baseType)) {
      return err('validation', 'unknown voucher base type');
    }
    VoucherType? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO voucher_type (type_id, company_id, base_type, name, '
          'created_at) VALUES (?, ?, ?, ?, ?)',
          <Object?>[id.value, companyId.value, baseType, name, now],
        );
        final Map<String, Object?> row = <String, Object?>{
          'type_id': id.value,
          'company_id': companyId.value,
          'base_type': baseType,
          'name': name,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'voucher_type',
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
          entity: 'voucher_type',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = VoucherType(
          id: id,
          companyId: companyId,
          baseType: baseType,
          name: name,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-type-create');
      return err(be.code, be.message);
    }
  }

  List<VoucherType> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT type_id, company_id, base_type, name, created_at '
      'FROM voucher_type WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <VoucherType>[
      for (final Map<String, Object?> r in rows) VoucherType.fromRow(r),
    ];
  }

  Result<VoucherSeries> createSeries({
    required EntityId seriesId,
    required CompanyId companyId,
    required EntityId typeId,
    required String name,
    String? prefix,
    String? suffix,
    int startNo = 1,
    int width = 0,
    String? restart,
    String? mode,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'series name and device id must not be empty');
    }
    if (startNo <= 0 || width < 0) {
      return err('validation', 'start_no must be > 0 and width >= 0');
    }
    if (mode != null && mode != 'auto' && mode != 'manual') {
      return err('validation', 'series mode must be auto or manual');
    }
    // FR-M04-002: no duplicate active series configuration that can generate
    // the same number within its scope (company + voucher type). The m009
    // table carries no UNIQUE clause, so the check lives here with an
    // explicit boundary until a rebuild migration carries it.
    final List<Map<String, Object?>> dupes = _db.queryArgs(
      'SELECT series_id FROM voucher_series '
      'WHERE company_id = ? AND type_id = ? AND name = ?',
      <Object?>[companyId.value, typeId.value, name],
    );
    if (dupes.isNotEmpty) {
      return err(
          'conflict', 'series name already exists for this voucher type');
    }
    VoucherSeries? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO voucher_series (series_id, company_id, type_id, '
          'name, prefix, suffix, start_no, width, restart, mode, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            seriesId.value,
            companyId.value,
            typeId.value,
            name,
            prefix,
            suffix,
            startNo,
            width,
            restart,
            mode,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'series_id': seriesId.value,
          'company_id': companyId.value,
          'type_id': typeId.value,
          'name': name,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'voucher_series',
          entityId: seriesId.value,
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
          entity: 'voucher_series',
          entityId: seriesId.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = VoucherSeries(
          id: seriesId,
          companyId: companyId,
          typeId: typeId,
          name: name,
          prefix: prefix,
          suffix: suffix,
          startNo: startNo,
          width: width,
          restart: restart,
          mode: mode,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'voucher-series-create');
      return err(be.code, be.message);
    }
  }

  List<VoucherSeries> seriesForType(CompanyId companyId, EntityId typeId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT series_id, company_id, type_id, name, prefix, suffix, '
      'start_no, width, restart, mode, created_at FROM voucher_series '
      'WHERE company_id = ? AND type_id = ? ORDER BY name',
      <Object?>[companyId.value, typeId.value],
    );
    return <VoucherSeries>[
      for (final Map<String, Object?> r in rows) VoucherSeries.fromRow(r),
    ];
  }
}

class GodownRepository {
  GodownRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  /// Create a godown. The documented per-company name uniqueness
  /// (uq_godown_company_name) is enforced here because the m001 table
  /// predates the UNIQUE clause; a rebuild migration carries it later.
  Result<Godown> create({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'godown name and device id must not be empty');
    }
    final List<Map<String, Object?>> dupes = _db.queryArgs(
      'SELECT godown_id FROM godown WHERE company_id = ? AND name = ?',
      <Object?>[companyId.value, name],
    );
    if (dupes.isNotEmpty) {
      return err('conflict', 'godown name already exists in this company');
    }
    Godown? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO godown (godown_id, company_id, name, created_at) '
          'VALUES (?, ?, ?, ?)',
          <Object?>[id.value, companyId.value, name, now],
        );
        final Map<String, Object?> row = <String, Object?>{
          'godown_id': id.value,
          'company_id': companyId.value,
          'name': name,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'godown',
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
          entity: 'godown',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = Godown(id: id, companyId: companyId, name: name, createdAt: now);
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'godown-create');
      return err(be.code, be.message);
    }
  }

  List<Godown> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT godown_id, company_id, name, created_at FROM godown '
      'WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <Godown>[for (final Map<String, Object?> r in rows) Godown.fromRow(r)];
  }
}
