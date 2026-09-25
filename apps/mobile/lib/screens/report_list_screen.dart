import 'package:flutter/material.dart';

import 'reports/reports_list_screen.dart';

/// Backwards-compatible entry point for the previous report list route.
///
/// The application now has one report list implementation backed by the
/// reports API. Keeping this wrapper avoids duplicate/demo data flows.
class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context) => const ReportsListScreen();
}
