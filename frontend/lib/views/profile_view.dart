import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        final doctor = authVM.currentDoctor;
        if (doctor == null)
          return const Center(child: CircularProgressIndicator());

        final imageBytes = doctor.profileImage != null
            ? base64Decode(doctor.profileImage!)
            : null;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Modern Profile Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF81C9F3),
                      Color(0xFF35C5CF),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Color(0xFFEDEDF1),
                            backgroundImage: imageBytes != null
                                ? MemoryImage(imageBytes)
                                : null,
                          ),
                          if (imageBytes == null)
                            Text(
                              doctor.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF35C5CF),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      doctor.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      doctor.specialty,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              // Information Cards
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildModernInfoCard(
                      Icons.email_outlined,
                      'Email Address',
                      doctor.email,
                      Color(0xFF81C9F3),
                    ),
                    _buildModernInfoCard(
                      Icons.phone_outlined,
                      'Phone Number',
                      doctor.phoneNumber,
                      Color(0xFF35C5CF),
                    ),
                    _buildModernInfoCard(
                      Icons.location_on_outlined,
                      'Office Address',
                      doctor.address,
                      Color(0xFF81C9F3),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Change Password',
                            Icons.lock_outline,
                            Color(0xFF35C5CF),
                            () => _showChangePasswordDialog(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            'Edit Profile',
                            Icons.edit_outlined,
                            Color(0xFF81C9F3),
                            () => _showEditProfileDialog(context),
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
    );
  }

  Widget _buildModernInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
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
              color: Color(0xFFD8EFF5),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String errorText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setState(() => errorText = 'New passwords do not match');
                  return;
                }
                await context.read<AuthViewModel>().changePassword(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                    );
                final error = context.read<AuthViewModel>().errorMessage;
                if (error.isEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password updated successfully')),
                  );
                } else {
                  setState(() => errorText = error);
                }
              },
              child: const Text('Change'),
            ),
          ],
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
                    backgroundColor:
                        MaterialStateProperty.all(AppTheme.skyBlue),
                    minimumSize: MaterialStateProperty.all(
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
}
