import 'package:flutter/material.dart';

import 'signup_view.dart';

/// Compatibility wrapper for the old patient registration screen.
///
/// Patient registration is implemented once in [SignupView] and maps directly
/// to the patient-only backend registration contract.
class PatientSignupView extends StatelessWidget {
  const PatientSignupView({super.key});

  @override
  Widget build(BuildContext context) => const SignupView();
}
