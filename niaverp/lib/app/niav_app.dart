// NiAvERP application root widget — Phase 00.
// Owns the [CompositionRoot] and hosts the five-item shell. Holds no
// business state; the shell keeps only the selected tab index (navigation
// chrome), never voucher/stock/accounting data.
// Traceability: OD-UI-001 / G0-CON-005 (five-item model).

import 'package:flutter/material.dart';

import 'composition_root.dart';
import '../presentation/shell/niav_shell.dart';

/// Application root. Created once by `main()` with its [root].
class NiavApp extends StatelessWidget {
  const NiavApp({super.key, required this.root});

  final CompositionRoot root;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: root.config.appTitle,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.indigo),
      ),
      home: NiavShell(title: root.config.appTitle),
    );
  }
}
