// NiAvERP five-item navigation shell — navigation slice, D4 lazy tabs.
// Authoritative model (OD-UI-001 / G0-CON-005): Home, Billing,
// Parties & Items, Reports, More. Every tab renders a real destination
// bound to the injected [CompanyScope]. The shell stores only navigation
// state (selected tab + selected company + built-tab set). No business state
// lives here.
// D4: tabs build lazily — only visited tabs construct their pages (C1), so
// startup never runs heavy synchronous DB work for all five tabs at once.
// Tab labels and the offline badge resolve through [AppLocalizations]
// (M02.1); icon-only affordances carry tooltips/semantics (UX-009).
// Without a scope every tab renders the scope gate — honest unavailability,
// never fake data. Without a selected company the shell shows onboarding
// (create/open) full-screen.
// Traceability: OD-UI-001; G0-CON-005; DECISIONS.md; FR-M02-001.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/billing/billing_hub_screen.dart';
import 'package:niaverp/presentation/home/home_dashboard_screen.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/more/more_tab_screen.dart';
import 'package:niaverp/presentation/onboarding/onboarding_screen.dart';
import 'package:niaverp/presentation/parties_items/parties_items_screen.dart';
import 'package:niaverp/presentation/reports/reports_hub_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// The five top-level destinations. Order is part of the approved model.
enum NiavDestination {
  home('navHome', Icons.home),
  billing('navBilling', Icons.receipt_long),
  partiesItems('navPartiesItems', Icons.groups),
  reports('navReports', Icons.bar_chart),
  more('navMore', Icons.more_horiz);

  const NiavDestination(this.titleKey, this.icon);

  /// Localisation key for the tab label (D4-A2).
  final String titleKey;
  final IconData icon;
}

/// Five-item shell backed by a lazily-built [IndexedStack].
class NiavShell extends StatefulWidget {
  const NiavShell({
    super.key,
    required this.title,
    this.scope,
    this.initialCompanyId,
    this.language,
  });

  final String title;

  /// Backend surface behind the tabs. Null until the D1 startup sequence
  /// delivers the encrypted backend (P-SQLIB approved 2026-10-05): tabs render
  final CompanyScope? scope;

  /// Company selected before first build (tests, deep links). Null starts
  /// at onboarding when a scope is present.
  final CompanyId? initialCompanyId;

  /// Language choice (D4-A1). Null renders English.
  final LanguageController? language;

  @override
  State<NiavShell> createState() => NiavShellState();
}

/// Exposed for tests (selected tab/company are navigation chrome, not
/// business state).
class NiavShellState extends State<NiavShell> {
  int selectedIndex = 0;
  CompanyId? selectedCompanyId;

  /// Tabs already visited (built at least once). Lazy: startup builds only
  /// the selected tab; the rest materialise on first visit (D4-C1).
  final Set<int> _built = <int>{0};

  @override
  void initState() {
    super.initState();
    selectedCompanyId = widget.initialCompanyId;
  }

  @override
  void didUpdateWidget(NiavShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCompanyId != widget.initialCompanyId) {
      setState(() {
        selectedCompanyId = widget.initialCompanyId;
        _built.clear();
        _built.add(0);
      });
    }
  }

  void selectTab(int index) {
    setState(() {
      selectedIndex = index;
      _built.add(index);
    });
  }

  void openCompany(CompanyId id) {
    setState(() {
      selectedCompanyId = id;
      _built.clear();
      _built.add(0); // reset lazy build; only selected tab stays built
    });
  }

  /// Persistent, non-alarming offline marker (UX-007): V1 stores everything
  /// on this device and syncs nothing — the badge states exactly that.
  Widget _offlineBadge(AppLocalizations l10n) {
    return Tooltip(
      message: l10n.t('offlineTip'),
      child: Semantics(
        label: l10n.t('offlineTip'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off, size: 18),
              const SizedBox(width: 4),
              Text(l10n.t('offlineBadge'),
                  key: const ValueKey<String>('offline-indicator')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gate(String destination, AppLocalizations l10n) {
    return Center(
      key: ValueKey<String>('scope-gate-$destination'),
      child: Text(l10n.t('scopeGate')),
    );
  }

  Widget _tabPage(NiavDestination d, CompanyScope scope, CompanyId company) {
    switch (d) {
      case NiavDestination.home:
        return HomeDashboardScreen(
          key: ValueKey<String>('tab-page-home-${company.id}'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.billing:
        return BillingHubScreen(
          key: ValueKey<String>('tab-page-billing-${company.id}'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.partiesItems:
        return PartiesItemsScreen(
          key: ValueKey<String>('tab-page-partiesItems-${company.id}'),
          companyId: company,
          parties: scope.parties,
          items: scope.items,
          aliases: scope.aliases,
          search: scope.search,
          write: scope.write,
        );
      case NiavDestination.reports:
        return ReportsHubScreen(
          key: ValueKey<String>('tab-page-reports-${company.id}'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.more:
        return MoreTabScreen(
          key: ValueKey<String>('tab-page-more-${company.id}'),
          companyId: company,
          scope: scope,
          language:
              widget.language ?? LanguageController(),
          onOpenCompany: openCompany,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<NiavDestination> destinations = NiavDestination.values;
    final CompanyScope? scope = widget.scope;
    final CompanyId? company = selectedCompanyId;
    if (scope == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[_offlineBadge(l10n)],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: <Widget>[
            for (final NiavDestination d in destinations)
              _gate(d.name, l10n),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: selectTab,
          items: <BottomNavigationBarItem>[
            for (final NiavDestination d in destinations)
              BottomNavigationBarItem(
                  icon: Icon(d.icon), label: l10n.t(d.titleKey)),
          ],
        ),
      );
    }
    if (company == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[_offlineBadge(l10n)],
        ),
        body: OnboardingScreen(
          key: const ValueKey<String>('company-gate'),
          companies: scope.companies,
          write: scope.write,
          onOpen: openCompany,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[_offlineBadge(l10n)],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          for (int i = 0; i < destinations.length; i++)
            _built.contains(i)
                ? _tabPage(destinations[i], scope, company)
                : SizedBox.shrink(
                    key: ValueKey<String>('tab-lazy-placeholder-$i')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: selectTab,
        items: <BottomNavigationBarItem>[
          for (final NiavDestination d in destinations)
            BottomNavigationBarItem(
                icon: Icon(d.icon), label: l10n.t(d.titleKey)),
        ],
      ),
    );
  }
}
