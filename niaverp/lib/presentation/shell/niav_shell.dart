// NiAvERP five-item navigation shell — navigation slice.
// Authoritative model (OD-UI-001 / G0-CON-005): Home, Billing,
// Parties & Items, Reports, More. Every tab renders a real destination
// bound to the injected [CompanyScope]: the home dashboard, the billing
// bill list, the parties & items masters, the reports hub, and company
// management (open/switch via onboarding). The shell stores only navigation
// state (selected tab + selected company). No business state lives here.
// Without a scope (production engine pending P-SQLIB) every tab renders
// the scope gate — honest unavailability, never fake data. Without a
// selected company the shell shows onboarding (create/open) full-screen.
// Traceability: OD-UI-001; G0-CON-005; DECISIONS.md.

import 'package:flutter/material.dart';

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/presentation/billing/billing_hub_screen.dart';
import 'package:niaverp/presentation/home/home_dashboard_screen.dart';
import 'package:niaverp/presentation/onboarding/onboarding_screen.dart';
import 'package:niaverp/presentation/parties_items/parties_items_screen.dart';
import 'package:niaverp/presentation/reports/reports_hub_screen.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// The five top-level destinations. Order is part of the approved model.
enum NiavDestination {
  home('Home', Icons.home),
  billing('Billing', Icons.receipt_long),
  partiesItems('Parties & Items', Icons.groups),
  reports('Reports', Icons.bar_chart),
  more('More', Icons.more_horiz);

  const NiavDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Five-item shell backed by an [IndexedStack].
class NiavShell extends StatefulWidget {
  const NiavShell({
    super.key,
    required this.title,
    this.scope,
    this.initialCompanyId,
  });

  final String title;

  /// Backend surface behind the tabs. Null until the production engine is
  /// ready (P-SQLIB): tabs render the scope gate instead of fake data.
  final CompanyScope? scope;

  /// Company selected before first build (tests, deep links). Null starts
  /// at onboarding when a scope is present.
  final CompanyId? initialCompanyId;

  @override
  State<NiavShell> createState() => NiavShellState();
}

/// Exposed for tests (selected tab/company are navigation chrome, not
/// business state).
class NiavShellState extends State<NiavShell> {
  int selectedIndex = 0;
  CompanyId? selectedCompanyId;

  @override
  void initState() {
    super.initState();
    selectedCompanyId = widget.initialCompanyId;
  }

  void selectTab(int index) {
    setState(() => selectedIndex = index);
  }

  void openCompany(CompanyId id) {
    setState(() => selectedCompanyId = id);
  }

  /// Persistent, non-alarming offline marker (UX-007): V1 stores everything
  /// on this device and syncs nothing — the badge states exactly that.
  Widget _offlineBadge() {
    return const Tooltip(
      message: 'Offline-first: saved on this device, no sync in V1.',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off, size: 18),
            SizedBox(width: 4),
            Text('Offline', key: ValueKey<String>('offline-indicator')),
          ],
        ),
      ),
    );
  }

  Widget _gate(String destination) {
    return Center(
      key: ValueKey<String>('scope-gate-$destination'),
      child: const Text(
        'Company data is unavailable until the encrypted database is ready.',
      ),
    );
  }

  Widget _tabPage(NiavDestination d, CompanyScope scope, CompanyId company) {
    switch (d) {
      case NiavDestination.home:
        return HomeDashboardScreen(
          key: const ValueKey<String>('tab-page-home'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.billing:
        return BillingHubScreen(
          key: const ValueKey<String>('tab-page-billing'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.partiesItems:
        return PartiesItemsScreen(
          key: const ValueKey<String>('tab-page-partiesItems'),
          companyId: company,
          parties: scope.parties,
          items: scope.items,
          aliases: scope.aliases,
          search: scope.search,
          write: scope.write,
        );
      case NiavDestination.reports:
        return ReportsHubScreen(
          key: const ValueKey<String>('tab-page-reports'),
          companyId: company,
          scope: scope,
        );
      case NiavDestination.more:
        return OnboardingScreen(
          key: const ValueKey<String>('tab-page-more'),
          companies: scope.companies,
          write: scope.write,
          onOpen: openCompany,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NiavDestination> destinations = NiavDestination.values;
    final CompanyScope? scope = widget.scope;
    final CompanyId? company = selectedCompanyId;
    if (scope == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[_offlineBadge()],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: <Widget>[
            for (final NiavDestination d in destinations) _gate(d.name),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: selectTab,
          items: <BottomNavigationBarItem>[
            for (final NiavDestination d in destinations)
              BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }
    if (company == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[_offlineBadge()],
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
        actions: <Widget>[_offlineBadge()],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          for (final NiavDestination d in destinations)
            _tabPage(d, scope, company),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: selectTab,
        items: <BottomNavigationBarItem>[
          for (final NiavDestination d in destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
