import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

// This wrapper helps to quickly translate existing widgets
// Just wrap your Text widgets with tr() function
class TranslationHelper {
  static Widget tr(BuildContext context, String text, {TextStyle? style}) {
    return Text(context.tr(text), style: style);
  }

  // For ElevatedButton.child and similar use cases
  static Widget trChild(BuildContext context, String text, {TextStyle? style}) {
    return Text(context.tr(text), style: style);
  }

  // For translating AppBar titles
  static String trTitle(BuildContext context, String text) {
    return context.tr(text);
  }
}
