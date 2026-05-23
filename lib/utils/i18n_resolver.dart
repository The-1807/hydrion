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

  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  Future<void> loadLocale(Locale locale) async {
    _locale = resolveLocale(locale, supportedLocales);
  }

  String getText(String key, String fallback) {
    return _localizedText[_locale.languageCode]?[key] ??
        _localizedText['en']?[key] ??
        fallback;
  }

  TextDirection getTextDirection(Locale locale) {
    return textDirectionOf(locale);
  }

  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    if (device == null) {
      return const Locale('en', 'US');
    }
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) {
        return locale;
      }
    }
    return const Locale('en', 'US');
  }

  static bool isRtl(Locale locale) {
    return const {'ar', 'he', 'fa', 'ur'}.contains(locale.languageCode);
  }

  static TextDirection textDirectionOf(Locale locale) {
    return isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}

const Map<String, Map<String, String>> _localizedText = {
  'en': {
    'app_title': 'Hydrion',
    'analytics_title': 'Analytics',
    'achievements': 'Achievements',
    'eco_impact': 'Environmental Impact',
    'plastic_saved': 'Plastic saved',
    'challenges_title': 'Challenges',
    'no_challenges': 'No challenges available',
    'challenge_joined': 'Challenge joined',
    'join': 'Join',
    'chat_error': 'Could not fetch coach reply',
    'chat_coach_title': 'Hydration Coach',
    'chat_hint': 'Ask your coach...',
    'log_title': 'Hydration Log',
    'logs_error': 'Failed to load hydration logs',
    'no_logs': 'No hydration logs found',
    'settings_title': 'Settings',
    'language': 'Language',
    'lang_updated': 'Language updated',
    'permissions': 'Permissions',
    'manage_permissions': 'Manage app permissions',
    'permissions_updated': 'Permissions updated',
    'ar_title': 'AR Hydration View',
  },
  'es': {
    'app_title': 'Hydrion',
    'analytics_title': 'Analitica',
    'settings_title': 'Configuracion',
  },
  'fr': {
    'app_title': 'Hydrion',
    'analytics_title': 'Analyses',
    'settings_title': 'Parametres',
  },
};
