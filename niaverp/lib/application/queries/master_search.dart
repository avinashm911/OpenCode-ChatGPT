// NiAvERP master search — Phase 02, application query (M12 subset, G1),
// extended by prompt 03 with voucher-number lookup (FR-M12-001).
// Substring search over approved stored fields plus user-entered aliases:
// parties by name/GSTIN/mobile/alias, items by name/code/barcode/alias,
// vouchers by number/series.
// Matching is LIKE on stored text in either script as entered. Explicitly
// OUT of this slice: fuzzy/typo tolerance (P2, M12.4), transliteration
// (excluded, G0-DEF-003), numeric latency targets (TBC, M12.8), recent/
// favourites storage (M12.6 — no approved table), type/date/amount filters
// (P2, M12.5). Company scope is always enforced; empty queries match nothing.
// Traceability: REG M12.3; FR-M12-001; G0-DEF-003; DSS-C-001.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';

/// Caller-overridable row cap. An implementation safety default, NOT a
/// documented performance target (M12.8 remains TBC).
const int kDefaultSearchLimit = 50;

/// Escape LIKE wildcards so user text matches literally.
String escapeLike(String raw) {
  return raw
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Search over party and item masters.
class MasterSearch {
  const MasterSearch(this._db);

  final MigrationDb _db;

  static const String _partyCols =
      'p.party_id, p.company_id, p.ledger_id, p.name, p.role, p.gstin, '
      'p.state, p.mobile, p.address, p.terms, p.created_at';

  /// Parties whose name, GSTIN, mobile, or alias contains [query]
  /// (case-insensitive ASCII; native script matches as stored).
  List<Party> searchParties(
    CompanyId companyId,
    String query, {
    int limit = kDefaultSearchLimit,
  }) {
    final String q = query.trim();
    if (q.isEmpty) return <Party>[];
    final String e = escapeLike(q);
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT DISTINCT $_partyCols FROM party p '
      'LEFT JOIN search_alias a ON a.company_id = p.company_id '
      "AND a.entity = 'party' AND a.entity_id = p.party_id "
      "WHERE p.company_id = ? AND (p.name LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR p.gstin LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR p.mobile LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR a.alias LIKE '%' || ? || '%' ESCAPE '\\') "
      "ORDER BY CASE WHEN p.name LIKE ? || '%' ESCAPE '\\' THEN 0 ELSE 1 END, "
      'p.name LIMIT ?',
      <Object?>[
        companyId.value,
        e,
        e,
        e,
        e,
        e,
        limit,
      ],
    );
    return <Party>[for (final Map<String, Object?> r in rows) Party.fromRow(r)];
  }

  static const String _itemCols =
      'i.item_id, i.company_id, i.name, i.unit, i.created_at, i.code, '
      'i.barcode, i.hsn_code, i.gst_rate_bps, i.tax_rate_id, i.group_id, '
      'i.unit_id';

  /// Items whose name, code, barcode, or alias contains [query].
  List<Item> searchItems(
    CompanyId companyId,
    String query, {
    int limit = kDefaultSearchLimit,
  }) {
    final String q = query.trim();
    if (q.isEmpty) return <Item>[];
    final String e = escapeLike(q);
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT DISTINCT $_itemCols FROM item i '
      'LEFT JOIN search_alias a ON a.company_id = i.company_id '
      "AND a.entity = 'item' AND a.entity_id = i.item_id "
      "WHERE i.company_id = ? AND (i.name LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR i.code LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR i.barcode LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR a.alias LIKE '%' || ? || '%' ESCAPE '\\') "
      "ORDER BY CASE WHEN i.name LIKE ? || '%' ESCAPE '\\' THEN 0 ELSE 1 END, "
      'i.name LIMIT ?',
      <Object?>[
        companyId.value,
        e,
        e,
        e,
        e,
        e,
        limit,
      ],
    );
    return <Item>[for (final Map<String, Object?> r in rows) Item.fromRow(r)];
  }

  /// Vouchers whose number or series contains [query] (stored text only;
  /// numbering/series semantics stay with the voucher engine, prompt 04).
  List<Voucher> searchVouchers(
    CompanyId companyId,
    String query, {
    int limit = kDefaultSearchLimit,
  }) {
    final String q = query.trim();
    if (q.isEmpty) return <Voucher>[];
    final String e = escapeLike(q);
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT voucher_id, company_id, voucher_type, series, voucher_no, '
      'voucher_date, status, created_at FROM voucher '
      "WHERE company_id = ? AND (voucher_no LIKE '%' || ? || '%' ESCAPE '\\' "
      "OR series LIKE '%' || ? || '%' ESCAPE '\\') "
      "ORDER BY CASE WHEN voucher_no LIKE ? || '%' ESCAPE '\\' THEN 0 ELSE 1 END, "
      'voucher_no LIMIT ?',
      <Object?>[
        companyId.value,
        e,
        e,
        e,
        limit,
      ],
    );
    return <Voucher>[for (final Map<String, Object?> r in rows) Voucher.fromRow(r)];
  }
}
