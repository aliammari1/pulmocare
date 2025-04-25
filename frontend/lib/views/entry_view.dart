import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_view.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class EntryView extends StatefulWidget {
  const EntryView({super.key});

  @override
  _EntryViewState createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> {
  final PageController _pageController = PageController();
  int _current = 0;

  // Carousel slides data with translation keys
  final List<Map<String, String>> _slides = [
    {
      'title': 'healthcare_made_simple',
      'subtitle': 'connecting_patients_doctors',
      'description': 'manage_your_health',
    },
    {
      'title': 'control_your_practice',
      'subtitle': 'manage_appointments',
      'description': 'ai_powered_tools',
    },
    {
      'title': 'secure_communication',
      'subtitle': 'end_to_end_encryption',
      'description': 'share_medical_records',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.paleBlue,
                  AppTheme.turquoise,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(Icons.medical_services,
                      size: 60, color: AppTheme.turquoise),
                ),

                const SizedBox(height: 24),

                // App Name
                Text(
                  context.tr('welcome_to_pulmocare'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // App Description
                Text(
                  context.tr('healthcare_platform'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 1),

                // Carousel
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _current = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr(slide['title']!),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.turquoise,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr(slide['subtitle']!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(slide['description']!),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('slide_to_continue'),
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Carousel Indicators
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _slides.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        width: 12.0,
                        height: 12.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.white)
                              .withOpacity(_current == entry.key ? 0.9 : 0.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(flex: 1),

                // Action Buttons
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoginView(userType: "doctor"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.turquoise,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          context.tr('doctor_login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoginView(userType: "patient"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          context.tr('patient_login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text(
                    context.tr('continue_as_guest'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
