import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  _ForgotPasswordViewState createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  String _email = '';

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _email = _emailController.text;
      });

      try {
        await context.read<AuthViewModel>().forgotPassword(_email);
        if (!mounted) return;

        if (context.read<AuthViewModel>().errorMessage.isEmpty) {
          setState(() {
            _currentStep = 1;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar(context.read<AuthViewModel>().errorMessage);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(e.toString());
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showErrorSnackbar(context.tr('enter_verification_code'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isVerified = await context
          .read<AuthViewModel>()
          .verifyOTP(_email, _otpController.text);

      if (!mounted) return;

      if (isVerified) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackbar(context.read<AuthViewModel>().errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final isReset = await context.read<AuthViewModel>().resetPassword(
            _email, _otpController.text, _passwordController.text);

        if (!mounted) return;

        if (isReset) {
          setState(() {
            _currentStep = 3;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar(context.read<AuthViewModel>().errorMessage);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(e.toString());
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('confirm_password_required');
    }
    if (value != _passwordController.text) {
      return context.tr('passwords_must_match');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('forgot_password_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOTPStep();
      case 2:
        return _buildResetPasswordStep();
      case 3:
        return _buildSuccessStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.turquoise,
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('forgot_password_title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('forgot_password_subtitle'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: context.tr('email'),
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.turquoise,
              disabledBackgroundColor: AppTheme.turquoise.withOpacity(0.6),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(context.tr('send_code')),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('back_to_login')),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.message,
          size: 80,
          color: AppTheme.turquoise,
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('enter_verification_code'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('code_sent') + ' ($_email)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: context.tr('enter_verification_code'),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 10),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.turquoise,
            disabledBackgroundColor: AppTheme.turquoise.withOpacity(0.6),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(context.tr('verify_code')),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('didnt_receive_code')),
            TextButton(
              onPressed: _isLoading ? null : _sendOTP,
              child: Text(context.tr('resend_code')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock,
            size: 80,
            color: AppTheme.turquoise,
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('reset_password'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('enter_new_password'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: context.tr('new_password'),
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: context.tr('confirm_password'),
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('password_requirements'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.turquoise,
              disabledBackgroundColor: AppTheme.turquoise.withOpacity(0.6),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(context.tr('reset_password')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('password_reset_success'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.turquoise,
          ),
          child: Text(context.tr('back_to_login')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
