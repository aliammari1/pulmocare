import 'package:flutter/material.dart';
import '../theme/style_constants.dart'; // Update this import

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({Key? key, this.size = 60}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: StyleConstants.primaryColor.withOpacity(0.1),
      ),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
