import 'package:flutter/material.dart';

import 'home_view.dart';

/// Compatibility wrapper for the legacy report dashboard.
///
/// The active application uses [HomeView] so there is a single source of truth
/// for navigation, authentication-aware actions and clinical data.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeView();
}
