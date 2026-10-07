// NiAvERP party repository — implementation Phase 02 (M03.3, gate G1).
// CRUD over the v9 `party` + `party_address` tables. Role vocabulary is
// exactly the documented pair (customer/supplier); GSTIN and mobile are
// stored as-entered text (format rules pending M17/G3 — no invented regex).
// Ledger linkage is validated when set (the ledger must exist in the same
// company; DB §3 N:1 ledger); null stays allowed for quick-add parties.
// price-list/salesperson linkage waits on their P2/P3 subsystems.
// Every write is company-scoped, single-transaction, with operation + audit
// lineage. Traceability: REG M03.3; DSS §3; DB §3; DSS-C-001/004; OD-DB-004.

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import 'audit_log.dart';
import 'operation_log.dart';
import 'repository.dart';

/// Documented party roles (REG M03.3 title). No 'both': a party acting in
/// both capacities is two rows until a combined role is approved.
const List<String> kPartyRoles = <String>['customer', 'supplier'];

/// One party row.
class Party {
  const Party({
    required this.id,
    required this.companyId,
    required this.name,
    required this.role,
    this.ledgerId,
    this.gstin,
    this.state,
    this.mobile,
    this.address,
    this.terms,
    this.registrationType,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final String name;
  final String role;
  final String? ledgerId;
  final String? gstin;
  final String? state;
  final String? mobile;
  final String? address;
  final String? terms;
  final int createdAt;

  /// Buyer classification for place-of-supply rules (CA reply 2026-10-07):
  /// 'registered' / 'unregistered' / 'composition'. Free text validated in
  /// Dart; the documents specify no CHECK vocabulary.
  final String? registrationType;

  static Party fromRow(Map<String, Object?> r) => Party(
        id: EntityId(r['party_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        name: r['name'] as String,
        role: r['role'] as String,
        ledgerId: r['ledger_id'] as String?,
        gstin: r['gstin'] as String?,
        state: r['state'] as String?,
        mobile: r['mobile'] as String?,
        address: r['address'] as String?,
        terms: r['terms'] as String?,
        registrationType: r['registration_type'] as String?,
        createdAt: r['created_at'] as int,
      );
}

/// One additional address row (REG M03.3 "multiple addresses").
class PartyAddress {
  const PartyAddress({
    required this.id,
    required this.companyId,
    required this.partyId,
    this.label,
    required this.address,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId partyId;
  final String? label;
  final String address;
  final int createdAt;

  static PartyAddress fromRow(Map<String, Object?> r) => PartyAddress(
        id: EntityId(r['address_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        partyId: EntityId(r['party_id'] as String),
        label: r['label'] as String?,
        address: r['address'] as String,
        createdAt: r['created_at'] as int,
      );
}

class PartyRepository {
  PartyRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'party_id, company_id, ledger_id, name, role, gstin, state, mobile, '
      'address, terms, registration_type, created_at';

  Result<Party> _insert({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    required String role,
    String? ledgerId,
    String? gstin,
    String? state,
    String? mobile,
    String? address,
    String? terms,
    String? registrationType,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
    required String action,
    Map<String, Object?>? oldRow,
  }) {
    if (name.isEmpty || deviceId.isEmpty) {
      return err('validation', 'party name and device id must not be empty');
    }
    if (!kPartyRoles.contains(role)) {
      return err('validation', 'party role must be customer or supplier');
    }
    // Ledger hook (DB §3 N:1 ledger): when set, the ledger must exist in
    // the same company. Null stays allowed (quick-add party before ledger).
    if (ledgerId != null) {
      final List<Map<String, Object?>> ledger = _db.queryArgs(
        'SELECT ledger_id FROM ledger WHERE company_id = ? AND ledger_id = ?',
        <Object?>[companyId.value, ledgerId],
      );
      if (ledger.isEmpty) {
        return err('foreign-key', 'party ledger must exist in this company');
      }
    }
    Party? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        if (action == 'create') {
          _db.executeArgs(
            'INSERT INTO party (party_id, company_id, ledger_id, name, role, '
            'gstin, state, mobile, address, terms, registration_type, '
            'created_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            <Object?>[
              id.value,
              companyId.value,
              ledgerId,
              name,
              role,
              gstin,
              state,
              mobile,
              address,
              terms,
              registrationType,
              now,
            ],
          );
        } else {
          _db.executeArgs(
            'UPDATE party SET ledger_id = ?, name = ?, role = ?, gstin = ?, '
            'state = ?, mobile = ?, address = ?, terms = ?, '
            'registration_type = ?, '
            'record_version = record_version + 1 '
            'WHERE company_id = ? AND party_id = ?',
            <Object?>[
              ledgerId,
              name,
              role,
              gstin,
              state,
              mobile,
              address,
              terms,
              registrationType,
              companyId.value,
              id.value,
            ],
          );
        }
        final Map<String, Object?> row = <String, Object?>{
          'party_id': id.value,
          'company_id': companyId.value,
          'name': name,
          'role': role,
          if (gstin case final String g) 'gstin': g,
          if (state case final String s) 'state': s,
          if (mobile case final String m) 'mobile': m,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'party',
          entityId: id.value,
          action: action,
          payloadHash: auditPayloadHash(row),
          eventId: eventId,
          oldRow: oldRow,
          newRow: row,
          actor: actor,
        );
        if (lineage.isErr) {
          txFailure = (lineage as Err<void>).error;
          throw const RepositoryAbort();
        }
        done = Party(
          id: id,
          companyId: companyId,
          name: name,
          role: role,
          ledgerId: ledgerId,
          gstin: gstin,
          state: state,
          mobile: mobile,
          address: address,
          terms: terms,
          registrationType: registrationType,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'party-write');
      return err(be.code, be.message);
    }
  }

  /// Create a party with lineage.
  Result<Party> create({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    required String role,
    String? ledgerId,
    String? gstin,
    String? state,
    String? mobile,
    String? address,
    String? terms,
    String? registrationType,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) =>
      _insert(
        id: id,
        companyId: companyId,
        name: name,
        role: role,
        ledgerId: ledgerId,
        gstin: gstin,
        state: state,
        mobile: mobile,
        address: address,
        terms: terms,
        registrationType: registrationType,
        deviceId: deviceId,
        opId: opId,
        eventId: eventId,
        actor: actor,
        action: 'create',
      );

  /// Edit a party (full-row replacement of editable fields) with old/new
  /// audit lineage. Returns 'not-found' when the row is absent or foreign.
  Result<Party> update({
    required EntityId id,
    required CompanyId companyId,
    required String name,
    required String role,
    String? ledgerId,
    String? gstin,
    String? state,
    String? mobile,
    String? address,
    String? terms,
    String? registrationType,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    final Party? before = get(companyId, id);
    if (before == null) {
      return err('not-found', 'party is absent in this company');
    }
    return _insert(
      id: id,
      companyId: companyId,
      name: name,
      role: role,
      ledgerId: ledgerId,
      gstin: gstin,
      state: state,
      mobile: mobile,
      address: address,
      terms: terms,
      registrationType: registrationType,
      deviceId: deviceId,
      opId: opId,
      eventId: eventId,
      actor: actor,
      action: 'update',
      oldRow: <String, Object?>{
        'party_id': before.id.value,
        'name': before.name,
        'role': before.role,
      },
    );
  }

  /// Fetch one party within its company (null when absent or foreign).
  Party? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM party WHERE company_id = ? AND party_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return Party.fromRow(rows.first);
  }

  /// All parties of one company, by name.
  List<Party> listByCompany(CompanyId companyId, {String? role}) {
    final String sql = role == null
        ? 'SELECT $_cols FROM party WHERE company_id = ? ORDER BY name'
        : 'SELECT $_cols FROM party WHERE company_id = ? AND role = ? '
            'ORDER BY name';
    final List<Object?> args = role == null
        ? <Object?>[companyId.value]
        : <Object?>[companyId.value, role];
    final List<Map<String, Object?>> rows = _db.queryArgs(sql, args);
    return <Party>[for (final Map<String, Object?> r in rows) Party.fromRow(r)];
  }

  /// Add an additional address with lineage.
  Result<PartyAddress> addAddress({
    required EntityId addressId,
    required CompanyId companyId,
    required EntityId partyId,
    String? label,
    required String address,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (address.isEmpty || deviceId.isEmpty) {
      return err('validation', 'address and device id must not be empty');
    }
    if (get(companyId, partyId) == null) {
      return err('foreign-key', 'party is absent in this company');
    }
    PartyAddress? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO party_address (address_id, company_id, party_id, '
          'label, address, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            addressId.value,
            companyId.value,
            partyId.value,
            label,
            address,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'address_id': addressId.value,
          'party_id': partyId.value,
          'address': address,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'party_address',
          entityId: addressId.value,
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
        done = PartyAddress(
          id: addressId,
          companyId: companyId,
          partyId: partyId,
          label: label,
          address: address,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'party-address-add');
      return err(be.code, be.message);
    }
  }

  /// Additional addresses of one party, in creation order.
  List<PartyAddress> addressesFor(CompanyId companyId, EntityId partyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT address_id, company_id, party_id, label, address, created_at '
      'FROM party_address WHERE company_id = ? AND party_id = ? '
      'ORDER BY created_at',
      <Object?>[companyId.value, partyId.value],
    );
    return <PartyAddress>[
      for (final Map<String, Object?> r in rows) PartyAddress.fromRow(r),
    ];
  }
}
