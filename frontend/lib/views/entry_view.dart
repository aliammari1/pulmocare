import 'package:flutter/material.dart';
import 'package:medicare/theme/app_theme.dart';
import 'login_view.dart';

class EntryView extends StatelessWidget {
  const EntryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF81C9F3), Color(0xFF35C5CF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Medicare',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              _buildLoginButton(
                context,
                'Sign in as Doctor',
                Icons.medical_information,
                'doctor',
              ),
              const SizedBox(height: 16),
              _buildLoginButton(
                context,
                'Sign in as Radiologist',
                Icons.mediation,
                'radiologist',
              ),
              const SizedBox(height: 16),
              _buildLoginButton(
                context,
                'Sign in as Patient',
                Icons.person,
                'patient',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
      BuildContext context, String text, IconData icon, String userType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton(
        onPressed: () {
          if (userType == 'doctor') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginView(userType: userType),
              ),
            );
          } else {
            // Show "Coming Soon" message for radiologist and patient
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Coming Soon'),
                content: Text(
                    '${userType.capitalize()} login is not yet available.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: userType == 'doctor'
              ? Colors.white
              : Colors.white.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.turquoise),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.turquoise,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
