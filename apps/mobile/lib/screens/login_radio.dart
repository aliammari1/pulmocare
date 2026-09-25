import 'package:flutter/material.dart';

import 'login_view.dart';

/// Legacy radiologist sign-in entry point.
class LoginRadioView extends StatelessWidget {
  const LoginRadioView({super.key});

  @override
  Widget build(BuildContext context) =>
      const LoginView(userType: 'radiologist');
}
