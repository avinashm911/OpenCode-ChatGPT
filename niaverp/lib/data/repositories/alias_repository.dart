// NiAvERP alias repository — Phase 02 (M12.3, gate G1).
// User-entered Latin/native-script spellings per master row. Aliases are
// stored exactly as entered and matched with LIKE; NOTHING here performs
// transliteration or fuzzy matching (excluded: G0-DEF-003; fuzzy is P2 M12.4).
// Traceability: REG M12.3; G0-DEF-003; strategy Slice 2.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// Entities that may carry aliases in this slice (matches the v9 CHECK).
const List<String> kAliasEntities = <String>['party', 'item'];

/// One alias row.
class SearchAlias {
  const SearchAlias({
    required this.id,
    required this.companyId,
    required this.entity,
    required this.entityId,
    required this.alias,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String entity;
  final EntityId entityId;
  final String alias;
  final int createdAt;

  static SearchAlias fromRow(Map<String, Object?> r) => SearchAlias(
        id: EntityId(r['alias_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        entity: r['entity'] as String,
        entityId: EntityId(r['entity_id'] as String),
        alias: r['alias'] as String,
        createdAt: r['created_at'] as int,
      );
}

class AliasRepository {
  AliasRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  /// Store one user-entered alias spelling with lineage.
  Result<SearchAlias> add({
    required EntityId id,
    required CompanyId companyId,
    required String entity,
    required EntityId entityId,
    required String alias,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (!kAliasEntities.contains(entity)) {
      return err('validation', 'alias entity must be party or item');
    }
    if (alias.isEmpty || deviceId.isEmpty) {
      return err('validation', 'alias and device id must not be empty');
    }
    SearchAlias? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO search_alias (alias_id, company_id, entity, '
          'entity_id, alias, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            entity,
            entityId.value,
            alias,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'alias_id': id.value,
          'entity': entity,
          'entity_id': entityId.value,
          'alias': alias,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'search_alias',
          entityId: id.value,
          action: 'create',
          payloadHash: auditPayloadHash(row),
          eventId: eventId,
          newRow: row,
          actor: actor,
        );
        if (lineage.isErr) {
          txFailure = (lineage as Err<void>).error;
          throw const RepositoryAbort();
        }
        done = SearchAlias(
          id: id,
          companyId: companyId,
          entity: entity,
          entityId: entityId,
          alias: alias,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'alias-add');
      return err(be.code, be.message);
    }
  }

  /// Aliases of one master row, in creation order.
  List<SearchAlias> forEntity(
    CompanyId companyId,
    String entity,
    EntityId entityId,
  ) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT alias_id, company_id, entity, entity_id, alias, created_at '
      'FROM search_alias WHERE company_id = ? AND entity = ? AND entity_id = ? '
      'ORDER BY created_at',
      <Object?>[companyId.value, entity, entityId.value],
    );
    return <SearchAlias>[
      for (final Map<String, Object?> r in rows) SearchAlias.fromRow(r),
    ];
  }
}
