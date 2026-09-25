import 'package:flutter/material.dart';

import 'account_view.dart';

/// Settings now exposes the real authenticated account and security controls
/// instead of a placeholder screen.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => const AccountView();
}
