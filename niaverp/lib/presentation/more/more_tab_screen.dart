// More tab — D4 (M01/M18–M24 P1 entry points, G1).
// Company switch/create (M01.1/M01.2, kept from onboarding), financial-year
// management (M01.3), company feature toggles (M01.4), period-lock
// administration (M01.7/D-M5), language (M02.1), about/diagnostics (M24
// test-safe info only) and a disabled backup/restore entry (M22.3, device
// evidence pending G0-VER-008). Users/roles (M18/M19, UI-013) and
// licence/trial (M20, UI-014) render as deferred rows: the documents define
// the screens but activation/key formats and multi-user auth wait on their
// gates (D4 §7). Every section carries loading/empty/validation/success and
// recoverable-failure states; repository codes map to localised messages,
// raw exception text is never shown (D4-B2). Feature toggles and language
// persist per company through the layout-profile store (FR-M23-001 local
// preferences): they change which preferences are stored, they do not gate
// engine behaviour in V1 Simple (recorded in D4 §6).
// Traceability: REG M01.1–M01.4/M01.7/M02.1/M22.3; FR-M01-001/002,
// FR-M02-001, FR-M23-001; UI-013/UI-014/UI-016/UI-017; UX-001/UX-004/UX-008.

import 'package:flutter/material.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/data/repositories/financial_year_repository.dart';
import 'package:niaverp/data/repositories/layout_profile_repository.dart';
import 'package:niaverp/data/repositories/period_lock.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// Test-safe app version (mirrors pubspec `version: 1.0.0+1`; update both).
const String kAppVersion = '1.0.0+1';

/// Feature toggles stored under this layout-profile key (FR-M23-001).
const String kFeaturesProfileKey = 'ui.features';

/// The nine M01.4 toggles. Multi-currency is TBC in the documents: it
/// renders locked-off and is never stored as enabled.
const List<String> kFeatureKeys = <String>[
  'featInventory',
  'featGst',
  'featBatch',
  'featExpiry',
  'featSerial',
  'featMultigodown',
  'featCostCentres',
  'featBillwise',
  'featApprovals',
];

/// More tab for [companyId]: P1 company/year/feature/lock/language/info.
class MoreTabScreen extends StatefulWidget {
  const MoreTabScreen({
    super.key,
    required this.companyId,
    required this.scope,
    required this.language,
    required this.onOpenCompany,
  });

  final CompanyId companyId;
  final CompanyScope scope;
  final LanguageController language;
  final ValueChanged<CompanyId> onOpenCompany;

  @override
  State<MoreTabScreen> createState() => MoreTabScreenState();
}

class MoreTabScreenState extends State<MoreTabScreen> {
  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;

  late Future<_MoreData> _data;

  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _fyStart = TextEditingController();
  final TextEditingController _fyEnd = TextEditingController();
  final TextEditingController _fyStatus = TextEditingController();
  final TextEditingController _lockFrom = TextEditingController();
  final TextEditingController _lockTo = TextEditingController();
  final TextEditingController _unlockReason = TextEditingController();

  String? _formError;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void dispose() {
    _companyName.dispose();
    _fyStart.dispose();
    _fyEnd.dispose();
    _fyStatus.dispose();
    _lockFrom.dispose();
    _lockTo.dispose();
    _unlockReason.dispose();
    super.dispose();
  }

  Future<_MoreData> _load() async {
    List<Company> companies;
    List<FinancialYear> years;
    List<PeriodLock> locks;
    try {
      companies = _companies();
      years = _scope.fyYears?.listByCompany(_company) ?? <FinancialYear>[];
      locks = _scope.periodLocks?.listByCompany(_company) ?? <PeriodLock>[];
    } catch (_) {
      // Never surface driver text: the error block shows a generic message.
      return _MoreData.failed();
    }
    return _MoreData(
      companies: companies,
      years: years,
      locks: locks,
      features: _readFeatures(),
      languageCode: LanguageController.readStored(_scope.layouts, _company),
      ok: true,
    );
  }

  List<Company> _companies() {
    final List<Map<String, Object?>> rows = _scope.companies.ctx.db.queryArgs(
      'SELECT company_id, name, created_at FROM company ORDER BY name',
      <Object?>[],
    );
    return <Company>[
      for (final Map<String, Object?> r in rows) Company.fromRow(r),
    ];
  }

  Map<String, bool> _readFeatures() {
    final Map<String, bool> out = <String, bool>{
      for (final String k in kFeatureKeys) k: true,
    };
    try {
      final String? json =
          _scope.layouts?.latest(_company, kFeaturesProfileKey)?.layoutJson;
      if (json == null) return out;
      for (final String k in kFeatureKeys) {
        final RegExpMatch? hit = RegExp('"$k"\\s*:\\s*(true|false)')
            .firstMatch(json);
        if (hit != null) out[k] = hit.group(1) == 'true';
      }
    } catch (_) {
      // Corrupt JSON reads as defaults; never throws into the widget.
    }
    return out;
  }

  Future<void> _refresh() async {
    setState(() {
      _formError = null;
      _data = _load();
    });
    await _data;
  }

  void _fail(AppLocalizations l10n, String code) {
    setState(() => _formError = l10n.errorFor(code));
  }

  Future<void> _createCompany(AppLocalizations l10n) async {
    final String name = _companyName.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = l10n.t('obNeedName'));
      return;
    }
    final Result<Company> result = _scope.companies.create(
      id: CompanyId(_scope.write.idMint('company')),
      name: name,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (!mounted) return;
    if (result.isErr) {
      _fail(l10n, (result as Err<Company>).error.code);
      return;
    }
    _companyName.clear();
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  Future<void> _createYear(AppLocalizations l10n) async {
    final FinancialYearRepository? repos = _scope.fyYears;
    if (repos == null) {
      setState(() => _formError = l10n.t('moreUnavailable'));
      return;
    }
    NiavDate start;
    NiavDate end;
    try {
      start = NiavDate(_fyStart.text.trim());
      end = NiavDate(_fyEnd.text.trim());
    } catch (_) {
      _fail(l10n, 'validation');
      return;
    }
    if (_fyStatus.text.trim().isEmpty) {
      _fail(l10n, 'validation');
      return;
    }
    final Result<FinancialYear> result = repos.create(
      id: EntityId(_scope.write.idMint('fy')),
      companyId: _company,
      startDate: start,
      endDate: end,
      status: _fyStatus.text.trim(),
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (!mounted) return;
    if (result.isErr) {
      _fail(l10n, (result as Err<FinancialYear>).error.code);
      return;
    }
    _fyStart.clear();
    _fyEnd.clear();
    _fyStatus.clear();
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  Future<void> _toggleFeature(
      AppLocalizations l10n, String key, bool value) async {
    final LayoutProfileRepository? layouts = _scope.layouts;
    if (layouts == null) {
      setState(() => _formError = l10n.t('moreUnavailable'));
      return;
    }
    final Map<String, bool> current = _readFeatures();
    current[key] = value;
    final int version =
        (layouts.latest(_company, kFeaturesProfileKey)?.version ?? 0) + 1;
    final String json =
        '{${current.entries.map((MapEntry<String, bool> e) => '"${e.key}":${e.value}').join(',')}}';
    final Result<LayoutProfile> result = layouts.save(
      id: EntityId(_scope.write.idMint('feat')),
      companyId: _company,
      profileKey: kFeaturesProfileKey,
      version: version,
      layoutJson: json,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (!mounted) return;
    if (result.isErr) {
      _fail(l10n, (result as Err<LayoutProfile>).error.code);
      return;
    }
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  Future<void> _createLock(AppLocalizations l10n) async {
    final PeriodLockRepository? repos = _scope.periodLocks;
    if (repos == null) {
      setState(() => _formError = l10n.t('moreUnavailable'));
      return;
    }
    if (_lockFrom.text.trim().isEmpty || _lockTo.text.trim().isEmpty) {
      _fail(l10n, 'validation');
      return;
    }
    final Result<PeriodLock> result = repos.create(
      id: EntityId(_scope.write.idMint('lock')),
      companyId: _company,
      scope: 'all',
      dateFrom: _lockFrom.text.trim(),
      dateTo: _lockTo.text.trim(),
      lockedBy: _scope.write.actor,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (!mounted) return;
    if (result.isErr) {
      _fail(l10n, (result as Err<PeriodLock>).error.code);
      return;
    }
    _lockFrom.clear();
    _lockTo.clear();
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  Future<void> _unlock(
      AppLocalizations l10n, EntityId lockId) async {
    final PeriodLockRepository? repos = _scope.periodLocks;
    if (repos == null) {
      setState(() => _formError = l10n.t('moreUnavailable'));
      return;
    }
    if (_unlockReason.text.trim().isEmpty) {
      _fail(l10n, 'validation');
      return;
    }
    final Result<PeriodLock> result = repos.unlock(
      id: lockId,
      companyId: _company,
      reason: _unlockReason.text.trim(),
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (!mounted) return;
    if (result.isErr) {
      _fail(l10n, (result as Err<PeriodLock>).error.code);
      return;
    }
    _unlockReason.clear();
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  Future<void> _setLanguage(AppLocalizations l10n, String code) async {
    final LayoutProfileRepository? layouts = _scope.layouts;
    if (layouts != null) {
      final int version =
          (layouts.latest(_company, LanguageController.profileKey)?.version ??
                  0) +
              1;
      final Result<LayoutProfile> result = layouts.save(
        id: EntityId(_scope.write.idMint('lang')),
        companyId: _company,
        profileKey: LanguageController.profileKey,
        version: version,
        layoutJson: '{"locale":"$code"}',
        deviceId: _scope.write.deviceId,
        opId: _scope.write.idMint('op'),
        eventId: _scope.write.idMint('ev'),
        actor: _scope.write.actor,
      );
      if (!mounted) return;
      if (result.isErr) {
        _fail(l10n, (result as Err<LayoutProfile>).error.code);
        return;
      }
    }
    widget.language.setCode(code);
    if (!mounted) return;
    setState(() => _notice = l10n.t('okSaved'));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: FutureBuilder<_MoreData>(
        future: _data,
        builder: (BuildContext context, AsyncSnapshot<_MoreData> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !(snap.data?.ok ?? false)) {
            return Center(
              key: const ValueKey<String>('more-error'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.t('errGeneric')),
                  TextButton(
                    key: const ValueKey<String>('more-retry'),
                    onPressed: _refresh,
                    child: Text(l10n.t('commonRetry')),
                  ),
                ],
              ),
            );
          }
          final _MoreData d = snap.data!;
          return ListView(
            key: const ValueKey<String>('more-tab'),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (_formError != null)
                Container(
                  key: const ValueKey<String>('more-error-inline'),
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Text(_formError!),
                ),
              if (_notice != null)
                Container(
                  key: const ValueKey<String>('more-notice'),
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(_notice!),
                ),
              _section(
                context,
                key: 'more-sec-companies',
                title: l10n.t('moreCompanies'),
                child: _companiesSection(l10n, d),
              ),
              _section(
                context,
                key: 'more-sec-years',
                title: l10n.t('moreYears'),
                child: _yearsSection(l10n, d),
              ),
              _section(
                context,
                key: 'more-sec-features',
                title: l10n.t('moreFeatures'),
                child: _featuresSection(l10n, d),
              ),
              _section(
                context,
                key: 'more-sec-locks',
                title: l10n.t('moreLocks'),
                child: _locksSection(l10n, d),
              ),
              _section(
                context,
                key: 'more-sec-language',
                title: l10n.t('moreLanguage'),
                child: _languageSection(l10n, d),
              ),
              _section(
                context,
                key: 'more-sec-about',
                title: l10n.t('moreAbout'),
                child: _aboutSection(l10n),
              ),
              _section(
                context,
                key: 'more-sec-backup',
                title: l10n.t('moreBackup'),
                child: _backupSection(l10n),
              ),
              _section(
                context,
                key: 'more-sec-admin',
                title: l10n.t('moreUsers'),
                child: _deferredRow(
                    l10n, 'more-row-users', l10n.t('moreLicence')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context,
      {required String key,
      required String title,
      required Widget child}) {
    return Card(
      key: ValueKey<String>(key),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _companiesSection(AppLocalizations l10n, _MoreData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (d.companies.isEmpty)
          Text(l10n.t('obEmpty'),
              key: const ValueKey<String>('more-companies-empty')),
        for (final Company c in d.companies)
          ListTile(
            key: ValueKey<String>('more-company-${c.id.value}'),
            title: Text(c.name),
            trailing: c.id == _company
                ? Text(l10n.t('aboutCompany'))
                : TextButton(
                    key: ValueKey<String>(
                        'more-open-${c.id.value}'),
                    onPressed: () => widget.onOpenCompany(c.id),
                    child: Text(l10n.t('commonOpen')),
                  ),
          ),
        TextField(
          key: const ValueKey<String>('more-company-name'),
          controller: _companyName,
          decoration:
              InputDecoration(labelText: l10n.t('obCompanyName')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey<String>('more-company-create'),
          onPressed: () => _createCompany(l10n),
          child: Text(l10n.t('obCreateCompany')),
        ),
      ],
    );
  }

  Widget _yearsSection(AppLocalizations l10n, _MoreData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (d.years.isEmpty)
          Text(l10n.t('moreEmpty'),
              key: const ValueKey<String>('more-years-empty')),
        for (final FinancialYear y in d.years)
          ListTile(
            key: ValueKey<String>('more-year-${y.id.value}'),
            title: Text('${y.startDate.iso} · ${y.endDate.iso}'),
            subtitle: Text(y.status),
          ),
        TextField(
          key: const ValueKey<String>('more-fy-start'),
          controller: _fyStart,
          decoration: InputDecoration(labelText: l10n.t('fyStart')),
        ),
        TextField(
          key: const ValueKey<String>('more-fy-end'),
          controller: _fyEnd,
          decoration: InputDecoration(labelText: l10n.t('fyEnd')),
        ),
        TextField(
          key: const ValueKey<String>('more-fy-status'),
          controller: _fyStatus,
          decoration: InputDecoration(labelText: l10n.t('fyStatus')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey<String>('more-fy-create'),
          onPressed: () => _createYear(l10n),
          child: Text(l10n.t('fyCreateYear')),
        ),
      ],
    );
  }

  Widget _featuresSection(AppLocalizations l10n, _MoreData d) {
    return Column(
      children: <Widget>[
        for (final String key in kFeatureKeys)
          SwitchListTile(
            key: ValueKey<String>('more-feat-$key'),
            title: Text(l10n.t(key)),
            value: d.features[key] ?? true,
            onChanged: (bool v) => _toggleFeature(l10n, key, v),
          ),
        ListTile(
          key: const ValueKey<String>('more-feat-multicurrency'),
          title: Text(l10n.t('featMulticurrency')),
          subtitle: Text(l10n.t('moreDeferredNote')),
          trailing: const Switch(value: false, onChanged: null),
        ),
      ],
    );
  }

  Widget _locksSection(AppLocalizations l10n, _MoreData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (d.locks.isEmpty)
          Text(l10n.t('moreEmpty'),
              key: const ValueKey<String>('more-locks-empty')),
        for (final PeriodLock lock in d.locks)
          ListTile(
            key: ValueKey<String>('more-lock-${lock.id.value}'),
            title: Text('${lock.dateFrom} · ${lock.dateTo}'),
            subtitle: Text(lock.isActive
                ? l10n.t('lockCreate')
                : l10n.t('lockUnlock')),
            trailing: lock.isActive
                ? TextButton(
                    key: ValueKey<String>(
                        'more-unlock-${lock.id.value}'),
                    onPressed: () => _unlock(l10n, lock.id),
                    child: Text(l10n.t('lockUnlock')),
                  )
                : null,
          ),
        TextField(
          key: const ValueKey<String>('more-lock-from'),
          controller: _lockFrom,
          decoration: InputDecoration(labelText: l10n.t('lockFrom')),
        ),
        TextField(
          key: const ValueKey<String>('more-lock-to'),
          controller: _lockTo,
          decoration: InputDecoration(labelText: l10n.t('lockTo')),
        ),
        TextField(
          key: const ValueKey<String>('more-unlock-reason'),
          controller: _unlockReason,
          decoration:
              InputDecoration(labelText: l10n.t('lockReason')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey<String>('more-lock-create'),
          onPressed: () => _createLock(l10n),
          child: Text(l10n.t('lockCreate')),
        ),
      ],
    );
  }

  Widget _languageSection(AppLocalizations l10n, _MoreData d) {
    const Map<String, String> nameKeys = <String, String>{
      'en': 'langEnglish',
      'hi': 'langHindi',
      'gu': 'langGujarati',
    };
    return RadioGroup<String>(
      groupValue: widget.language.code,
      onChanged: (String? v) {
        if (v != null) _setLanguage(l10n, v);
      },
      child: Column(
        children: <Widget>[
          for (final String code in kLanguageCodes)
            RadioListTile<String>(
              key: ValueKey<String>('more-lang-$code'),
              title: Text(l10n.t(nameKeys[code]!)),
              value: code,
            ),
        ],
      ),
    );
  }

  Widget _aboutSection(AppLocalizations l10n) {
    final String companyName =
        _scope.companies.get(_company)?.name ?? _company.value;
    return Column(
      children: <Widget>[
        ListTile(
          key: const ValueKey<String>('more-about-app'),
          title: Text(l10n.t('aboutAppVersion')),
          trailing: Text(kAppVersion),
        ),
        ListTile(
          key: const ValueKey<String>('more-about-schema'),
          title: Text(l10n.t('aboutSchema')),
          trailing: Text('v$kLatestVersion'),
        ),
        ListTile(
          key: const ValueKey<String>('more-about-lang'),
          title: Text(l10n.t('aboutLanguage')),
          trailing: Text(widget.language.code),
        ),
        ListTile(
          key: const ValueKey<String>('more-about-company'),
          title: Text(companyName),
          subtitle: Text(l10n.t('aboutCompany')),
        ),
      ],
    );
  }

  Widget _backupSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.t('moreBackupNote'),
            key: const ValueKey<String>('more-backup-note')),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey<String>('more-backup-run'),
          onPressed: null,
          child: Text(l10n.t('moreBackup')),
        ),
      ],
    );
  }

  Widget _deferredRow(AppLocalizations l10n, String key, String licence) {
    return Column(
      children: <Widget>[
        ListTile(
          key: ValueKey<String>(key),
          title: Text(l10n.t('moreUsers')),
          subtitle: Text(l10n.t('moreDeferredNote')),
          enabled: false,
        ),
        ListTile(
          key: const ValueKey<String>('more-row-licence'),
          title: Text(licence),
          subtitle: Text(l10n.t('moreDeferredNote')),
          enabled: false,
        ),
      ],
    );
  }
}

class _MoreData {
  const _MoreData({
    required this.companies,
    required this.years,
    required this.locks,
    required this.features,
    required this.languageCode,
    required this.ok,
  });

  factory _MoreData.failed() => const _MoreData(
        companies: <Company>[],
        years: <FinancialYear>[],
        locks: <PeriodLock>[],
        features: <String, bool>{},
        languageCode: 'en',
        ok: false,
      );

  final List<Company> companies;
  final List<FinancialYear> years;
  final List<PeriodLock> locks;
  final Map<String, bool> features;
  final String languageCode;
  final bool ok;
}
