// Derived ledger balances — posting slice (M14 books foundation, G1).
// Per DSS, ledger balances are DERIVED from posted vouchers and rebuilt by
// query: signed opening (Dr positive, Cr negative — house convention,
// owner-directed) plus posted lines carrying this ledger (Dr adds, Cr
// subtracts). Unposted vouchers never count. Full voucher→ledger
// auto-posting templates stay downstream; only explicitly ledger-referenced
// lines participate (nothing inferred).
// Traceability: FR-M06-004 (Dr = Cr rule enforced at post); DB §3 (ledger).

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

/// One ledger balance row (paise, signed: Dr positive).
class LedgerBalance {
  const LedgerBalance({
    required this.ledgerId,
    required this.name,
    required this.balancePaise,
  });

  final EntityId ledgerId;
  final String name;
  final int balancePaise;
}

class LedgerBooks {
  const LedgerBooks(this._db);

  final MigrationDb _db;

  /// Signed balance of one ledger in its company, or null when absent.
  int? ledgerBalance(CompanyId companyId, EntityId ledgerId) {
    final List<Map<String, Object?>> ledgers = _db.queryArgs(
      'SELECT opening_side, opening_paise FROM ledger '
      'WHERE company_id = ? AND ledger_id = ?',
      <Object?>[companyId.value, ledgerId.value],
    );
    if (ledgers.isEmpty) return null;
    int balance = 0;
    if ((ledgers.first['opening_side'] as String?) == 'Cr') {
      balance -= ledgers.first['opening_paise'] as int;
    } else {
      balance += ledgers.first['opening_paise'] as int;
    }
    final List<Map<String, Object?>> lines = _db.queryArgs(
      'SELECT l.dr_cr, l.amount_paise FROM voucher_line l '
      'JOIN voucher v ON v.voucher_id = l.voucher_id '
      "WHERE l.company_id = ? AND l.ledger_id = ? AND v.status = 'posted'",
      <Object?>[companyId.value, ledgerId.value],
    );
    for (final Map<String, Object?> l in lines) {
      final int amount = l['amount_paise'] as int;
      if ((l['dr_cr'] as String?) == 'Cr') {
        balance -= amount;
      } else {
        balance += amount;
      }
    }
    return balance;
  }

  /// Trial balance: every ledger of the company with its signed balance,
  /// ordered by name. Balanced books sum to zero only when postings do —
  /// the engine's Dr = Cr rule keeps posted vouchers balanced; openings
  /// are the owner's responsibility (validated sideful at creation).
  List<LedgerBalance> trialBalance(CompanyId companyId) {
    final List<Map<String, Object?>> ledgers = _db.queryArgs(
      'SELECT ledger_id, name FROM ledger WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    return <LedgerBalance>[
      for (final Map<String, Object?> l in ledgers)
        LedgerBalance(
          ledgerId: EntityId(l['ledger_id'] as String),
          name: l['name'] as String,
          balancePaise: ledgerBalance(
                  companyId, EntityId(l['ledger_id'] as String)) ??
              0,
        ),
    ];
  }
}
