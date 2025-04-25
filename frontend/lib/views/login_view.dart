import 'package:flutter/material.dart';
import 'package:medicare/theme/app_theme.dart';
import 'package:medicare/views/forgot_password_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../localization/app_localizations.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  final String userType;

  const LoginView({super.key, required this.userType});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('email_required');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return context.tr('email_invalid');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('password_required');
    }
    if (value.length < 8) {
      return context.tr('password_min_length');
    }
    return null;
  }

  void _showAlert(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient with wave pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF81C9F3),
                  Color(0xFF35C5CF),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo and App Name
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFD8EFF5).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('app_name'),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.tr('welcome_back'),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF35C5CF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('sign_in_as') +
                                ' ' +
                                widget.userType.capitalize(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            decoration: AppTheme.inputDecoration.copyWith(
                              labelText: context.tr('email'),
                              prefixIcon:
                                  Icon(Icons.email, color: Color(0xFF81C9F3)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: true,
                            decoration: AppTheme.inputDecoration.copyWith(
                              labelText: context.tr('password'),
                              prefixIcon:
                                  Icon(Icons.lock, color: Color(0xFF81C9F3)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordView()),
                              ),
                              child: Text(
                                context.tr('forgot_password'),
                                style: TextStyle(color: Color(0xFF81C9F3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);
                                      try {
                                        await context
                                            .read<AuthViewModel>()
                                            .login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                        if (context
                                            .read<AuthViewModel>()
                                            .isAuthenticated) {
                                          _showAlert('Success',
                                              'Login successful!', true);
                                          Navigator.pushReplacementNamed(
                                              context, '/home');
                                        }
                                      } catch (e) {
                                        _showAlert(
                                            'Error', e.toString(), false);
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF35C5CF),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.tr('login'),
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Create Account Button
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupView()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: context.tr('dont_have_account') + ' ',
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: context.tr('create_account'),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Error Message
                    Consumer<AuthViewModel>(
                      builder: (context, authVM, child) {
                        return authVM.errorMessage.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  authVM.errorMessage,
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
