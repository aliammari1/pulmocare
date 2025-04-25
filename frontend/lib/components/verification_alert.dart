import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_view_model.dart';
import '../localization/app_localizations.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class VerificationAlert extends StatefulWidget {
  final bool isVerified;

  const VerificationAlert({Key? key, required this.isVerified})
      : super(key: key);

  @override
  _VerificationAlertState createState() => _VerificationAlertState();
}

class _VerificationAlertState extends State<VerificationAlert>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  String? _selectedLanguage;
  String? _errorMessage;
  String? _detectedLanguage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVerified) {
      return FadeTransition(
        opacity: _animation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.verified, color: Colors.green, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Account verified'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context
                          .tr('Your medical credentials have been validated'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return FadeTransition(
        opacity: _animation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.amber.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade700, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      context
                          .tr('Account not verified please scan your diploma'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('Verification required'),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    letterSpacing: 0.3,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Verification Failed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          height: 1.4,
                        ),
                      ),
                      if (_detectedLanguage != null &&
                          _selectedLanguage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.sync),
                            label: Text(
                                'Try with ${_detectedLanguage!.capitalize()} instead'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade800,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _selectedLanguage =
                                    _detectedLanguage!.toLowerCase();
                                _detectedLanguage = null;
                              });
                              _showImagePickerForLanguage(_selectedLanguage!);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.verified_user, size: 22),
                  label: Text(
                    _isUploading
                        ? context.tr('uploading')
                        : context.tr('verify now'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.turquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppTheme.turquoise.withOpacity(0.5),
                  ),
                  onPressed: _isUploading
                      ? null
                      : () => _showVerificationOptions(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showVerificationOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Select diploma language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('Select language for verification'),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(ctx, 'english', 'English', Icons.language),
            _buildLanguageOption(
                ctx, 'russian', 'Russian (Русский)', Icons.language),
            _buildLanguageOption(
                ctx, 'arabic', 'Arabic (العربية)', Icons.language),
            _buildLanguageOption(
                ctx, 'french', 'French (Français)', Icons.language),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, String value, String label, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.paleBlue,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          setState(() {
            _selectedLanguage = value;
            _errorMessage = null;
            _detectedLanguage = null;
          });
          _showImagePickerForLanguage(value);
        },
      ),
    );
  }

  void _showImagePickerForLanguage(String language) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _startVerificationProcess(image, language);
    }
  }

  void _startVerificationProcess(XFile image, String language) async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _detectedLanguage = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await context.read<AuthViewModel>().verifyDoctor(
            base64Image,
            language,
          );

      // Check for language mismatch
      String error = context.read<AuthViewModel>().errorMessage;
      if (error.contains("Language mismatch")) {
        // Extract detected language from error message
        RegExp regex = RegExp(r'in (\w+)\.');
        Match? match = regex.firstMatch(error);
        if (match != null && match.groupCount >= 1) {
          _detectedLanguage = match.group(1);
        }
        _errorMessage = error;
      } else if (!result) {
        _errorMessage =
            error.isNotEmpty ? error : context.tr('Verification failed');
      }

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Verification successful')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${context.tr('Verification error')}: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
