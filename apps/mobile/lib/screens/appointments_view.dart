import 'package:flutter/material.dart';

import 'AppointmentsScreen.dart';

/// Compatibility wrapper for older navigation code.
class AppointmentsView extends StatelessWidget {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) => const AppointmentsScreen();
}
