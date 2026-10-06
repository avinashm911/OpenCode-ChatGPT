// Outstanding business report — bill-wise settlement (FR-M06/FR-M14-001).
// Read-only queries over posted vouchers, voucher lines and bill_allocation
// rows: per-bill open balances with Open/Part-settled/Settled states,
// party receivables/payables, caller-bucketed aging by document date,
// advance (unallocated payment/receipt) lines, and full settlement history
// including reversals. Company scope always enforced.
//
// Boundaries (explicit, never silent): due-date aging waits on a schema
// column the approved migrations do not carry (bills age by voucher date);
// bills exclude M06 settlement/adjustment documents (Payment, Receipt,
// Contra, Journal — their source-side "open" is not a receivable);
// advance detection covers posted Payment/Receipt vouchers (FR-M06-001/002)
// resolved by canonical name, mechanical slug, or a registered company
// type with a Payment/Receipt base. Over-allocated history throws instead
// of clamping (same rule as settlement.remainingBalance).
// Traceability: FR-M06-001/002 (bill-wise settlement, advances);
// FR-M14-001 (bill states, allocation cap, outstanding reports);
// G0-SCH-003; DSS-C-003/004.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';

/// Open (unsettled) amount, in paise, of one voucher in its company.
/// Vouchers without lines, or unknown ids, report zero.
int voucherOpenBalance(
  MigrationDb db,
  CompanyId companyId,
  EntityId voucherId,
) {
  // Bill economics live in the document lines (no Dr/Cr marker); ledger arms
  // (D3-A1) are excluded exactly as in bills() below.
  final List<Map<String, Object?>> lines = db.queryArgs(
    'SELECT voucher_line_id, amount_paise FROM voucher_line '
    'WHERE company_id = ? AND voucher_id = ? AND dr_cr IS NULL',
    <Object?>[companyId.value, voucherId.value],
  );
  if (lines.isEmpty) return 0;
  int total = 0;
  final List<Object?> lineIds = <Object?>[];
  for (final Map<String, Object?> line in lines) {
    total += line['amount_paise'] as int;
    lineIds.add(line['voucher_line_id'] as String);
  }
  final String placeholders =
      List<String>.filled(lineIds.length, '?').join(', ');
  final List<Map<String, Object?>> allocs = db.queryArgs(
    'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
    "WHERE company_id = ? AND status = 'active' "
    'AND source_voucher_line_id IN ($placeholders)',
    <Object?>[companyId.value, ...lineIds],
  );
  final int allocated = (allocs.first['a'] as int?) ?? 0;
  final int remaining = total - allocated;
  if (remaining < 0) {
    throw StateError('Impossible balance: allocated $allocated exceeds '
        'voucher total $total');
  }
  return remaining;
}

/// Source-side open of one voucher line (its amount minus active
/// allocations out of it). Throws on impossible history.
int lineOpenBalance(
  MigrationDb db,
  CompanyId companyId,
  EntityId lineId,
) {
  final List<Map<String, Object?>> lines = db.queryArgs(
    'SELECT amount_paise FROM voucher_line '
    'WHERE company_id = ? AND voucher_line_id = ?',
    <Object?>[companyId.value, lineId.value],
  );
  if (lines.isEmpty) return 0;
  final int total = lines.first['amount_paise'] as int;
  final List<Map<String, Object?>> allocs = db.queryArgs(
    'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
    "WHERE company_id = ? AND status = 'active' "
    'AND source_voucher_line_id = ?',
    <Object?>[companyId.value, lineId.value],
  );
  final int allocated = (allocs.first['a'] as int?) ?? 0;
  final int remaining = total - allocated;
  if (remaining < 0) {
    throw StateError('Impossible balance: allocated $allocated exceeds '
        'line total $total');
  }
  return remaining;
}

/// Settlement-side remainder of one voucher line: |line total| minus active
/// allocations consuming it (the advance/unallocated amount sitting on a
/// payer/payee line). Throws on impossible history.
int lineUnallocated(
  MigrationDb db,
  CompanyId companyId,
  EntityId lineId,
) {
  final List<Map<String, Object?>> lines = db.queryArgs(
    'SELECT amount_paise FROM voucher_line '
    'WHERE company_id = ? AND voucher_line_id = ?',
    <Object?>[companyId.value, lineId.value],
  );
  if (lines.isEmpty) return 0;
  final int permitted = (lines.first['amount_paise'] as int).abs();
  final List<Map<String, Object?>> allocs = db.queryArgs(
    'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
    "WHERE company_id = ? AND status = 'active' "
    'AND settlement_voucher_line_id = ?',
    <Object?>[companyId.value, lineId.value],
  );
  final int allocated = (allocs.first['a'] as int?) ?? 0;
  final int remainder = permitted - allocated;
  if (remainder < 0) {
    throw StateError('Impossible balance: allocated $allocated exceeds '
        'permitted $permitted');
  }
  return remainder;
}

/// Bill lifecycle state (FR-M14-001: Open → Settled/Part-settled), derived
/// from posted totals — never stored.
String billState(int totalPaise, int allocatedPaise) {
  if (allocatedPaise <= 0) return 'open';
  if (allocatedPaise >= totalPaise) return 'settled';
  return 'part-settled';
}

/// One outstanding-report row: a posted voucher with its bill economics.
class OutstandingBill {
  const OutstandingBill({
    required this.voucherId,
    required this.voucherNo,
    required this.voucherType,
    required this.dateIso,
    required this.partyIds,
    required this.totalPaise,
    required this.allocatedPaise,
    required this.openPaise,
    required this.state,
    required this.ageDays,
  });

  final EntityId voucherId;
  final String voucherNo;
  final String voucherType;
  final String dateIso;
  final List<EntityId> partyIds;
  final int totalPaise;
  final int allocatedPaise;
  final int openPaise;
  final String state;
  final int ageDays;
}

/// Party receivable/payable rollup over posted lines carrying the party.
class PartyOutstanding {
  const PartyOutstanding({
    required this.partyId,
    required this.billedPaise,
    required this.allocatedPaise,
    required this.openPaise,
    required this.billCount,
  });

  final EntityId partyId;
  final int billedPaise;
  final int allocatedPaise;
  final int openPaise;
  final int billCount;
}

/// One aging bucket: open amount of bills whose age falls in
/// [minDays]..[maxDays] (max null = oldest bucket, no ceiling).
class AgingBucket {
  const AgingBucket({
    required this.label,
    required this.minDays,
    required this.maxDays,
    required this.openPaise,
    required this.billCount,
  });

  final String label;
  final int minDays;
  final int? maxDays;
  final int openPaise;
  final int billCount;
}

/// One advance line: a posted Payment/Receipt line with unallocated
/// remainder available for later bills (FR-M06-002 advances).
class AdvanceLine {
  const AdvanceLine({
    required this.lineId,
    required this.voucherId,
    required this.voucherNo,
    required this.partyIds,
    required this.totalPaise,
    required this.allocatedPaise,
    required this.unallocatedPaise,
  });

  final EntityId lineId;
  final EntityId voucherId;
  final String voucherNo;
  final List<EntityId> partyIds;
  final int totalPaise;
  final int allocatedPaise;
  final int unallocatedPaise;
}

/// One settlement-history entry, newest first, reversals included
/// (compensating history is reportable, never hidden).
class SettlementEntry {
  const SettlementEntry({
    required this.allocationId,
    required this.dateIso,
    required this.sourceVoucherId,
    required this.sourceVoucherNo,
    required this.settlementVoucherId,
    required this.settlementVoucherNo,
    required this.amountPaise,
    required this.status,
  });

  final String allocationId;
  final String dateIso;
  final EntityId sourceVoucherId;
  final String sourceVoucherNo;
  final EntityId settlementVoucherId;
  final String settlementVoucherNo;
  final int amountPaise;
  final String status;

  static SettlementEntry fromRow(Map<String, Object?> r) => SettlementEntry(
        allocationId: r['allocation_id'] as String,
        dateIso: r['allocation_date'] as String,
        sourceVoucherId: EntityId(r['source_voucher_id'] as String),
        sourceVoucherNo: r['source_no'] as String,
        settlementVoucherId: EntityId(r['settlement_voucher_id'] as String),
        settlementVoucherNo: r['settlement_no'] as String,
        amountPaise: r['allocated_amount_paise'] as int,
        status: r['status'] as String,
      );
}

/// Read-only outstanding/settlement report queries.
class OutstandingReport {
  const OutstandingReport(this._db);

  final MigrationDb _db;

  /// Open amount of one voucher (posted or not; see [voucherOpenBalance]).
  int voucherOpen(CompanyId companyId, EntityId voucherId) =>
      voucherOpenBalance(_db, companyId, voucherId);

  /// Source-side open of one voucher line (see [lineOpenBalance]).
  int lineOpen(CompanyId companyId, EntityId lineId) =>
      lineOpenBalance(_db, companyId, lineId);

  /// Settlement-side remainder of one voucher line (see [lineUnallocated]).
  int lineRemainder(CompanyId companyId, EntityId lineId) =>
      lineUnallocated(_db, companyId, lineId);

  int _ageDays(String voucherIso, NiavDate asOf) {
    final int days = DateTime.parse(asOf.iso)
        .difference(DateTime.parse(voucherIso))
        .inDays;
    return days < 0 ? 0 : days;
  }

  /// Posted vouchers with bill economics. [onlyOpen] drops fully settled
  /// rows; [partyId] keeps vouchers with a line carrying the party;
  /// [voucherType] keeps one voucher type (as stored). Posted M06
  /// accounting documents (Payment, Receipt, Contra, Journal) are excluded
  /// unless [includeSettlementTypes]: their source-side "open" is not a
  /// receivable — unallocated money on payments/receipts is reported by
  /// [advances] instead (FR-M06-002).
  List<OutstandingBill> bills(
    CompanyId companyId, {
    required NiavDate asOf,
    EntityId? partyId,
    String? voucherType,
    bool onlyOpen = true,
    bool includeSettlementTypes = false,
  }) {
    final StringBuffer sql = StringBuffer(
      'SELECT voucher_id, voucher_no, voucher_type, voucher_date '
      "FROM voucher WHERE company_id = ? AND status = 'posted'",
    );
    final List<Object?> args = <Object?>[companyId.value];
    if (voucherType != null) {
      sql.write(' AND voucher_type = ?');
      args.add(voucherType);
    }
    sql.write(' ORDER BY voucher_date, voucher_no');
    final List<Map<String, Object?>> vouchers =
        _db.queryArgs(sql.toString(), args);
    final List<VoucherTypeRow> regTypes = _registeredTypes(companyId);
    final List<OutstandingBill> out = <OutstandingBill>[];
    for (final Map<String, Object?> v in vouchers) {
      final EntityId voucherId = EntityId(v['voucher_id'] as String);
      if (!includeSettlementTypes &&
          _isNonBillType(v['voucher_type'] as String, regTypes)) {
        continue;
      }
      final List<Map<String, Object?>> lines = _db.queryArgs(
        // Bill economics live in the document lines (no Dr/Cr marker).
        // Engine-posted ledger arms (D3-A1, ledger + Dr/Cr) are the ledger
        // books' representation of the same money — counting them here would
        // double the bill, so they are excluded (partyOutstanding needs no
        // filter: arms never carry a party).
        'SELECT voucher_line_id, amount_paise, party_id FROM voucher_line '
        'WHERE company_id = ? AND voucher_id = ? AND dr_cr IS NULL',
        <Object?>[companyId.value, voucherId.value],
      );
      if (lines.isEmpty) continue;
      if (partyId != null &&
          lines.every((Map<String, Object?> l) =>
              l['party_id'] == null ||
              (l['party_id'] as String) != partyId.value)) {
        continue;
      }
      int total = 0;
      int allocated = 0;
      final Set<String> parties = <String>{};
      for (final Map<String, Object?> l in lines) {
        total += l['amount_paise'] as int;
        final Object? party = l['party_id'];
        if (party != null) parties.add(party as String);
        final List<Map<String, Object?>> allocs = _db.queryArgs(
          'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
          "WHERE company_id = ? AND status = 'active' "
          'AND source_voucher_line_id = ?',
          <Object?>[companyId.value, l['voucher_line_id'] as String],
        );
        allocated += (allocs.first['a'] as int?) ?? 0;
      }
      final int open = total - allocated;
      if (open < 0) {
        throw StateError('Impossible balance on voucher ${voucherId.value}');
      }
      if (onlyOpen && open == 0) continue;
      out.add(OutstandingBill(
        voucherId: voucherId,
        voucherNo: v['voucher_no'] as String,
        voucherType: v['voucher_type'] as String,
        dateIso: v['voucher_date'] as String,
        partyIds: <EntityId>[
          for (final String p in parties) EntityId(p),
        ],
        totalPaise: total,
        allocatedPaise: allocated,
        openPaise: open,
        state: billState(total, allocated),
        ageDays: _ageDays(v['voucher_date'] as String, asOf),
      ));
    }
    return out;
  }

  /// Receivable/payable rollup for one party: billed over posted bill
  /// lines carrying the party (M06 settlement/adjustment documents are
  /// not bills — their effect appears via allocations and advances),
  /// minus active allocations out of those lines.
  PartyOutstanding partyOutstanding(CompanyId companyId, EntityId partyId) {
    final List<VoucherTypeRow> regTypes = _registeredTypes(companyId);
    final List<Map<String, Object?>> lines = _db.queryArgs(
      'SELECT l.amount_paise AS amount, l.voucher_id AS voucher, '
      'l.voucher_line_id AS line, v.voucher_type AS type '
      'FROM voucher_line l '
      'JOIN voucher v ON v.voucher_id = l.voucher_id '
      "WHERE l.company_id = ? AND l.party_id = ? AND v.status = 'posted'",
      <Object?>[companyId.value, partyId.value],
    );
    int billed = 0;
    int allocated = 0;
    final Set<String> vouchers = <String>{};
    for (final Map<String, Object?> l in lines) {
      if (_isNonBillType(l['type'] as String, regTypes)) continue;
      billed += l['amount'] as int;
      vouchers.add(l['voucher'] as String);
      final List<Map<String, Object?>> allocs = _db.queryArgs(
        'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
        "WHERE company_id = ? AND status = 'active' "
        'AND source_voucher_line_id = ?',
        <Object?>[companyId.value, l['line'] as String],
      );
      allocated += (allocs.first['a'] as int?) ?? 0;
    }
    final int open = billed - allocated;
    if (open < 0) {
      throw StateError(
          'Impossible balance on party ${partyId.value}');
    }
    return PartyOutstanding(
      partyId: partyId,
      billedPaise: billed,
      allocatedPaise: allocated,
      openPaise: open,
      billCount: vouchers.length,
    );
  }

  /// Open amount grouped into age buckets by document date. [cutoffs] are
  /// caller-owned bucket ceilings in days (e.g. [30, 60, 90] → 0–30, 31–60,
  /// 61–90, 90+); bucket boundaries are a presentation choice, never a
  /// statutory rule. Due-date aging waits on a schema column.
  List<AgingBucket> aging(
    CompanyId companyId, {
    required NiavDate asOf,
    List<int> cutoffs = const <int>[30, 60, 90],
    EntityId? partyId,
  }) {
    final List<int> edges = <int>[...cutoffs]..sort();
    final List<OutstandingBill> held =
        bills(companyId, asOf: asOf, partyId: partyId);
    final List<AgingBucket> out = <AgingBucket>[];
    int start = 0;
    for (int i = 0; i <= edges.length; i++) {
      final int? end = i < edges.length ? edges[i] : null;
      int open = 0;
      int count = 0;
      for (final OutstandingBill b in held) {
        if (b.ageDays >= start && (end == null || b.ageDays <= end)) {
          open += b.openPaise;
          count += 1;
        }
      }
      out.add(AgingBucket(
        label: end == null
            ? '${edges.isEmpty ? 0 : edges.last}+'
            : '$start–$end',
        minDays: start,
        maxDays: end,
        openPaise: open,
        billCount: count,
      ));
      if (end != null) start = end + 1;
    }
    return out;
  }

  /// M06 accounting documents (Payment, Receipt, Contra, Journal) settle
  /// or adjust — they are never bills. Matches canonical names, mechanical
  /// slugs, and registered company types with an M06 base.
  bool _isNonBillType(String typeText, List<VoucherTypeRow> regTypes) {
    const List<String> m06 = <String>[
      'Payment',
      'Receipt',
      'Contra',
      'Journal',
    ];
    for (final String name in m06) {
      if (typeText == name || typeText == voucherBaseSlug(name)) return true;
    }
    for (final VoucherTypeRow t in regTypes) {
      if (typeText == t.name) {
        for (final String name in m06) {
          if (t.baseType == name ||
              t.baseType == voucherBaseSlug(name)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Payment/Receipt documents only (advance carriers, FR-M06-002).
  bool _isPaymentOrReceipt(String typeText, List<VoucherTypeRow> regTypes) {
    const List<String> pr = <String>['Payment', 'Receipt'];
    for (final String name in pr) {
      if (typeText == name || typeText == voucherBaseSlug(name)) return true;
    }
    for (final VoucherTypeRow t in regTypes) {
      if (typeText == t.name) {
        for (final String name in pr) {
          if (t.baseType == name ||
              t.baseType == voucherBaseSlug(name)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<VoucherTypeRow> _registeredTypes(CompanyId companyId) {
    final List<Map<String, Object?>> regRows = _db.queryArgs(
      'SELECT name, base_type FROM voucher_type WHERE company_id = ?',
      <Object?>[companyId.value],
    );
    return <VoucherTypeRow>[
      for (final Map<String, Object?> r in regRows)
        VoucherTypeRow(
            name: r['name'] as String, baseType: r['base_type'] as String),
    ];
  }

  /// Advance (unallocated) lines: posted Payment/Receipt lines whose
  /// settlement-side remainder exceeds zero, oldest first. Only
  /// Payment/Receipt carry advances (FR-M06-002) — Contra/Journal remainders
  /// are not advance money.
  List<AdvanceLine> advances(
    CompanyId companyId, {
    EntityId? partyId,
  }) {
    final List<VoucherTypeRow> regTypes = _registeredTypes(companyId);
    final List<Map<String, Object?>> vouchers = _db.queryArgs(
      'SELECT voucher_id, voucher_no, voucher_type FROM voucher '
      "WHERE company_id = ? AND status = 'posted' "
      'ORDER BY voucher_date, voucher_no',
      <Object?>[companyId.value],
    );
    final List<AdvanceLine> out = <AdvanceLine>[];
    for (final Map<String, Object?> v in vouchers) {
      if (!_isPaymentOrReceipt(v['voucher_type'] as String, regTypes)) {
        continue;
      }
      final EntityId voucherId = EntityId(v['voucher_id'] as String);
      final List<Map<String, Object?>> lines = _db.queryArgs(
        'SELECT voucher_line_id, amount_paise, party_id FROM voucher_line '
        'WHERE company_id = ? AND voucher_id = ? ORDER BY line_no',
        <Object?>[companyId.value, voucherId.value],
      );
      for (final Map<String, Object?> l in lines) {
        final EntityId lineId = EntityId(l['voucher_line_id'] as String);
        if (partyId != null &&
            (l['party_id'] == null ||
                (l['party_id'] as String) != partyId.value)) {
          continue;
        }
        final int total = l['amount_paise'] as int;
        final List<Map<String, Object?>> allocs = _db.queryArgs(
          'SELECT SUM(allocated_amount_paise) AS a FROM bill_allocation '
          "WHERE company_id = ? AND status = 'active' "
          'AND settlement_voucher_line_id = ?',
          <Object?>[companyId.value, lineId.value],
        );
        final int allocated = (allocs.first['a'] as int?) ?? 0;
        final int remainder = total.abs() - allocated;
        if (remainder < 0) {
          throw StateError(
              'Impossible balance on advance line ${lineId.value}');
        }
        if (remainder == 0) continue;
        final Set<String> parties = <String>{};
        for (final Map<String, Object?> sib in lines) {
          if (sib['party_id'] != null) parties.add(sib['party_id'] as String);
        }
        out.add(AdvanceLine(
          lineId: lineId,
          voucherId: voucherId,
          voucherNo: v['voucher_no'] as String,
          partyIds: <EntityId>[for (final String p in parties) EntityId(p)],
          totalPaise: total,
          allocatedPaise: allocated,
          unallocatedPaise: remainder,
        ));
      }
    }
    return out;
  }

  /// Settlement history over bill_allocation rows joined to both vouchers,
  /// newest first. [voucherId] keeps entries touching the voucher on either
  /// side; reversals are included (history, never hidden).
  List<SettlementEntry> settlementHistory(
    CompanyId companyId, {
    EntityId? voucherId,
    int limit = 200,
  }) {
    final StringBuffer sql = StringBuffer(
      'SELECT a.allocation_id, a.allocation_date, a.allocated_amount_paise, '
      'a.status, sv.voucher_id AS source_voucher_id, '
      'sv.voucher_no AS source_no, tv.voucher_id AS settlement_voucher_id, '
      'tv.voucher_no AS settlement_no FROM bill_allocation a '
      'JOIN voucher_line sl ON sl.voucher_line_id = '
      'a.source_voucher_line_id '
      'JOIN voucher sv ON sv.voucher_id = sl.voucher_id '
      'JOIN voucher_line tl ON tl.voucher_line_id = '
      'a.settlement_voucher_line_id '
      'JOIN voucher tv ON tv.voucher_id = tl.voucher_id '
      'WHERE a.company_id = ?',
    );
    final List<Object?> args = <Object?>[companyId.value];
    if (voucherId != null) {
      sql.write(' AND (sv.voucher_id = ? OR tv.voucher_id = ?)');
      args.add(voucherId.value);
      args.add(voucherId.value);
    }
    sql.write(' ORDER BY a.allocation_date DESC, a.created_at DESC LIMIT ?');
    args.add(limit);
    final List<Map<String, Object?>> rows = _db.queryArgs(sql.toString(), args);
    return <SettlementEntry>[
      for (final Map<String, Object?> r in rows) SettlementEntry.fromRow(r),
    ];
  }
}

/// Minimal registered-type view (name + base) for advance-type matching.
class VoucherTypeRow {
  const VoucherTypeRow({required this.name, required this.baseType});

  final String name;
  final String baseType;
}
