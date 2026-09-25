import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create patient account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Patient registration',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Clinical staff accounts are provisioned by an '
                        'administrator. Self-registration creates a patient '
                        'account only.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 2
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
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
                        validator: (value) => (value?.length ?? 0) < 8
                            ? 'Use at least 8 characters'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _address,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address (optional)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create account'),
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

    final ok = await context.read<AuthViewModel>().signupPatient(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text.isEmpty ? null : _phone.text,
          address: _address.text.isEmpty ? null : _address.text,
        );

    if (!mounted || !ok) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }
}
