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
        final profile = auth.currentDoctor;

        return RefreshIndicator(
          onRefresh: auth.fetchProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.10),
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
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              _RoleBadge(role: role),
                              if (profile?.isVerified == true) ...[
                                const SizedBox(height: 10),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: AppTheme.secondary,
                                    ),
                                    SizedBox(width: 6),
                                    Text('Verified clinical account'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Account details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: auth.userEmail ?? 'Not available',
                      ),
                      if ((profile?.specialty ?? '').isNotEmpty)
                        _InfoTile(
                          icon: Icons.medical_services_outlined,
                          label: 'Specialty',
                          value: profile!.specialty,
                        ),
                      if ((profile?.phoneNumber ?? '').isNotEmpty)
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: profile!.phoneNumber,
                        ),
                      if ((profile?.address ?? '').isNotEmpty)
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: profile!.address,
                        ),
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Account ID',
                        value: auth.userId ?? 'Not available',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Security & profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                              ),
                              title: const Text('Edit profile'),
                              subtitle: const Text(
                                'Update your name and contact information.',
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: auth.isBusy
                                  ? null
                                  : () => _editProfile(context, auth),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.password_outlined,
                                color: AppTheme.primary,
                              ),
                              title: const Text('Change password'),
                              subtitle: const Text(
                                'Update the password managed by PulmoCare identity.',
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: auth.isBusy
                                  ? null
                                  : () => _changePassword(context, auth),
                            ),
                          ],
                        ),
                      ),
                      if (auth.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: auth.errorMessage),
                      ],
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed:
                            auth.isBusy ? null : () => _confirmLogout(context, auth),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return content;
    return Scaffold(appBar: AppBar(title: const Text('Account')), body: content);
  }

  Future<void> _editProfile(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final profile = auth.currentDoctor;
    final nameController = TextEditingController(
      text: auth.displayName ?? profile?.name ?? '',
    );
    final phoneController =
        TextEditingController(text: profile?.phoneNumber ?? '');
    final addressController =
        TextEditingController(text: profile?.address ?? '');
    final specialtyController =
        TextEditingController(text: profile?.specialty ?? '');
    final isClinical = auth.userRole == 'doctor' ||
        auth.userRole == 'radiologist' ||
        auth.userRole == 'admin';

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                if (isClinical) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true || !context.mounted) {
      nameController.dispose();
      phoneController.dispose();
      addressController.dispose();
      specialtyController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final specialty = specialtyController.text.trim();

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    specialtyController.dispose();

    if (name.length < 2) {
      _showMessage(context, 'Enter a valid full name.');
      return;
    }

    final ok = await auth.updateProfile(
      name: name,
      phoneNumber: phone,
      address: address,
      specialty: isClinical ? specialty : null,
    );
    if (!context.mounted) return;
    _showMessage(
      context,
      ok ? 'Profile updated.' : auth.errorMessage,
      error: !ok,
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update password'),
          ),
        ],
      ),
    );

    if (submit != true || !context.mounted) {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
      return;
    }

    final current = currentController.text;
    final next = newController.text;
    final confirm = confirmController.text;

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (current.length < 8 || next.length < 8) {
      _showMessage(context, 'Passwords must contain at least 8 characters.');
      return;
    }
    if (next != confirm) {
      _showMessage(context, 'The new passwords do not match.');
      return;
    }

    final ok = await auth.changePassword(current, next);
    if (!context.mounted) return;
    _showMessage(
      context,
      ok ? 'Password updated.' : auth.errorMessage,
      error: !ok,
    );
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

  void _showMessage(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    if (message.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          role.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
