import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/verification_alert.dart';
import 'signature_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        final doctor = auth.currentDoctor;
        final name = auth.displayName ?? auth.userEmail ?? 'PulmoCare user';
        final role = auth.userRole ?? 'user';
        final provider =
            role == 'doctor' || role == 'radiologist' || role == 'admin';
        final avatar = _decodeImage(doctor?.profileImage);

        return RefreshIndicator(
          onRefresh: auth.fetchProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _ProfileHeader(
                name: name,
                email: auth.userEmail ?? '',
                role: role,
                imageBytes: avatar,
                verified: doctor?.isVerified ?? false,
              ),
              const SizedBox(height: 18),
              if (provider && role != 'admin')
                VerificationAlert(isVerified: doctor?.isVerified ?? false),
              if (provider && role != 'admin') const SizedBox(height: 8),
              Text(
                'Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: auth.userEmail ?? 'Not available',
                  ),
                  if (provider)
                    _InfoRow(
                      icon: Icons.medical_services_outlined,
                      label: 'Specialty',
                      value: _valueOrFallback(
                        doctor?.specialty,
                        'Not specified',
                      ),
                    ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _valueOrFallback(
                      doctor?.phoneNumber,
                      'Not specified',
                    ),
                  ),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: _valueOrFallback(
                      doctor?.address,
                      'Not specified',
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Account & security',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Update your name and contact information.',
                onTap: () => _showEditProfile(context, auth),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                subtitle: 'Confirm your current password before replacing it.',
                onTap: () => _showChangePassword(context, auth),
              ),
              if (provider) ...[
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.draw_outlined,
                  title: doctor?.signature?.isNotEmpty == true
                      ? 'Update signature'
                      : 'Add signature',
                  subtitle:
                      'Manage the signature used in your clinical reporting workflow.',
                  onTap: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: SignatureView(
                            existingSignature: doctor?.signature,
                          ),
                        ),
                      ),
                    );
                    if (context.mounted) {
                      await auth.fetchProfile();
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'End this session on this device.',
                destructive: true,
                onTap: () => _confirmLogout(context, auth),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Account')), body: body);
  }

  static Uint8List? _decodeImage(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) return null;
    try {
      final payload = encoded.contains(',')
          ? encoded.substring(encoded.indexOf(',') + 1)
          : encoded;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  static String _valueOrFallback(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> _showEditProfile(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final profile = auth.currentDoctor;
    final provider = auth.userRole == 'doctor' ||
        auth.userRole == 'radiologist' ||
        auth.userRole == 'admin';
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(
      text: profile?.name ?? auth.displayName ?? '',
    );
    final specialty = TextEditingController(text: profile?.specialty ?? '');
    final phone = TextEditingController(text: profile?.phoneNumber ?? '');
    final address = TextEditingController(text: profile?.address ?? '');
    XFile? selectedImage;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit profile'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          (value?.trim().length ?? 0) < 2
                              ? 'Enter your full name'
                              : null,
                    ),
                    if (provider) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: specialty,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                          prefixIcon:
                              Icon(Icons.medical_services_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: address,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: auth.isBusy
                          ? null
                          : () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 82,
                                maxWidth: 1200,
                              );
                              if (image != null) {
                                setState(() => selectedImage = image);
                              }
                            },
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        selectedImage == null
                            ? 'Choose profile photo'
                            : 'Photo selected',
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  auth.isBusy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      String? image;
                      if (selectedImage != null) {
                        image =
                            base64Encode(await selectedImage!.readAsBytes());
                      }
                      final ok = await auth.updateProfile(
                        name: name.text,
                        specialty: specialty.text,
                        phoneNumber: phone.text,
                        address: address.text,
                        base64Image: image,
                      );
                      if (!dialogContext.mounted) return;
                      if (ok) {
                        Navigator.pop(dialogContext);
                      } else {
                        setState(() => localError = auth.errorMessage);
                      }
                    },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    specialty.dispose();
    phone.dispose();
    address.dispose();

    if (context.mounted && auth.errorMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  }

  Future<void> _showChangePassword(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change password'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Current password'),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration:
                        const InputDecoration(labelText: 'New password'),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator: (value) => value != next.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      localError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  auth.isBusy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await auth.changePassword(
                        current.text,
                        next.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (ok) {
                        Navigator.pop(dialogContext);
                      } else {
                        setState(() => localError = auth.errorMessage);
                      }
                    },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );

    current.dispose();
    next.dispose();
    confirm.dispose();

    if (context.mounted && auth.errorMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    }
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
          'You will need to sign in again to access your PulmoCare workspace.',
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

    if (confirmed == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.imageBytes,
    required this.verified,
  });

  final String name;
  final String email;
  final String role;
  final Uint8List? imageBytes;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            backgroundImage:
                imageBytes == null ? null : MemoryImage(imageBytes!),
            child: imageBytes == null
                ? Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip(label: role.toUpperCase()),
                    if (verified)
                      const _HeaderChip(
                        label: 'VERIFIED',
                        icon: Icons.verified_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary, size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 3),
                    Text(value),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : AppTheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        onTap: onTap,
      ),
    );
  }
}
