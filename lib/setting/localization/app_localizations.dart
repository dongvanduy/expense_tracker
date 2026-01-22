import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert' show json;
import 'package:expense_tracker/setting/localization/app_localizations_delegate.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<void> load() async {
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map<String, String>((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  // Tìm hàm translate cũ (thường ở khoảng dòng 28-30) và thay bằng:
  String translate(String key) {
    // Nếu tìm thấy key thì trả về giá trị, nếu không thấy (null) thì trả về chính cái key đó
    return _localizedStrings[key] ?? key;
  }
  bool get isEnLocale => locale.languageCode == 'en';
}
