// lib/utils/i18n_resolver.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class I18nResolver {
  static const supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('ar', 'SA'),
    Locale('de', 'DE'),
    Locale('pt', 'PT'),
    Locale('zh', 'CN'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    if (device == null) return const Locale('en', 'US');
    for (final l in supported) {
      if (l.languageCode == device.languageCode) {
        return l;
      }
    }
    return const Locale('en', 'US');
  }

  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ar' || locale.languageCode == 'he' || locale.languageCode == 'fa' || locale.languageCode == 'ur';
  }

  static TextDirection textDirectionOf(Locale locale) {
    return isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}
