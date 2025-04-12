import 'package:flutter/material.dart';
import '../views/pdf_actions_screen.dart'; // Add this import

class NavigationService {
  static Future<void> navigateToPdfActions(BuildContext context,
      {required String ordonnanceId}) async {
    try {
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PdfActionsScreen(
            ordonnanceId: ordonnanceId,
            mode: PdfActionMode.newOrdonnance,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation: $e');
      // Fallback navigation
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  static void showTransitionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TransitionDialog(),
    );
  }
}

class TransitionDialog extends StatelessWidget {
  const TransitionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Préparation de votre ordonnance...'),
          ],
        ),
      ),
    );
  }
}
