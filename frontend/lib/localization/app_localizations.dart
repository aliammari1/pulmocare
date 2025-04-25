import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../utils/language_data.dart';

class AppLocalizations {
  final AppLanguage language;
  final Map<String, String> _localizedStrings;

  AppLocalizations(this.language, this._localizedStrings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguages.english, englishTranslations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get currentLanguageCode => language.code;

  String get currentLanguageName => language.name;

  bool get isRTL => language.isRTL;

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static Future<AppLocalizations> load(AppLanguage language) async {
    Map<String, String> translations;

    switch (language.code) {
      case 'en':
        translations = {
          ...englishTranslations,
          'select_diploma_language': 'Select Diploma Language',
          'select_language_for_verification':
              'Please select the language of your diploma or medical certificate to improve verification accuracy.',
          'uploading': 'Uploading...',
          'verification_successful':
              'Verification successful! Your account is now verified.',
          'verification_failed':
              'Verification failed. Please ensure your name is clearly visible in the document.',
          'verification_error': 'Error during verification',
          'language_mismatch': 'Language mismatch detected',
          'try_correct_language': 'Try with detected language instead',
        };
        break;
      case 'fr':
        translations = {
          ...frenchTranslations,
          'select_diploma_language': 'Select Diploma Language',
          'select_language_for_verification':
              'Please select the language of your diploma or medical certificate to improve verification accuracy.',
          'uploading': 'Uploading...',
          'verification_successful':
              'Verification successful! Your account is now verified.',
          'verification_failed':
              'Verification failed. Please ensure your name is clearly visible in the document.',
          'verification_error': 'Error during verification',
          'language_mismatch': 'Language mismatch detected',
          'try_correct_language': 'Try with detected language instead',
        };
        break;
      case 'ar':
        translations = {
          ...arabicTranslations,
          'select_diploma_language': 'Select Diploma Language',
          'select_language_for_verification':
              'Please select the language of your diploma or medical certificate to improve verification accuracy.',
          'uploading': 'Uploading...',
          'verification_successful':
              'Verification successful! Your account is now verified.',
          'verification_failed':
              'Verification failed. Please ensure your name is clearly visible in the document.',
          'verification_error': 'Error during verification',
          'language_mismatch': 'Language mismatch detected',
          'try_correct_language': 'Try with detected language instead',
        };
        break;
      default:
        translations = {
          ...englishTranslations,
          'select_diploma_language': 'Select Diploma Language',
          'select_language_for_verification':
              'Please select the language of your diploma or medical certificate to improve verification accuracy.',
          'uploading': 'Uploading...',
          'verification_successful':
              'Verification successful! Your account is now verified.',
          'verification_failed':
              'Verification failed. Please ensure your name is clearly visible in the document.',
          'verification_error': 'Error during verification',
          'language_mismatch': 'Language mismatch detected',
          'try_correct_language': 'Try with detected language instead',
        };
    }

    return AppLocalizations(language, translations);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLanguage language = AppLanguages.supportedLanguages.firstWhere(
      (lang) => lang.code == locale.languageCode,
      orElse: () => AppLanguages.english,
    );

    return await AppLocalizations.load(language);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension TranslateX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
}
