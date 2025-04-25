import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../viewmodels/auth_view_model.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../models/app_language.dart';
import '../localization/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.paleBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppTheme.turquoise,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('logout'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('logout_confirmation'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              context.tr('cancel'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.turquoise,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              context.tr('logout'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 280, // Increased height to accommodate more info
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppTheme.paleBlue, AppTheme.turquoise],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            authViewModel.currentDoctor?.profileImage != null
                                ? MemoryImage(base64Decode(
                                    authViewModel.currentDoctor!.profileImage!))
                                : null,
                        child: authViewModel.currentDoctor?.profileImage == null
                            ? const Icon(Icons.person,
                                size: 45, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Dr. ${authViewModel.currentDoctor?.name ?? "Name"}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        authViewModel.currentDoctor?.specialty ?? "Specialty",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Updated Settings Section with Multiple Settings
          ExpansionTile(
            leading: Icon(Icons.settings, color: AppTheme.turquoise),
            title: Text(
              context.tr('settings'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              // Theme Mode Setting
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 36.0),
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.turquoise,
                ),
                title: Text(context.tr('dark_mode')),
                trailing: Switch(
                  activeColor: AppTheme.turquoise,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),

              // Language Setting
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 36.0),
                leading: const Icon(Icons.language, color: AppTheme.turquoise),
                title: Text(context.tr('language')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        _buildLanguageSelectionDialog(context),
                  );
                },
              ),

              // Privacy
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 36.0),
                leading: const Icon(Icons.security_outlined,
                    color: AppTheme.turquoise),
                title: Text(context.tr('privacy')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to privacy settings
                  showDialog(
                    context: context,
                    builder: (context) => _buildPrivacyDialog(context),
                  );
                },
              ),

              // Help & Support
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 36.0),
                leading:
                    const Icon(Icons.help_outline, color: AppTheme.turquoise),
                title: Text(context.tr('help_support')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildHelpDialog(context),
                  );
                },
              ),

              // About
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 36.0),
                leading:
                    const Icon(Icons.info_outline, color: AppTheme.turquoise),
                title: Text(context.tr('about')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildAboutDialog(context),
                  );
                },
              ),
            ],
          ),

          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.kErrorRed),
            title: Text(
              context.tr('logout'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              if (await _showLogoutConfirmation(context)) {
                await authViewModel.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/entry');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // New method for language selection dialog
  Widget _buildLanguageSelectionDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('select_language'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.turquoise,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildLanguageOption(
              context,
              AppLanguages.english,
              AppLanguages.english.nativeName,
            ),
            _buildLanguageOption(
              context,
              AppLanguages.french,
              AppLanguages.french.nativeName,
            ),
            _buildLanguageOption(
              context,
              AppLanguages.arabic,
              AppLanguages.arabic.nativeName,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build language option
  Widget _buildLanguageOption(
      BuildContext context, AppLanguage language, String displayName) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSelected = languageProvider.currentLanguage.code == language.code;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.turquoise.withOpacity(0.2)
              : AppTheme.paleBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          language.code.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.turquoise : Colors.grey,
          ),
        ),
      ),
      title: Text(displayName),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.turquoise)
          : null,
      onTap: () {
        languageProvider.changeLanguage(language);
        Navigator.pop(context);
      },
    );
  }

  // Dialog for Privacy
  Widget _buildPrivacyDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            _buildPrivacyTile(
              'Privacy Policy',
              Icons.policy_outlined,
              () => _showPrivacyPolicyDialog(context),
            ),
            _buildPrivacyTile(
              'Terms of Service',
              Icons.description_outlined,
              () => _showTermsOfServiceDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for Help & Support
  Widget _buildHelpDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            _buildHelpTile('Contact Support', Icons.support_agent_outlined,
                () => _showContactSupportDialog(context)),
            _buildHelpTile('User Guide', Icons.menu_book_outlined,
                () => _showUserGuideDialog(context)),
            const Divider(),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for About
  Widget _buildAboutDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'About Pulmocare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.paleBlue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.medical_services,
                  size: 40,
                  color: AppTheme.turquoise,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pulmocare',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pulmocare is a healthcare platform designed to connect doctors with patients seamlessly. Our mission is to improve healthcare access and quality through technology.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.language, () {}),
                _buildSocialButton(Icons.mail_outline, () {}),
                _buildSocialButton(Icons.facebook, () {}),
                _buildSocialButton(Icons.webhook, () {}),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '© 2025 Pulmocare. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build switch tiles
  Widget _buildSwitchTile(String title, String subtitle, bool initialValue) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = initialValue;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: isEnabled,
          activeColor: AppTheme.turquoise,
          onChanged: (value) {
            setState(() {
              isEnabled = value;
            });
          },
        );
      },
    );
  }

  // Helper method to build privacy tiles
  Widget _buildPrivacyTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.paleBlue.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.turquoise),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  // Helper method to build help tiles
  Widget _buildHelpTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.paleBlue.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.turquoise),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  // Helper method to build social media buttons
  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.turquoise),
        onPressed: onTap,
      ),
    );
  }

  // Helper method to show Privacy Policy dialog
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Last Updated: May 15, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'At Pulmocare, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '1. INFORMATION WE COLLECT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We may collect personal information that you provide directly to us, such as your name, address, email address, phone number, date of birth, medical history, prescription information, insurance details, and payment information. We may also collect information about your interactions with our platform.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. HOW WE USE YOUR INFORMATION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We use the information we collect to provide, maintain, and improve our services, process your requests and transactions, communicate with you, and comply with legal obligations.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. DATA SECURITY',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We implement appropriate security measures to protect your information from unauthorized access, alteration, disclosure, or destruction. These measures include encryption, secure data storage, and regular security reviews.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '4. DATA RETENTION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We retain your information for as long as necessary to fulfill the purposes for which it was collected, to comply with legal obligations, resolve disputes, and enforce our agreements.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '5. YOUR RIGHTS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You have the right to access, correct, or delete your personal information. You may also object to or restrict certain processing of your information or request a copy of your information in a structured, commonly used format.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '6. CONTACT US',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'If you have any questions about this Privacy Policy, please contact us at privacy@pulmocare.com.',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to show Terms of Service dialog
  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Last Updated: May 15, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Please read these Terms of Service carefully before using the Pulmocare platform. By accessing or using Pulmocare, you agree to be bound by these Terms.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '1. ACCEPTANCE OF TERMS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'By accessing or using our platform, you agree to these Terms of Service. If you do not agree with any part of these Terms, you may not use our platform.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. USE OF SERVICES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You agree to use our platform only for lawful purposes and in accordance with these Terms. You are responsible for maintaining the confidentiality of your account information.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. MEDICAL DISCLAIMER',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Pulmocare is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '4. USER CONTENT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You retain all rights to any content you submit, post, or display on or through our platform. By providing content, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and display your content.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '5. TERMINATION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We may terminate or suspend your account and access to our platform at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '6. LIMITATION OF LIABILITY',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'To the maximum extent permitted by law, Pulmocare shall not be liable for any indirect, incidental, special, consequential, or punitive damages, resulting from your use of or inability to use our platform.',
                          style: TextStyle(height: 1.5),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '7. CHANGES TO TERMS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We may revise these Terms from time to time. The most current version will always be posted on our platform. By continuing to use Pulmocare after changes become effective, you agree to be bound by the revised Terms.',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to show Contact Support dialog
  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.paleBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.paleBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.email_outlined,
                                color: AppTheme.turquoise),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'support@pulmocare.com',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.paleBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.paleBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.phone_outlined,
                                color: AppTheme.turquoise),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '+1 (800) 123-4567',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Monday-Friday, 9:00 AM - 5:00 PM ET',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.paleBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.paleBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_outlined,
                                color: AppTheme.turquoise),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Chat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Available 24/7 in the Pulmocare App',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.turquoise,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Handle submission of support ticket
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Submit a Support Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to show User Guide dialog
  void _showUserGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Guide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuideSection(
                          'Getting Started',
                          'Welcome to Pulmocare! This guide will help you navigate the app and make the most of its features.',
                          Icons.play_circle_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Dashboard',
                          'The dashboard provides an overview of your daily activities, appointments, and patient statistics. Tap on any card to view more details.',
                          Icons.dashboard_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Patient Management',
                          'Access your patient list by tapping the "Patients" icon in the bottom navigation bar. From there, you can view patient profiles, medical histories, and add notes.',
                          Icons.people_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Appointments',
                          'Manage your appointments by tapping the "Calendar" icon. You can create, reschedule, or cancel appointments. Set reminders and view upcoming consultations.',
                          Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Messaging',
                          'Communicate with patients securely through the messaging feature. Access it via the "Messages" icon. You can share documents, images, and send reminders.',
                          Icons.message_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Prescriptions',
                          'Create and manage prescriptions digitally. Select a patient, add medications with dosage instructions, and send them directly to the patient or pharmacy.',
                          Icons.medical_services_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Reports',
                          'Generate custom reports on patient visits, conditions, treatments, and more. Export data in various formats for analysis or record-keeping.',
                          Icons.bar_chart_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildGuideSection(
                          'Settings',
                          'Customize your Pulmocare experience through the Settings menu. Set notification preferences, update your profile, and manage security options.',
                          Icons.settings_outlined,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Need additional help? Contact our support team at support@pulmocare.com',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build guide sections
  Widget _buildGuideSection(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.paleBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.turquoise),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
