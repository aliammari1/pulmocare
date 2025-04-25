class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final bool isRTL;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRTL = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class AppLanguages {
  static const english = AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    isRTL: false,
  );

  static const french = AppLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    isRTL: false,
  );

  static const arabic = AppLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    isRTL: true,
  );

  static const List<AppLanguage> supportedLanguages = [
    english,
    french,
    arabic,
  ];
}
