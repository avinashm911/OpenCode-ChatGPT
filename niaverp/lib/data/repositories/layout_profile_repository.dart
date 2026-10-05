// NiAvERP layout-profile repository — prompt 10 (M23 P1, gate G1).
// Versioned UI layout preferences over the m005 `layout_profile` table
// (G0-SCH-004): company-scoped, one row per (key, version), JSON opaque to
// storage (no layout schema invented here). Every write carries operation +
// audit lineage. Preferences affect UI behavior only; rights gating and
// disabled-edition enforcement belong to the entitlement/rights slices and
// are NOT decided here — a stored preference never grants access by itself.
// synced_at / backup_manifest_id stay null until the S1/backup slices own
// them. Traceability: FR-M23-001; G0-SCH-004; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// One stored layout-profile version.
class LayoutProfile {
  const LayoutProfile({
    required this.id,
    required this.companyId,
    required this.profileKey,
    required this.version,
    required this.layoutJson,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String profileKey;
  final int version;
  final String layoutJson;
  final int createdAt;

  static LayoutProfile fromRow(Map<String, Object?> r) => LayoutProfile(
        id: EntityId(r['profile_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        profileKey: r['profile_key'] as String,
        version: r['version'] as int,
        layoutJson: r['layout_json'] as String,
        createdAt: r['updated_at'] as int,
      );
}

class LayoutProfileRepository {
  LayoutProfileRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'profile_id, company_id, profile_key, version, layout_json, updated_at';

  /// Save one profile version. Duplicate (company, key, version) collides
  /// via the table UNIQUE (reported as `conflict`); version must be > 0.
  Result<LayoutProfile> save({
    required EntityId id,
    required CompanyId companyId,
    required String profileKey,
    required int version,
    required String layoutJson,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (profileKey.isEmpty || layoutJson.isEmpty || deviceId.isEmpty) {
      return err('validation',
          'profile key, layout json and device id must not be empty');
    }
    if (version <= 0) {
      return err('validation', 'profile version must be > 0');
    }
    LayoutProfile? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO layout_profile (profile_id, company_id, profile_key, '
          'version, layout_json, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            profileKey,
            version,
            layoutJson,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'profile_id': id.value,
          'company_id': companyId.value,
          'profile_key': profileKey,
          'version': version,
        };
        final Result<OperationRecord> op = ops.append(
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'layout_profile',
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
          entity: 'layout_profile',
          entityId: id.value,
          newRow: row,
          actor: actor,
        );
        if (ev.isErr) {
          txFailure = (ev as Err<AuditEvent>).error;
          throw const RepositoryAbort();
        }
        done = LayoutProfile(
          id: id,
          companyId: companyId,
          profileKey: profileKey,
          version: version,
          layoutJson: layoutJson,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'layout-profile-save');
      return err(be.code, be.message);
    }
  }

  /// Newest saved version of one key, or null when never saved.
  LayoutProfile? latest(CompanyId companyId, String profileKey) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM layout_profile '
      'WHERE company_id = ? AND profile_key = ? ORDER BY version DESC LIMIT 1',
      <Object?>[companyId.value, profileKey],
    );
    if (rows.isEmpty) return null;
    return LayoutProfile.fromRow(rows.first);
  }

  /// All saved versions of one key, oldest first.
  List<LayoutProfile> versions(CompanyId companyId, String profileKey) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM layout_profile '
      'WHERE company_id = ? AND profile_key = ? ORDER BY version',
      <Object?>[companyId.value, profileKey],
    );
    return <LayoutProfile>[
      for (final Map<String, Object?> r in rows) LayoutProfile.fromRow(r),
    ];
  }
}
