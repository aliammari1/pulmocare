import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _sent
                    ? Column(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            size: 56,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Check your email',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'If the address is registered, the identity provider '
                            'will send password-reset instructions.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to sign in'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Recover your account',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your account email. PulmoCare uses the '
                              'configured identity provider for password resets.',
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'Email is required';
                                if (!email.contains('@')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            if (auth.errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                auth.errorMessage,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: auth.isBusy ? null : _submit,
                              child: auth.isBusy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Send reset instructions'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context
        .read<AuthViewModel>()
        .forgotPassword(_emailController.text);
    if (!mounted || !ok) return;
    setState(() => _sent = true);
  }
}
