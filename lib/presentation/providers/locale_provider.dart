import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', 'US')) {
    _loadLocale();
  }

  static const String _localeKey = 'app_locale';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('${_localeKey}_language_code') ?? 'en';
    final countryCode = prefs.getString('${_localeKey}_country_code') ?? 'US';
    state = Locale(languageCode, countryCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_localeKey}_language_code', locale.languageCode);
    await prefs.setString('${_localeKey}_country_code', locale.countryCode ?? '');
    state = locale;
  }
}
