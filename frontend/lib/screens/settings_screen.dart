import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/report_provider.dart'; // Add this import
import '../config/env_config.dart';
import '../services/cache_service.dart';
import 'dart:async'; // Add this import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ThemeSettings(),
          _Divider(),
          _ServiceSettings(),
          _Divider(),
          _CacheSettings(),
          _Divider(),
          _AccessibilitySettings(),
          _Divider(),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceSettings extends StatefulWidget {
  const _ServiceSettings();

  @override
  State<_ServiceSettings> createState() => _ServiceSettingsState();
}

class _ServiceSettingsState extends State<_ServiceSettings> {
  late bool _serviceDiscoveryEnabled;
  Timer? _healthCheckTimer;

  @override
  void initState() {
    super.initState();
    _serviceDiscoveryEnabled = EnvConfig.enableServiceDiscovery;
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Microservices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Service Discovery'),
          subtitle: const Text('Automatically detect available services'),
          value: _serviceDiscoveryEnabled,
          onChanged: (value) {
            setState(() => _serviceDiscoveryEnabled = value);
            // TODO: Implement service discovery toggle
          },
        ),
        ListTile(
          title: Text(
            'API Gateway',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text(EnvConfig.apiGatewayUrl),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          title: Text(
            'MongoDB',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text('${EnvConfig.apiGatewayUrl}/mongodb'),
          trailing: Consumer<ReportProvider>(
            builder: (context, provider, _) => Icon(
              provider.isMongoDBConnected ? Icons.check_circle : Icons.error,
              color: provider.isMongoDBConnected ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class _CacheSettings extends StatefulWidget {
  const _CacheSettings();

  @override
  State<_CacheSettings> createState() => _CacheSettingsState();
}

class _CacheSettingsState extends State<_CacheSettings> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CacheService>(
      builder: (context, cacheService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Caching'),
              subtitle: const Text('Cache responses for faster loading'),
              value: EnvConfig.enableCaching,
              onChanged: null, // Controlled by environment
            ),
            ListTile(
              title: const Text('Cache Duration'),
              subtitle: Text('${EnvConfig.cacheMaxAge.inMinutes} minutes'),
            ),
            ListTile(
              enabled: !_isClearing,
              title: const Text('Clear Cache'),
              leading: _isClearing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onTap: () async {
                setState(() => _isClearing = true);
                try {
                  await cacheService.invalidateAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isClearing = false);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _AccessibilitySettings extends StatelessWidget {
  const _AccessibilitySettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accessibility',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: themeProvider.textScaleFactor,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label:
                  'Text Size: ${(themeProvider.textScaleFactor * 100).round()}%',
              onChanged: (value) => themeProvider.updateTextScale(value),
            ),
          ],
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Implement terms of service navigation
          },
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Implement privacy policy navigation
          },
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(),
    );
  }
}
