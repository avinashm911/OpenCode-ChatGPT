// Derived ledger balances — posting slice (M14 books foundation, G1).
// Per DSS, ledger balances are DERIVED from posted vouchers and rebuilt by
// query: signed opening (Dr positive, Cr negative — house convention,
// owner-directed) plus posted lines carrying this ledger (Dr adds, Cr
// subtracts). Unposted vouchers never count. Full voucher→ledger
// auto-posting templates stay downstream; only explicitly ledger-referenced
// lines participate (nothing inferred).
//
// Books in this module (M14.1/14.2/14.6, all pure projections of posted
// transactions — no report-specific calculations duplicate posting logic):
// day book / voucher registers (chronological posted vouchers with gross
// totals, optional type/series/date filters), ledger accounts (opening +
// posted lines + running balance), trial balance (ledger-wise, optional
// date window) and group summary (per-group subtree totals).
//
// Boundaries: P&L / Balance Sheet (M14.3/14.4, P1) wait on the group→
// statement mapping — FR-M03-001 names a group "classification" but no
// vocabulary or storage is specified, and statement placement cannot be
// derived from group names without inventing accounting policy. GST reports
// wait on G3 line-tax storage. Trading/BRS/reminders/cheques/interest are
// P2/P3 (M14.5/14.7–14.10); budgets/ratios P3; M14.11 superseded.
// Traceability: FR-M06-004 (Dr = Cr rule enforced at post); DB §3 (ledger);
// M14.1/14.2/14.6/14.13; DSS-C-001/004.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
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

/// One day-book / register row: a posted voucher with its gross total.
/// Cancelled vouchers appear only with [includeCancelled] (compensating
/// history stays visible, never rewritten).
class DayBookEntry {
  const DayBookEntry({
    required this.voucherId,
    required this.voucherNo,
    required this.voucherType,
    required this.series,
    required this.dateIso,
    required this.status,
    required this.totalPaise,
    required this.lineCount,
  });

  final EntityId voucherId;
  final String voucherNo;
  final String voucherType;
  final String series;
  final String dateIso;
  final String status;
  final int totalPaise;
  final int lineCount;
}

/// One ledger-account line with its running balance (paise, signed).
class LedgerEntry {
  const LedgerEntry({
    required this.voucherId,
    required this.voucherNo,
    required this.dateIso,
    required this.lineNo,
    required this.drCr,
    required this.amountPaise,
    required this.balanceAfterPaise,
  });

  final EntityId voucherId;
  final String voucherNo;
  final String dateIso;
  final int lineNo;
  final String? drCr;
  final int amountPaise;
  final int balanceAfterPaise;
}

/// One ledger account: master identity, opening, posted lines in document
/// order, and the closing balance. Drill-down data (voucher ids) rides
/// every line.
class LedgerAccount {
  const LedgerAccount({
    required this.ledgerId,
    required this.name,
    required this.openingSide,
    required this.openingPaise,
    required this.entries,
    required this.closingPaise,
  });

  final EntityId ledgerId;
  final String name;
  final String? openingSide;
  final int openingPaise;
  final List<LedgerEntry> entries;
  final int closingPaise;
}

/// One group-summary row: the signed total of every ledger in the group's
/// subtree (group plus all descendants).
class GroupBalance {
  const GroupBalance({
    required this.groupId,
    required this.name,
    required this.balancePaise,
    required this.ledgerCount,
  });

  final EntityId groupId;
  final String name;
  final int balancePaise;
  final int ledgerCount;
}

class LedgerBooks {
  const LedgerBooks(this._db);

  final MigrationDb _db;

  /// Signed balance of one ledger in its company, or null when absent.
  /// Optional [from]/[to] (inclusive ISO dates) restrict posted lines by
  /// voucher date; the master opening always counts in full (openings are
  /// master values, not period-derived — pre-window activity is not
  /// recomputed into them).
  int? ledgerBalance(
    CompanyId companyId,
    EntityId ledgerId, {
    NiavDate? from,
    NiavDate? to,
  }) {
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
    final StringBuffer sql = StringBuffer(
      'SELECT l.dr_cr, l.amount_paise FROM voucher_line l '
      'JOIN voucher v ON v.voucher_id = l.voucher_id '
      "WHERE l.company_id = ? AND l.ledger_id = ? AND v.status = 'posted'",
    );
    final List<Object?> args = <Object?>[companyId.value, ledgerId.value];
    if (from != null) {
      sql.write(' AND v.voucher_date >= ?');
      args.add(from.iso);
    }
    if (to != null) {
      sql.write(' AND v.voucher_date <= ?');
      args.add(to.iso);
    }
    final List<Map<String, Object?>> lines =
        _db.queryArgs(sql.toString(), args);
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
  /// Optional [from]/[to] restrict posted lines (openings always in full —
  /// see [ledgerBalance]).
  List<LedgerBalance> trialBalance(
    CompanyId companyId, {
    NiavDate? from,
    NiavDate? to,
  }) {
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
                  companyId, EntityId(l['ledger_id'] as String),
                  from: from, to: to) ??
              0,
        ),
    ];
  }

  /// Day book / voucher register (M14.1): posted vouchers in document order
  /// with gross line totals. [types] keeps voucher types (as stored),
  /// [series] keeps one series, [from]/[to] bound the voucher date
  /// (inclusive). Sales/Purchase registers are this query filtered by type.
  List<DayBookEntry> dayBook(
    CompanyId companyId, {
    NiavDate? from,
    NiavDate? to,
    List<String>? types,
    String? series,
    bool includeCancelled = false,
  }) {
    final StringBuffer sql = StringBuffer(
      'SELECT v.voucher_id, v.voucher_no, v.voucher_type, v.series, '
      'v.voucher_date, v.status, '
      'COALESCE(SUM(l.amount_paise), 0) AS total, '
      'COUNT(l.voucher_line_id) AS lines '
      'FROM voucher v LEFT JOIN voucher_line l '
      'ON l.voucher_id = v.voucher_id AND l.company_id = v.company_id '
      'WHERE v.company_id = ?',
    );
    final List<Object?> args = <Object?>[companyId.value];
    if (includeCancelled) {
      sql.write(" AND v.status IN ('posted', 'cancelled')");
    } else {
      sql.write(" AND v.status = 'posted'");
    }
    if (from != null) {
      sql.write(' AND v.voucher_date >= ?');
      args.add(from.iso);
    }
    if (to != null) {
      sql.write(' AND v.voucher_date <= ?');
      args.add(to.iso);
    }
    if (types != null && types.isNotEmpty) {
      sql.write(
          ' AND v.voucher_type IN (${List<String>.filled(types.length, '?').join(', ')})');
      args.addAll(types);
    }
    if (series != null) {
      sql.write(' AND v.series = ?');
      args.add(series);
    }
    sql.write(' GROUP BY v.voucher_id ORDER BY v.voucher_date, v.voucher_no');
    final List<Map<String, Object?>> rows =
        _db.queryArgs(sql.toString(), args);
    return <DayBookEntry>[
      for (final Map<String, Object?> r in rows)
        DayBookEntry(
          voucherId: EntityId(r['voucher_id'] as String),
          voucherNo: r['voucher_no'] as String,
          voucherType: r['voucher_type'] as String,
          series: r['series'] as String,
          dateIso: r['voucher_date'] as String,
          status: r['status'] as String,
          totalPaise: r['total'] as int,
          lineCount: r['lines'] as int,
        ),
    ];
  }

  /// Distinct voucher types with posted vouchers (register filter source).
  List<String> postedVoucherTypes(CompanyId companyId) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT DISTINCT voucher_type FROM voucher '
      "WHERE company_id = ? AND status = 'posted' ORDER BY voucher_type",
      <Object?>[companyId.value],
    );
    return <String>[
      for (final Map<String, Object?> r in rows) r['voucher_type'] as String
    ];
  }

  /// Ledger account (M14.1): master identity plus posted lines in document
  /// order with a running balance from the signed opening. Null when the
  /// ledger is absent. Optional [from]/[to] bound lines by voucher date.
  LedgerAccount? ledgerAccount(
    CompanyId companyId,
    EntityId ledgerId, {
    NiavDate? from,
    NiavDate? to,
  }) {
    final List<Map<String, Object?>> ledgers = _db.queryArgs(
      'SELECT ledger_id, name, opening_side, opening_paise FROM ledger '
      'WHERE company_id = ? AND ledger_id = ?',
      <Object?>[companyId.value, ledgerId.value],
    );
    if (ledgers.isEmpty) return null;
    final Map<String, Object?> head = ledgers.first;
    final String? side = head['opening_side'] as String?;
    int running = side == 'Cr'
        ? -(head['opening_paise'] as int)
        : (head['opening_paise'] as int);
    final StringBuffer sql = StringBuffer(
      'SELECT l.voucher_id, v.voucher_no, v.voucher_date, l.line_no, '
      'l.dr_cr, l.amount_paise FROM voucher_line l '
      'JOIN voucher v ON v.voucher_id = l.voucher_id '
      "WHERE l.company_id = ? AND l.ledger_id = ? AND v.status = 'posted'",
    );
    final List<Object?> args = <Object?>[companyId.value, ledgerId.value];
    if (from != null) {
      sql.write(' AND v.voucher_date >= ?');
      args.add(from.iso);
    }
    if (to != null) {
      sql.write(' AND v.voucher_date <= ?');
      args.add(to.iso);
    }
    sql.write(' ORDER BY v.voucher_date, v.voucher_no, l.line_no');
    final List<Map<String, Object?>> rows =
        _db.queryArgs(sql.toString(), args);
    final List<LedgerEntry> entries = <LedgerEntry>[];
    for (final Map<String, Object?> r in rows) {
      final int amount = r['amount_paise'] as int;
      if ((r['dr_cr'] as String?) == 'Cr') {
        running -= amount;
      } else {
        running += amount;
      }
      entries.add(LedgerEntry(
        voucherId: EntityId(r['voucher_id'] as String),
        voucherNo: r['voucher_no'] as String,
        dateIso: r['voucher_date'] as String,
        lineNo: r['line_no'] as int,
        drCr: r['dr_cr'] as String?,
        amountPaise: amount,
        balanceAfterPaise: running,
      ));
    }
    return LedgerAccount(
      ledgerId: EntityId(head['ledger_id'] as String),
      name: head['name'] as String,
      openingSide: side,
      openingPaise: head['opening_paise'] as int,
      entries: entries,
      closingPaise: running,
    );
  }

  /// Group summary (M14.1/14.2 group-wise): every account group with the
  /// signed total of the ledgers in its subtree, ordered by name.
  List<GroupBalance> groupTrialBalance(CompanyId companyId) {
    final List<Map<String, Object?>> groups = _db.queryArgs(
      'SELECT group_id, parent_group_id, name FROM account_group '
      'WHERE company_id = ? ORDER BY name',
      <Object?>[companyId.value],
    );
    final List<Map<String, Object?>> ledgers = _db.queryArgs(
      'SELECT ledger_id, group_id FROM ledger WHERE company_id = ?',
      <Object?>[companyId.value],
    );
    final Map<String, List<String>> children = <String, List<String>>{};
    for (final Map<String, Object?> g in groups) {
      final Object? parent = g['parent_group_id'];
      if (parent != null) {
        children
            .putIfAbsent(parent as String, () => <String>[])
            .add(g['group_id'] as String);
      }
    }
    Set<String> subtree(String root) {
      final Set<String> out = <String>{root};
      final List<String> stack = <String>[root];
      while (stack.isNotEmpty) {
        final String next = stack.removeLast();
        for (final String child in children[next] ?? <String>[]) {
          if (out.add(child)) stack.add(child);
        }
      }
      return out;
    }

    final List<GroupBalance> out = <GroupBalance>[];
    for (final Map<String, Object?> g in groups) {
      final String groupId = g['group_id'] as String;
      final Set<String> scope = subtree(groupId);
      int total = 0;
      int count = 0;
      for (final Map<String, Object?> l in ledgers) {
        if (!scope.contains(l['group_id'] as String)) continue;
        total +=
            ledgerBalance(companyId, EntityId(l['ledger_id'] as String)) ?? 0;
        count += 1;
      }
      out.add(GroupBalance(
        groupId: EntityId(groupId),
        name: g['name'] as String,
        balancePaise: total,
        ledgerCount: count,
      ));
    }
    return out;
  }
}
