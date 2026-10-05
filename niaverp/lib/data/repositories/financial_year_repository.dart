// NiAvERP financial-year repository — DSS slice (DB §3, gate G1).
// Storage for the m011 `financial_year` table (fy_id PK, company FK,
// start/end/status, UNIQUE per company+start). Status stays free TEXT: the
// open/closed vocabulary is unspecified — recorded open. Date order is
// enforced pre-DB and by the table CHECK. Every write carries operation +
// audit lineage. Company FY-start/books-begin configuration (FR-M01-001)
// and any enforcement reading this table stay downstream.
// Traceability: DB §3 (financial_year); DSS §3; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One financial-year row.
class FinancialYear {
  const FinancialYear({
    required this.id,
    required this.companyId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final NiavDate startDate;
  final NiavDate endDate;
  final String status;
  final int createdAt;

  static FinancialYear fromRow(Map<String, Object?> r) => FinancialYear(
        id: EntityId(r['fy_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        startDate: NiavDate(r['start_date'] as String),
        endDate: NiavDate(r['end_date'] as String),
        status: r['status'] as String,
        createdAt: r['created_at'] as int,
      );
}

class FinancialYearRepository {
  FinancialYearRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'fy_id, company_id, start_date, end_date, status, created_at';

  Result<FinancialYear> create({
    required EntityId id,
    required CompanyId companyId,
    required NiavDate startDate,
    required NiavDate endDate,
    required String status,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (status.isEmpty || deviceId.isEmpty) {
      return err('validation', 'fy status and device id must not be empty');
    }
    if (endDate.iso.compareTo(startDate.iso) < 0) {
      return err('validation', 'fy end_date must be >= start_date');
    }
    FinancialYear? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO financial_year (fy_id, company_id, start_date, '
          'end_date, status, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            startDate.iso,
            endDate.iso,
            status,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'fy_id': id.value,
          'company_id': companyId.value,
          'start_date': startDate.iso,
          'end_date': endDate.iso,
          'status': status,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'financial_year',
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
          entity: 'financial_year',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = FinancialYear(
          id: id,
          companyId: companyId,
          startDate: startDate,
          endDate: endDate,
          status: status,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'financial-year-create');
      return err(be.code, be.message);
    }
  }

  FinancialYear? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM financial_year WHERE company_id = ? AND fy_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return FinancialYear.fromRow(rows.first);
  }

  List<FinancialYear> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM financial_year WHERE company_id = ? ORDER BY start_date',
      <Object?>[companyId.value],
    );
    return <FinancialYear>[
      for (final Map<String, Object?> r in rows) FinancialYear.fromRow(r),
    ];
  }
}
