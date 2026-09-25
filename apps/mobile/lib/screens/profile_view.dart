import 'package:flutter/material.dart';

import 'account_view.dart';

/// Compatibility view for older doctor navigation.
///
/// The canonical profile implementation is [AccountView].
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => const AccountView(embedded: true);
}
