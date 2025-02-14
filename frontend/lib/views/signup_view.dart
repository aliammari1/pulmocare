import 'package:flutter/material.dart';
import 'package:medicare/views/map_selection_dialog.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'visit_card_scan_view.dart'; // Import the new VisitCardScanView
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/location_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _initialCountryCode;
  bool _isCountryCodeLoading = true;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions
    _loadCountryCode();
  }

  Future<void> _requestPermissions() async {
    // Request location permission
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.location.request();
    }

    // Request camera permission
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      await Permission.camera.request();
    }
  }

  Future<void> _loadCountryCode() async {
    try {
      setState(() => _isCountryCodeLoading = true);
      final countryCode = await _locationService.getCurrentCountryCode();

      setState(() {
        _initialCountryCode = countryCode;
        _isCountryCodeLoading = false;
      });
      print('Detected Country Code: $_initialCountryCode');
    } catch (e) {
      print('Error detecting country code: $e');
      setState(() => _isCountryCodeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Please fill in the details below',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
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
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Navigate to VisitCardScanView and await the result
                            final visitCardData = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => VisitCardScanView()),
                            );

                            // If data is returned from VisitCardScanView, populate the fields
                            if (visitCardData != null) {
                              setState(() {
                                _nameController.text =
                                    visitCardData['name'] ?? '';
                                _specialtyController.text =
                                    visitCardData['specialty'] ?? '';
                                _emailController.text =
                                    visitCardData['email'] ?? '';
                                _phoneController.text =
                                    visitCardData['phone_number'] ?? '';
                                _addressController.text =
                                    visitCardData['address'] ?? '';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF35C5CF),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('Scan Visit Card',
                              style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            _nameController, 'Full Name', Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField(_emailController, 'Email', Icons.email),
                        const SizedBox(height: 16),
                        _buildTextField(
                            _passwordController, 'Password', Icons.lock,
                            isPassword: true),
                        const SizedBox(height: 16),
                        _buildTextField(_specialtyController, 'Specialty',
                            Icons.medical_services),
                        const SizedBox(height: 16),
                        _buildPhoneField(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _addressController,
                          'Address',
                          Icons.location_on,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () async {
                              final selectedAddress = await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  return MapSelectionDialog(
                                      initialAddress: _addressController.text);
                                },
                              );
                              if (selectedAddress != null) {
                                setState(() =>
                                    _addressController.text = selectedAddress);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  await context.read<AuthViewModel>().signup(
                                        _nameController.text,
                                        _emailController.text,
                                        _passwordController.text,
                                        _specialtyController.text,
                                        _phoneController.text,
                                        _addressController.text,
                                      );
                                  setState(() => _isLoading = false);
                                  if (context
                                      .read<AuthViewModel>()
                                      .isAuthenticated) {
                                    Navigator.pushReplacementNamed(
                                        context, '/home');
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
                              : Text('Sign Up', style: TextStyle(fontSize: 16)),
                        ),
                      ],
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
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, Widget? prefix, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix == null
            ? Icon(icon, color: Color(0xFF81C9F3))
            : null, // Only show the default icon if there's no prefix
        prefix: prefix, // Use the custom prefix widget
        suffixIcon: suffixIcon, // Use the custom suffix widget
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPhoneField() {
    if (_isCountryCodeLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return IntlPhoneField(
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(),
      ),
      initialCountryCode: _initialCountryCode ?? 'US', // Fallback to US
      onChanged: (phone) {
        _phoneController.text = phone.completeNumber;
      },
    );
  }
}
