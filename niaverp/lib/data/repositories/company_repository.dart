// NiAvERP company repository — implementation Phase 01.
// Minimal CRUD over the m001 `company` parent (company_id, name, created_at).
// Company is the scope root (DSS-C-001): every write carries its company_id,
// runs in one transaction, and appends operation + audit lineage.
// Traceability: DSS-C-001; DSS-C-004; OD-DB-004; DB v0.4 §3.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/security/trial_service.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One company row. [stateCode] is the 2-digit GST state code of the
/// company's location (supplier location for place-of-supply rules).
class Company {
  const Company({
    required this.id,
    required this.name,
    required this.createdAt,
    this.stateCode,
  });

  final CompanyId id;
  final String name;
  final int createdAt;
  final String? stateCode;

  static Company fromRow(Map<String, Object?> r) => Company(
        id: CompanyId(r['company_id'] as String),
        name: r['name'] as String,
        createdAt: r['created_at'] as int,
        stateCode: r['state_code'] as String?,
      );
}

class CompanyRepository {
  CompanyRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  /// Create a company with operation + audit lineage in one transaction.
  Result<Company> create({
    required CompanyId id,
    required String name,
    String? stateCode,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'company name and device id must not be empty');
    }
    Company? created;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO company (company_id, name, state_code, created_at) '
          'VALUES (?, ?, ?, ?)',
          <Object?>[id.value, name, stateCode, now],
        );
        final Map<String, Object?> row = <String, Object?>{
          'company_id': id.value,
          'name': name,
        };
        // B1 (SEC §3.3): every company gets its trial anchor in the same
        // transaction. Single earliest-wins logic (TrialService): new
        // companies inherit the installation's start, including the
        // app-private file copy when the context carries it. Never rewrites
        // an existing row.
        TrialService(db: _db, clock: ctx.clock, files: ctx.trialFiles)
            .ensureCompanyAnchor(id.value, now);
        final String hash = auditPayloadHash(row);
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: id.value,
          deviceId: deviceId,
          entity: 'company',
          entityId: id.value,
          action: 'create',
          payloadHash: hash,
          eventId: eventId,
          newRow: row,
          actor: actor,
        );
        if (lineage.isErr) {
          txFailure = (lineage as Err<void>).error;
          throw const RepositoryAbort();
        }
        created = Company(id: id, name: name, createdAt: now, stateCode: stateCode);
      });
      return ok(created!);
    } on RepositoryAbort {
      // txFailure is always set before the sentinel is thrown.
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'company-create');
      return err(be.code, be.message);
    }
  }

  /// Fetch one company by id (null when absent — not an error).
  Company? get(CompanyId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT company_id, name, state_code, created_at FROM company '
      'WHERE company_id = ?',
      <Object?>[id.value],
    );
    if (rows.isEmpty) return null;
    return Company.fromRow(rows.first);
  }
}
