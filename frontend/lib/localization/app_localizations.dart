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
          'medication_search': 'Medication Search',
          'enter_medication_name': 'Enter medication name',
          'search': 'Search',
          'search_disclaimer': 'Data provided by med.tn',
          'medication_not_found': 'Medication not found',
          'no_results_found_for': 'No results found for',
          'try_different_search': 'Please try a different search term',
          'form': 'Form',
          'dosage': 'Dosage',
          'laboratory': 'Laboratory',
          'presentation': 'Presentation',
          'price': 'Price',
          'indication': 'Indication',
          'composition': 'Composition',
          'posology': 'Posology',
          'view_on_medtn': 'View full details on med.tn',
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
          'medication_search': 'Recherche de Médicaments',
          'enter_medication_name': 'Entrez le nom du médicament',
          'search': 'Rechercher',
          'search_disclaimer': 'Données fournies par med.tn',
          'medication_not_found': 'Médicament non trouvé',
          'no_results_found_for': 'Aucun résultat trouvé pour',
          'try_different_search':
              'Veuillez essayer un autre terme de recherche',
          'form': 'Forme',
          'dosage': 'Dosage',
          'laboratory': 'Laboratoire',
          'presentation': 'Présentation',
          'price': 'Prix',
          'indication': 'Indication',
          'composition': 'Composition',
          'posology': 'Posologie',
          'view_on_medtn': 'Voir les détails complets sur med.tn',
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
          'medication_search': 'البحث عن الدواء',
          'enter_medication_name': 'أدخل اسم الدواء',
          'search': 'بحث',
          'search_disclaimer': 'البيانات مقدمة من med.tn',
          'medication_not_found': 'الدواء غير موجود',
          'no_results_found_for': 'لم يتم العثور على نتائج لـ',
          'try_different_search': 'يرجى تجربة مصطلح بحث مختلف',
          'form': 'الشكل',
          'dosage': 'الجرعة',
          'laboratory': 'المختبر',
          'presentation': 'العرض',
          'price': 'السعر',
          'indication': 'دواعي الاستعمال',
          'composition': 'التركيب',
          'posology': 'الجرعات',
          'view_on_medtn': 'عرض التفاصيل الكاملة على med.tn',
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
          'medication_search': 'Medication Search',
          'enter_medication_name': 'Enter medication name',
          'search': 'Search',
          'search_disclaimer': 'Data provided by med.tn',
          'medication_not_found': 'Medication not found',
          'no_results_found_for': 'No results found for',
          'try_different_search': 'Please try a different search term',
          'form': 'Form',
          'dosage': 'Dosage',
          'laboratory': 'Laboratory',
          'presentation': 'Presentation',
          'price': 'Price',
          'indication': 'Indication',
          'composition': 'Composition',
          'posology': 'Posology',
          'view_on_medtn': 'View full details on med.tn',
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
