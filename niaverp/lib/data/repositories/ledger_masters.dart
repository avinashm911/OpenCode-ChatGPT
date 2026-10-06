// NiAvERP ledger-master repositories — posting slice (FR-M03-002/004, G1).
// Storage for the m013/m014 tables (DB §3 exact shape): account_group
// self-tree; ledger identity + group + opening side/value + bill-wise flag
// + credit limit/days + contact/address/bank details (m014); bank_account
// with company/ledger links + as-entered account/IFSC/UPI (m014).
// Balances are derived by query (DSS projection model), never stored here.
// Group guards mirror the item-group precedent (self-parent, same-company
// parent, bounded ancestor walk). Duplicate ledger names collide per
// company (FR-M03-002). An opening amount without a side is ambiguous and
// rejected; zero openings may leave the side null. Bank format rules are
// VERIFY before release (FR-M03-004) — values stored as-entered, never
// validated by invented regex. GST detail columns wait on G3 schemas
// (OD-DB-003). Cost centres (M03.5 P3) and currencies (M03.6 P3 TBC) are
// explicitly out of scope. Every write carries operation + audit lineage.
// Traceability: FR-M03-002 (REG M03.2); FR-M03-004 (REG M03.4); DB §3;
// DSS-C-001/004; OD-DB-004.

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
    this.creditLimitPaise,
    this.creditDays,
    this.contact,
    this.address,
    this.bankDetails,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId groupId;
  final String name;
  final String? openingSide;
  final int openingPaise;
  final bool billwise;
  final int? creditLimitPaise;
  final int? creditDays;
  final String? contact;
  final String? address;
  final String? bankDetails;
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
        creditLimitPaise: r.containsKey('credit_limit_paise')
            ? r['credit_limit_paise'] as int?
            : null,
        creditDays: r.containsKey('credit_days')
            ? r['credit_days'] as int?
            : null,
        contact: r.containsKey('contact') ? r['contact'] as String? : null,
        address: r.containsKey('address') ? r['address'] as String? : null,
        bankDetails: r.containsKey('bank_details')
            ? r['bank_details'] as String?
            : null,
        createdAt: r['created_at'] as int,
      );
}

/// One bank-account row (FR-M03-004): a bank ledger plus as-entered
/// account/IFSC/UPI metadata. One row per ledger per company.
class BankAccount {
  const BankAccount({
    required this.id,
    required this.companyId,
    required this.ledgerId,
    this.accountNo,
    this.ifsc,
    this.upiId,
    required this.createdAt,
  });

  final EntityId id;
  final CompanyId companyId;
  final EntityId ledgerId;
  final String? accountNo;
  final String? ifsc;
  final String? upiId;
  final int createdAt;

  static BankAccount fromRow(Map<String, Object?> r) => BankAccount(
        id: EntityId(r['bank_account_id'] as String),
        companyId: CompanyId(r['company_id'] as String),
        ledgerId: EntityId(r['ledger_id'] as String),
        accountNo: r['account_no'] as String?,
        ifsc: r['ifsc'] as String?,
        upiId: r['upi_id'] as String?,
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
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'account_group',
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
      'billwise, credit_limit_paise, credit_days, contact, address, '
      'bank_details, created_at';

  Result<Ledger> create({
    required EntityId id,
    required CompanyId companyId,
    required EntityId groupId,
    required String name,
    String? openingSide,
    int openingPaise = 0,
    bool billwise = false,
    int? creditLimitPaise,
    int? creditDays,
    String? contact,
    String? address,
    String? bankDetails,
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
    if (creditLimitPaise != null && creditLimitPaise < 0) {
      return err('validation', 'credit limit must be >= 0');
    }
    if (creditDays != null && creditDays < 0) {
      return err('validation', 'credit days must be >= 0');
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
          'opening_side, opening_paise, billwise, credit_limit_paise, '
          'credit_days, contact, address, bank_details, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            groupId.value,
            name,
            openingSide,
            openingPaise,
            billwise ? 1 : 0,
            creditLimitPaise,
            creditDays,
            contact,
            address,
            bankDetails,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'ledger_id': id.value,
          'company_id': companyId.value,
          'group_id': groupId.value,
          'name': name,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'ledger',
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
        done = Ledger(
          id: id,
          companyId: companyId,
          groupId: groupId,
          name: name,
          openingSide: openingSide,
          openingPaise: openingPaise,
          billwise: billwise,
          creditLimitPaise: creditLimitPaise,
          creditDays: creditDays,
          contact: contact,
          address: address,
          bankDetails: bankDetails,
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

  /// True when the ledger exists in the company (posting-time ref check).
  bool exists(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT 1 FROM ledger WHERE company_id = ? AND ledger_id = ? LIMIT 1',
      <Object?>[companyId.value, id.value],
    );
    return rows.isNotEmpty;
  }
}

/// Bank-account masters (FR-M03-004, REG M03.4, gate G1).
/// One row per bank ledger per company; account/IFSC/UPI stored as-entered
/// (format rules VERIFY before release — never invented here). The ledger
/// must exist in the same company. Every write carries operation + audit
/// lineage.
class BankAccountRepository {
  BankAccountRepository(this.ctx, {required this.ops, required this.audit});

  final RepositoryContext ctx;
  final OperationLog ops;
  final AuditLog audit;

  MigrationDb get _db => ctx.db;

  static const String _cols =
      'bank_account_id, company_id, ledger_id, account_no, ifsc, upi_id, '
      'created_at';

  Result<BankAccount> create({
    required EntityId id,
    required CompanyId companyId,
    required EntityId ledgerId,
    String? accountNo,
    String? ifsc,
    String? upiId,
    required String deviceId,
    required String opId,
    required String eventId,
    required String actor,
  }) {
    if (deviceId.isEmpty) {
      return err('validation', 'device id must not be empty');
    }
    final List<Map<String, Object?>> ledger = _db.queryArgs(
      'SELECT ledger_id FROM ledger WHERE company_id = ? AND ledger_id = ?',
      <Object?>[companyId.value, ledgerId.value],
    );
    if (ledger.isEmpty) {
      return err('foreign-key', 'bank ledger must exist in this company');
    }
    BankAccount? done;
    AppError? txFailure;
    try {
      _db.runInTransaction(() {
        final int now = ctx.clock.nowMs();
        _db.executeArgs(
          'INSERT INTO bank_account (bank_account_id, company_id, ledger_id, '
          'account_no, ifsc, upi_id, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id.value,
            companyId.value,
            ledgerId.value,
            accountNo,
            ifsc,
            upiId,
            now,
          ],
        );
        final Map<String, Object?> row = <String, Object?>{
          'bank_account_id': id.value,
          'company_id': companyId.value,
          'ledger_id': ledgerId.value,
        };
        final Result<void> lineage = recordLineage(
          ops: ops,
          audit: audit,
          opId: opId,
          companyId: companyId.value,
          deviceId: deviceId,
          entity: 'bank_account',
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
        done = BankAccount(
          id: id,
          companyId: companyId,
          ledgerId: ledgerId,
          accountNo: accountNo,
          ifsc: ifsc,
          upiId: upiId,
          createdAt: now,
        );
      });
      return ok(done!);
    } on RepositoryAbort {
      final AppError f = txFailure!;
      return err(f.code, f.message);
    } catch (e) {
      final AppError be = dbError(e, 'bank-account-create');
      return err(be.code, be.message);
    }
  }

  BankAccount? get(CompanyId companyId, EntityId id) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM bank_account WHERE company_id = ? AND bank_account_id = ?',
      <Object?>[companyId.value, id.value],
    );
    if (rows.isEmpty) return null;
    return BankAccount.fromRow(rows.first);
  }

  BankAccount? forLedger(CompanyId companyId, EntityId ledgerId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM bank_account WHERE company_id = ? AND ledger_id = ?',
      <Object?>[companyId.value, ledgerId.value],
    );
    if (rows.isEmpty) return null;
    return BankAccount.fromRow(rows.first);
  }

  List<BankAccount> listByCompany(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT $_cols FROM bank_account WHERE company_id = ? ORDER BY bank_account_id',
      <Object?>[companyId.value],
    );
    return <BankAccount>[
      for (final Map<String, Object?> r in rows) BankAccount.fromRow(r),
    ];
  }
}
