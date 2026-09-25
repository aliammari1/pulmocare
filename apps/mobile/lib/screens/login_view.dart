import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';
import 'forgot_password_view.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.userType});

  final String userType;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String get _roleLabel =>
      '${widget.userType[0].toUpperCase()}${widget.userType.substring(1)}';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_outlined,
                                color: AppTheme.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to your $_roleLabel workspace.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: auth.isBusy
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordView(),
                                          ),
                                        ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            if (auth.errorMessage.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  auth.errorMessage,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            FilledButton(
                              onPressed: auth.isBusy ? null : _submit,
                              child: auth.isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                            if (widget.userType == 'patient') ...[
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('New to PulmoCare?'),
                                  TextButton(
                                    onPressed: auth.isBusy
                                        ? null
                                        : () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignupView(),
                                              ),
                                            ),
                                    child: const Text('Create account'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

    final ok = await context.read<AuthViewModel>().login(
          _emailController.text,
          _passwordController.text,
          expectedRole: widget.userType,
        );

    if (!mounted || !ok) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }
}
