// NiAvERP five-item navigation shell — Phase 00.
// Authoritative model (OD-UI-001 / G0-CON-005): Home, Billing,
// Parties & Items, Reports, More. Tab pages are placeholders; real screens
// land with their vertical slices (strategy §§4–5). The shell stores only the
// selected tab index. No business state lives in widgets.
// Traceability: OD-UI-001; G0-CON-005; DECISIONS.md.

import 'package:flutter/material.dart';

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
  const NiavShell({super.key, required this.title});

  final String title;

  @override
  State<NiavShell> createState() => NiavShellState();
}

/// Exposed for tests (selected tab index is navigation chrome, not business).
class NiavShellState extends State<NiavShell> {
  int selectedIndex = 0;

  void selectTab(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<NiavDestination> destinations = NiavDestination.values;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          for (final NiavDestination d in destinations)
            Center(
              key: ValueKey<String>('tab-page-${d.name}'),
              child: Text('${d.label} — coming in its vertical slice'),
            ),
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
