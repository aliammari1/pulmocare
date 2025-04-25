import 'package:flutter/material.dart';
import 'package:medicare/utils/language_data.dart';
import '../localization/app_localizations.dart';

/// A helper class for translations
class TranslationHelper {
  /// Translates a text key into the current language and returns a Text widget
  static Widget text(BuildContext context, String key,
      {TextStyle? style,
      TextAlign? textAlign,
      int? maxLines,
      TextOverflow? overflow}) {
    return Text(
      context.tr(key),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Translates a text key into the current language (string only)
  static String tr(BuildContext context, String key) {
    return context.tr(key);
  }
}

/// Extensions for easier translation in widgets
extension TranslationWidgetExtension on Widget {
  /// Wraps a widget with a Builder to provide context for translations
  Widget withTranslation(BuildContext context) {
    return Builder(builder: (innerContext) => this);
  }
}

/// Add translation helpers for standard Flutter widgets
extension ButtonTranslation on ElevatedButton {
  /// Creates an ElevatedButton with translated text
  static ElevatedButton tr(
    BuildContext context,
    String textKey, {
    required VoidCallback? onPressed,
    ButtonStyle? style,
    TextStyle? textStyle,
    bool isLoading = false,
    Widget? loadingWidget,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: isLoading
          ? (loadingWidget ??
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ))
          : Text(context.tr(textKey), style: textStyle),
    );
  }
}

/// Application-wide translation checker
void verifyTranslations() {
  // Get all translation keys from English map
  final englishKeys = englishTranslations.keys.toSet();
  final frenchKeys = frenchTranslations.keys.toSet();
  final arabicKeys = arabicTranslations.keys.toSet();

  // Find missing translations in each language
  final missingInFrench = englishKeys.difference(frenchKeys);
  final missingInArabic = englishKeys.difference(arabicKeys);

  // Print warnings for development - can be removed in production
  if (missingInFrench.isNotEmpty) {
    print(
        'WARNING: Missing French translations for: ${missingInFrench.join(', ')}');
  }

  if (missingInArabic.isNotEmpty) {
    print(
        'WARNING: Missing Arabic translations for: ${missingInArabic.join(', ')}');
  }
}
