import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: AppTheme.turquoise.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('settings_coming_soon'),
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.turquoise.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
