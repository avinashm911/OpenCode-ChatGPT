// NiAvERP application entry point — Phase 00.
// Counter scaffold replaced by the five-item shell (OD-UI-001 / G0-CON-005).
// Owns the [CompositionRoot]; no business state is created here.

import 'package:flutter/material.dart';

import 'app/composition_root.dart';
import 'app/niav_app.dart';

void main() {
  runApp(NiavApp(root: CompositionRoot.system()));
}
