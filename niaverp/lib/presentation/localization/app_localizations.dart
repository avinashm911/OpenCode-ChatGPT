// NiAvERP localisation runtime — D4 (M02, D-03: en/hi/gu at launch).
// ARB files under lib/l10n are the source of truth (D-03 launch set;
// extensible by adding an ARB + font/print check, no code change per ZCP).
// [AppLocalizations] resolves keys from the checked-in mirror of those ARBs
// (tool_gen_l10n.js); [AppLocalizationsDelegate] wires supportedLocales.
// Terms the UX glossary fixes (UX §6) are used verbatim; every other hi/gu
// string is single-author and flagged in the D4 translator-review list.
// Language choice persists per company through the existing layout-profile
// store (FR-M23-001 local preferences): no new table, no user model in V1
// Simple — user-level scoping awaits the M19 slice (recorded in D4 §7).
// Traceability: FR-M02-001; REG M02.1/M02.2/M02.3; UX §6 glossary + §7 rules;
// AC-002; TC-M02-001/002.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/repositories/layout_profile_repository.dart';

import 'app_localizations_maps.dart';

/// Supported launch locales (D-03). Order: English, Hindi, Gujarati.
const List<Locale> kSupportedLocales = <Locale>[
  Locale('en'),
  Locale('hi'),
  Locale('gu'),
];

/// Language options shown in the selector (autonyms in every locale).
const List<String> kLanguageCodes = <String>['en', 'hi', 'gu'];

/// Resolved UI strings for one locale.
class AppLocalizations {
  const AppLocalizations(this.localeCode);

  /// ISO 639 code: 'en', 'hi' or 'gu'. Unknown codes fall back to 'en'.
  final String localeCode;

  static const AppLocalizations english = AppLocalizations('en');

  /// Lookup with English fallback. Never throws: missing keys return the
  /// English value, and a missing English value returns the key itself
  /// (tests assert the maps are complete, so this is a last-resort guard).
  String t(String key) {
    final Map<String, String>? table = kArbMaps[localeCode];
    final String? hit = table?[key];
    if (hit != null) return hit;
    return kArbMaps['en']?[key] ?? key;
  }

  /// Localised message for a repository/engine error code. Raw exception
  /// text is never shown to users (D4-B2): codes map to resources.
  String errorFor(String code) {
    switch (code) {
      case 'validation':
        return t('errValidation');
      case 'conflict':
        return t('errConflict');
      case 'locked':
        return t('errLocked');
      case 'not-found':
        return t('errNotFound');
      default:
        return t('errGeneric');
    }
  }

  // Composite patterns: human words from ARB, runtime data interpolated.
  // (Amounts/dates render through the single NiavFormat formatter.)

  /// `'Invoice <no>'`.
  String invoiceTitle(String no) => '${t('ivInvoice')} $no';

  /// `'No: <no> · Date: <iso>'`.
  String noDate(String no, String iso) =>
      '${t('wordNo')}: $no · ${t('wordDate')}: $iso';

  /// `'Status: <status>'`.
  String statusLine(String status) => '${t('wordStatus')}: $status';

  /// `'Narration: <narration>'`.
  String narrationLine(String narration) =>
      '${t('wordNarration')}: $narration';

  /// `'Open: <amount>'`.
  String openLine(String amount) => '${t('wordOpen')}: $amount';

  /// `'Note: <note>'`.
  String noteLine(String note) => '${t('wordNote')}: $note';

  /// `'Record <name>'`.
  String recordWhat(String name) => '${t('wordRecord')} $name';

  /// `'Posted <id>.'`.
  String postedMsg(String id) => '${t('commonPost')} $id.';

  /// `'Gross: <g> · Net: <n>'`.
  String grossNet(String gross, String net) =>
      '${t('wordGross')}: $gross · ${t('wordNet')}: $net';

  /// `'Line <i>: <msg>'` (1-based display index passed in).
  String numberedLine(int oneBased, String msg) =>
      '${t('wordLine')} $oneBased: $msg';

  /// `'Row <i>: <msg>'` (1-based display index passed in).
  String numberedRow(int oneBased, String msg) =>
      '${t('wordRow')} $oneBased: $msg';

  /// `'Lines: <n>'`.
  String linesCount(int n) => '${t('vfLinesWord')}: $n';

  /// `'Post <type>?'`.
  String confirmPost(String type) => '${t('commonPost')} $type?';

  /// `'No type registered'` with the canonical type name interpolated.
  /// The type name itself is a canonical master value (data, not UI).
  String noTypeRegistered(String type) =>
      '${t('wordNo')} $type ${t('vfNoTypeTail')}';

  /// `'Auto-numbered on post (<name>).'`.
  String autoNumbered(String name) =>
      "${t('vfAutoNumberedPre')}$name).";

  /// `'Bill <no> has no allocatable lines.'`
  String billNoAlloc(String no) =>
      '${t('wordBill')} $no ${t('lvNoAllocTail')}';

  /// `'<Done> posted and fully applied.'`
  String appliedMsg(String done) => '$done ${t('ivAppliedTail')}';

  /// `'<Done> posted; advance <amt> remains.'`
  String advanceMsg(String done, String amt) =>
      '$done ${t('ivAdvanceMid')} $amt ${t('ivRemainsTail')}';

  /// `'<Suffix> amount must be positive.'`
  String needPositive(String suffix) => '$suffix ${t('ivNeedPositiveTail')}';

  /// `'Stock Journal <no>' / 'Transfer <no>'`.
  String journalTitle(String no) => '${t('hubStockJournal')} $no';
  String transferTitle(String no) => '${t('hubTransfer')} $no';

  /// `'<date> · <series> · <n> lines'`.
  String dayRowSub(String date, String series, int n) =>
      '$date · $series · $n ${t('booksLinesWord')}';

  /// `'<n> vouchers · gross <amt>'`.
  String vouchersGross(int n, String amt) =>
      '$n ${t('booksVouchersWord')} · ${t('booksGrossWord')} $amt';

  /// `'<n> ledgers'`.
  String ledgersCount(int n) => '$n ${t('booksLedgersWord')}';

  /// `'Out of balance by <amt>'`.
  String outOfBalance(String amt) => '${t('outOfBalPre')}$amt';

  /// `'<amt> · bal <bal>'`.
  String ledgerBalLine(String amt, String bal) =>
      '$amt · ${t('booksBalWord')} $bal';

  /// `'<n> bills · <total> open'`.
  String billsOpen(int n, String total) =>
      '$n ${t('outBillsWord')} · $total ${t('outOpenWord')}';

  /// `'Qty <q> @ <r>'`.
  String qtyAtLine(String q, String r) => '${t('wordQtyAt')} $q @ $r';

  /// `'Amount (₹, open <amt>)'`.
  String amountOpen(String amt) => 'Amount (₹, open $amt)';

  /// `'<no> (open <amt>)'`.
  String allocLabel(String no, String amt) =>
      '$no (${t('outOpenWord')} $amt)';

  /// `'Reference: <code>'`.
  String referenceCode(String code) => '${t('stReferencePre')}$code';

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? found =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return found ?? english;
  }
}

/// Delegate wiring [AppLocalizations] into Flutter's locale resolution.
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final String code = kLanguageCodes.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return AppLocalizations(code);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Company-scoped language choice (FR-M23-001 local preferences).
/// Persisted as profile key 'ui.language' with JSON '{"locale":"hi"}';
/// version increments per save. Falls back to English when nothing stored.
class LanguageController extends ChangeNotifier {
  LanguageController({String initialCode = 'en'})
      : _code = kLanguageCodes.contains(initialCode) ? initialCode : 'en';

  static const String profileKey = 'ui.language';

  String _code;

  String get code => _code;

  Locale get locale => Locale(_code);

  void setCode(String code) {
    final String next =
        kLanguageCodes.contains(code) ? code : 'en';
    if (next == _code) return;
    _code = next;
    notifyListeners();
  }

  /// Read the stored choice for [companyId] (null-safe, sync reads).
  /// Returns 'en' when nothing valid is stored.
  static String readStored(
    LayoutProfileRepository? layouts,
    CompanyId companyId,
  ) {
    try {
      final String? json = layouts?.latest(companyId, profileKey)?.layoutJson;
      if (json == null) return 'en';
      final RegExpMatch? hit =
          RegExp(r'"locale"\s*:\s*"([a-z-]{2,8})"').firstMatch(json);
      final String code = hit?.group(1) ?? 'en';
      return kLanguageCodes.contains(code) ? code : 'en';
    } catch (_) {
      return 'en';
    }
  }
}
