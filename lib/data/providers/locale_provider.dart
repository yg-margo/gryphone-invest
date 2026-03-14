import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ru', 'RU');

  Locale get locale => _locale;
  bool get isRussian => _locale.languageCode == 'ru';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('langCode') ?? 'ru';
    _locale = langCode == 'ru'
        ? const Locale('ru', 'RU')
        : const Locale('en', 'US');
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    _locale = isRussian
        ? const Locale('en', 'US')
        : const Locale('ru', 'RU');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('langCode', _locale.languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('langCode', locale.languageCode);
    notifyListeners();
  }
}