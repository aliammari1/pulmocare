import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../components/verification_alert.dart';
import '../localization/app_localizations.dart';
import './signature_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, child) {
          final doctor = authVM.currentDoctor;
          if (doctor == null)
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.turquoise),
            );

          final imageBytes = doctor.profileImage != null
              ? base64Decode(doctor.profileImage!)
              : null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Enhanced Profile Header with animated gradient and glassmorphism effect
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.turquoise.withOpacity(0.8),
                        AppTheme.skyBlue,
                        AppTheme.turquoise.withOpacity(0.9),
                      ],
                      stops: const [0.1, 0.5, 0.9],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.skyBlue.withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Enhanced Profile Image with animations and glow effect
                      Hero(
                        tag: 'profile-image',
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 75,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: AppTheme.lightGray,
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes)
                                  : null,
                              child: imageBytes == null
                                  ? Icon(
                                      Icons.person_outline,
                                      size: 50,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Enhanced name with animated entrance
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 3),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // Animated specialty badge
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.medical_services_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    doctor.specialty,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Verification Alert
                VerificationAlert(isVerified: doctor.isVerified),

                // Information Cards with enhanced design and animations
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Animated information cards
                      _buildAnimatedInfoCard(
                        context,
                        Icons.email_outlined,
                        context.tr('email_address'),
                        doctor.email,
                        AppTheme.turquoise,
                        0,
                      ),
                      _buildAnimatedInfoCard(
                        context,
                        Icons.phone_outlined,
                        context.tr('phone_number'),
                        doctor.phoneNumber,
                        AppTheme.skyBlue,
                        1,
                      ),
                      _buildAnimatedInfoCard(
                        context,
                        Icons.location_on_outlined,
                        context.tr('office_address'),
                        doctor.address,
                        AppTheme.turquoise,
                        2,
                      ),
                      const SizedBox(height: 30),

                      // Enhanced signature button with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutQuad,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.paleBlue,
                                    Color(0xFFE6F7FF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.skyBlue.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor:
                                      AppTheme.turquoise.withOpacity(0.1),
                                  onTap: () => doctor.signature != null
                                      ? _showSignatureDialog(
                                          context, doctor.signature!)
                                      : _showSignatureCreationDialog(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                doctor.signature != null
                                                    ? Icons.draw
                                                    : Icons.add,
                                                color: AppTheme.turquoise,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doctor.signature != null
                                                      ? context
                                                          .tr('your_signature')
                                                      : context
                                                          .tr('add_signature'),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  doctor.signature != null
                                                      ? context
                                                          .tr('View or update')
                                                      : context.tr(
                                                          'Required for prescriptions'),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.black45,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Modern Action Buttons with staggered animations
                      Row(
                        children: [
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(-30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildEnhancedActionButton(
                                      context,
                                      context.tr('change_password'),
                                      Icons.lock_outline,
                                      [
                                        AppTheme.turquoise,
                                        AppTheme.turquoise.withOpacity(0.7)
                                      ],
                                      () => _showChangePasswordDialog(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildEnhancedActionButton(
                                      context,
                                      context.tr('edit_profile'),
                                      Icons.edit_outlined,
                                      [
                                        AppTheme.skyBlue,
                                        AppTheme.skyBlue.withOpacity(0.7)
                                      ],
                                      () => _showEditProfileDialog(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedInfoCard(BuildContext context, IconData icon,
      String title, String? value, Color color, int index) {
    // Handle null or empty values with appropriate placeholder
    final displayValue =
        (value == null || value.isEmpty) ? context.tr('not_provided') : value;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Use FutureBuilder-like approach for displaying data
                        value == null
                            ? _buildLoadingText()
                            : Text(
                                displayValue,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: value.isEmpty
                                      ? Colors.grey[500]
                                      : Colors.black87,
                                ),
                              ),
                      ],
                    ),
                  ),
                  // Add edit icon for editable fields if needed
                  if (title != context.tr('email_address'))
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      splashRadius: 20,
                      onPressed: () => _showEditProfileDialog(context),
                      tooltip: context.tr('edit_info'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingText() {
    return Container(
      width: 120,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.turquoise.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButton(BuildContext context, String text,
      IconData icon, List<Color> gradientColors, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrentPass = true;
    bool obscureNewPass = true;
    bool obscureConfirmPass = true;
    String errorText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.turquoise.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.turquoise.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock, color: AppTheme.turquoise),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        context.tr('change_password'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        decoration: InputDecoration(
                          labelText: context.tr('current_password'),
                          prefixIcon: Icon(Icons.vpn_key_outlined,
                              color: AppTheme.skyBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.turquoise),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrentPass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => obscureCurrentPass = !obscureCurrentPass),
                          ),
                        ),
                        obscureText: obscureCurrentPass,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('current_password_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: newPasswordController,
                        decoration: InputDecoration(
                          labelText: context.tr('new_password'),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: AppTheme.skyBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.turquoise),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNewPass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => obscureNewPass = !obscureNewPass),
                          ),
                        ),
                        obscureText: obscureNewPass,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('new_password_required');
                          }
                          if (value.length < 6) {
                            return context.tr('password_min_length');
                          }
                          if (value == currentPasswordController.text) {
                            return context.tr('new_password_different');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: context.tr('confirm_new_password'),
                          prefixIcon: Icon(Icons.check_circle_outline,
                              color: AppTheme.skyBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.turquoise),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => obscureConfirmPass = !obscureConfirmPass),
                          ),
                        ),
                        obscureText: obscureConfirmPass,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('confirm_password_required');
                          }
                          if (value != newPasswordController.text) {
                            return context.tr('passwords_do_not_match');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (errorText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorText,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          context.tr('cancel'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              await context
                                  .read<AuthViewModel>()
                                  .changePassword(
                                    currentPasswordController.text.trim(),
                                    newPasswordController.text.trim(),
                                  );

                              final error =
                                  context.read<AuthViewModel>().errorMessage;
                              if (error.isEmpty) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(context.tr('password_updated')),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } else {
                                setState(() => errorText = error);
                              }
                            } catch (e) {
                              setState(() => errorText =
                                  context.tr('password_change_failed') +
                                      ': $e');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.turquoise,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          context.tr('change'),
                          style: const TextStyle(
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
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final _nameController =
        TextEditingController(text: authVM.currentDoctor?.name);
    final _specialtyController =
        TextEditingController(text: authVM.currentDoctor?.specialty);
    final _phoneController =
        TextEditingController(text: authVM.currentDoctor?.phoneNumber);
    final _addressController =
        TextEditingController(text: authVM.currentDoctor?.address);
    XFile? selectedImage;
    String errorText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: AppTheme.dialogDecoration,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.skyBlue),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: AppTheme.inputDecoration.copyWith(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person,
                              color: AppTheme.turquoise),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _specialtyController,
                        decoration: AppTheme.inputDecoration.copyWith(
                          labelText: 'Specialty',
                          prefixIcon: const Icon(Icons.medical_services,
                              color: AppTheme.turquoise),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: AppTheme.inputDecoration.copyWith(
                          labelText: 'Phone',
                          prefixIcon: const Icon(Icons.phone,
                              color: AppTheme.turquoise),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: AppTheme.inputDecoration.copyWith(
                          labelText: 'Address',
                          prefixIcon: const Icon(Icons.location_on,
                              color: AppTheme.turquoise),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Select Profile Image'),
                  style: AppTheme.buttonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.all(AppTheme.skyBlue),
                    minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 50)),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => selectedImage = image);
                    }
                  },
                ),
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Selected: ${selectedImage!.name}',
                      style: const TextStyle(color: AppTheme.turquoise),
                    ),
                  ),
                if (errorText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final base64Image = selectedImage != null
                                ? base64Encode(
                                    await selectedImage!.readAsBytes())
                                : null;
                            await authVM.updateProfile(
                              name: _nameController.text.trim(),
                              specialty: _specialtyController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              address: _addressController.text.trim(),
                              base64Image: base64Image,
                            );
                            if (authVM.errorMessage.isEmpty) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Profile updated')),
                              );
                            } else {
                              setState(() => errorText = authVM.errorMessage);
                            }
                          } catch (e) {
                            setState(() => errorText = 'Error: $e');
                          }
                        },
                        style: AppTheme.buttonStyle,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignatureDialog(BuildContext context, String signatureBase64) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('your_signature'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.turquoise, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(signatureBase64),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSignatureCreationDialog(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(context.tr('change')),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(context.tr('close')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignatureCreationDialog(BuildContext context) {
    final doctor = context.read<AuthViewModel>().currentDoctor;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SignatureView(existingSignature: doctor?.signature),
      ),
    );
  }
}
