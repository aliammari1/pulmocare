import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/env_config.dart';
import '../services/cache_service.dart';

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

  @override
  void initState() {
    super.initState();
    _serviceDiscoveryEnabled = EnvConfig.enableServiceDiscovery;
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
            'X-Ray Service',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text(EnvConfig.xrayServiceUrl),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          title: Text(
            'Knowledge Service',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text(EnvConfig.knowledgeServiceUrl),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
      ],
    );
  }
}

class _CacheSettings extends StatelessWidget {
  const _CacheSettings();

  @override
  Widget build(BuildContext context) {
    final cacheService = Provider.of<CacheService>(context, listen: false);

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
          subtitle: Text('${EnvConfig.maxCacheAgeMinutes} minutes'),
        ),
        ListTile(
          title: const Text('Clear Cache'),
          leading: const Icon(Icons.delete_outline),
          onTap: () async {
            await cacheService.invalidateAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            }
          },
        ),
      ],
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
