import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        final name = auth.displayName ?? auth.userEmail ?? 'PulmoCare user';
        final role = auth.userRole ?? 'user';

        return RefreshIndicator(
          onRefresh: auth.fetchProfile,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                role.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: auth.userEmail ?? 'Not available',
              ),
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'Account ID',
                value: auth.userId ?? 'Not available',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, auth),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return content;
    return Scaffold(appBar: AppBar(title: const Text('Account')), body: content);
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access clinical data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
