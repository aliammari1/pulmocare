import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  _ForgotPasswordViewState createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_otpSent) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await context
                      .read<AuthViewModel>()
                      .forgotPassword(_emailController.text);
                  setState(() => _otpSent = true);
                },
                child: const Text('Send OTP'),
              ),
            ],
            if (_otpSent && !_otpVerified) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await context.read<AuthViewModel>().verifyOTP(
                        _emailController.text,
                        _otpController.text,
                      );
                  setState(() => _otpVerified = true);
                },
                child: const Text('Verify OTP'),
              ),
            ],
            if (_otpVerified) ...[
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await context.read<AuthViewModel>().resetPassword(
                        _emailController.text,
                        _otpController.text,
                        _newPasswordController.text,
                      );
                  Navigator.pop(context);
                },
                child: const Text('Reset Password'),
              ),
            ],
            Consumer<AuthViewModel>(
              builder: (context, authVM, child) {
                return authVM.errorMessage.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          authVM.errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
