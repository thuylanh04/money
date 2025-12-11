import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _languageKey = 'languageCode';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'dateFormat';

  late bool _isDarkMode;
  late String _languageCode;
  late String _currency;
  late String _dateFormat;
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs)
      : _isDarkMode = _prefs.getBool(_themeKey) ?? false,
        _languageCode = _prefs.getString(_languageKey) ?? 'en',
        _currency = _prefs.getString(_currencyKey) ?? 'USD',
        _dateFormat = _prefs.getString(_dateFormatKey) ?? 'dd/MM/yyyy';

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;
  String get currency => _currency;
  String get dateFormat => _dateFormat;

  // Theme methods
  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  // Language methods
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  // Currency methods (read-only for now)
  String getCurrencySymbol() {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'USD':
        return '₫';
      default:
        return _currency;
    }
  }

  // Date format methods
  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    await _prefs.setString(_dateFormatKey, format);
    notifyListeners();
  }

  // Format date according to current format
  String formatDate(DateTime date) {
    String result = _dateFormat;
    result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    result = result.replaceAll('yyyy', date.year.toString());
    return result;
  }
}
