import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (default)
    Locale('es', 'ES'), // Spanish
    Locale('fr', 'FR'), // French
    Locale('zh', 'CN'), // Chinese (Simplified)
    Locale('hi', 'IN'), // Hindi
  ];

  static const List<LanguageData> languages = [
    LanguageData(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageData(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageData(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageData(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    LanguageData(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    final String jsonString = await rootBundle.loadString('lib/core/localization/lang/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Common translations
  String get appName => translate('app_name');
  String get home => translate('home');
  String get services => translate('services');
  String get history => translate('history');
  String get account => translate('account');
  String get airtime => translate('airtime');
  String get data => translate('data');
  String get bills => translate('bills');
  String get more => translate('more');
  String get buyAirtime => translate('buy_airtime');
  String get buyData => translate('buy_data');
  String get walletBalance => translate('wallet_balance');
  String get transactions => translate('transactions');
  String get recentTransactions => translate('recent_transactions');
  String get viewAll => translate('view_all');
  String get quickServices => translate('quick_services');
  String get transactionSummary => translate('transaction_summary');
  String get pending => translate('pending');
  String get completed => translate('completed');
  String get featuredServices => translate('featured_services');
  String get specialOffer => translate('special_offer');
  String get language => translate('language');
  String get chooseLanguage => translate('choose_language');
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get help => translate('help');
  String get about => translate('about');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get system => translate('system');
  String get appearance => translate('appearance');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

class LanguageData {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageData({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class LanguageNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) {
    _loadLanguage();
  }

  Locale get locale => _locale;

  Future<void> _loadLanguage() async {
    final String? languageCode = _prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    await _prefs.setString('language_code', languageCode);
    notifyListeners();
  }
}
