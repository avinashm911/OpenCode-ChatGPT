// Active-company scope for tabs — navigation slice.
// [CompanyScope] bundles the repository/query objects the five destinations
// need, plus the write identity and the report date. Widgets take this
// instead of a backend bundle so presentation never depends on the app
// layer (composition_root builds the bundle; a small converter there maps
// it to this scope). The scope carries no company id: the shell keeps the
// selected company as navigation state (company switching is navigation,
// not business data).
// Traceability: OD-UI-001 / G0-CON-005 (five-item model).

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/queries/stock_levels.dart';
import 'package:niaverp/application/services/numbering.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/repositories/alias_repository.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/shared/screen_wiring.dart';

/// Repository/query surface behind the five tabs. Null scope means the D1
/// startup sequence has not delivered a backend yet (P-SQLIB approved
/// 2026-10-05): tabs render
/// the scope gate, never fake data.
class CompanyScope {
  const CompanyScope({
    required this.companies,
    required this.parties,
    required this.items,
    required this.aliases,
    required this.search,
    required this.godowns,
    required this.stock,
    required this.books,
    required this.ledgers,
    required this.outstanding,
    required this.vouchers,
    required this.types,
    required this.numbering,
    required this.engine,
    required this.write,
    required this.today,
  });

  final CompanyRepository companies;
  final PartyRepository parties;
  final ItemRepository items;
  final AliasRepository aliases;
  final MasterSearch search;
  final GodownRepository godowns;
  final StockLevels stock;
  final LedgerBooks books;
  final LedgerRepository ledgers;
  final OutstandingReport outstanding;
  final VoucherRepository vouchers;
  final VoucherTypeRepository types;
  final SeriesNumbering numbering;
  final VoucherEngine engine;
  final WriteContext write;
  final NiavDate today;
}
