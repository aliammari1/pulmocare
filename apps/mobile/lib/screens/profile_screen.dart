import 'package:flutter/material.dart';

import 'account_view.dart';

/// Backwards-compatible route kept for older navigation paths.
///
/// Account management now has one implementation so profile data, session
/// handling, verification, signatures, and password changes cannot drift.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const AccountView();
}
