import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';

class VerificationAlert extends StatelessWidget {
  const VerificationAlert({super.key, required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final details = auth.currentDoctor?.verificationDetails;
    final status = details?['status']?.toString().toLowerCase();

    if (isVerified) {
      return _VerificationCard(
        icon: Icons.verified_rounded,
        title: 'Professional account verified',
        message:
            'Your clinical credentials have been reviewed and approved by PulmoCare administration.',
        tone: Colors.green,
      );
    }

    if (status == 'pending') {
      return _VerificationCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Verification under review',
        message:
            'Your credential document was submitted successfully. An administrator still needs to review it.',
        tone: Colors.orange,
        action: TextButton.icon(
          onPressed: auth.isBusy ? null : () => _pickAndSubmit(context),
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Replace document'),
        ),
      );
    }

    final rejected = status == 'rejected';
    return _VerificationCard(
      icon: rejected
          ? Icons.report_gmailerrorred_rounded
          : Icons.verified_user_outlined,
      title: rejected
          ? 'Verification needs attention'
          : 'Verify your professional account',
      message: rejected
          ? 'Your previous submission was not approved. Upload a clear photo of your medical diploma or professional license to submit it again.'
          : 'Upload a clear photo of your medical diploma or professional license. Verification is completed only after administrator review.',
      tone: rejected ? Theme.of(context).colorScheme.error : AppTheme.primary,
      action: FilledButton.icon(
        onPressed: auth.isBusy ? null : () => _pickAndSubmit(context),
        icon: auth.isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(rejected ? 'Submit another document' : 'Upload document'),
      ),
    );
  }

  Future<void> _pickAndSubmit(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (image == null || !context.mounted) return;

    final auth = context.read<AuthViewModel>();
    final ok = await auth.submitVerificationDocument(
      filePath: image.path,
      filename: image.name,
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Verification document submitted for review.'
              : auth.errorMessage,
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: action!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
