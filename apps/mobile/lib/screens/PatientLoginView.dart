import 'package:flutter/material.dart';

import 'login_view.dart';

/// Legacy patient sign-in entry point.
class PatientLoginView extends StatelessWidget {
  const PatientLoginView({super.key});

  @override
  Widget build(BuildContext context) => const LoginView(userType: 'patient');
}
