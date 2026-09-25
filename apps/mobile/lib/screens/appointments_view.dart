import 'package:flutter/material.dart';

import 'appointments_screen.dart';

/// Compatibility wrapper for older navigation code.
class AppointmentsView extends StatelessWidget {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) => const AppointmentsScreen();
}
