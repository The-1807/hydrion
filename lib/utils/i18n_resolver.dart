import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

enum LocaleSupportStatus {
  active,
  future,
  unsupported,
}

class I18nResolver extends ChangeNotifier {
  static const fallbackLocale = Locale('en');

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  static const futureLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('pt'),
    Locale('zh'),
  ];

  final UserSettingsRepository? _settingsRepository;
  Locale _locale;

  I18nResolver({UserSettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository,
        _locale = resolveLocale(
          settingsRepository?.settings.locale,
          supportedLocales,
        );

  Locale get locale => _locale;

  Future<void> loadLocale(Locale locale) {
    return setLocale(locale);
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = resolveLocale(locale, supportedLocales);
    final changed = _locale != resolved;
    _locale = resolved;
    await _settingsRepository?.setLocale(_locale);
    if (changed) {
      notifyListeners();
    }
  }

  bool isSupported(Locale locale) {
    return localeStatus(locale) == LocaleSupportStatus.active;
  }

  LocaleSupportStatus localeStatus(Locale locale) {
    if (_containsLanguage(supportedLocales, locale)) {
      return LocaleSupportStatus.active;
    }
    if (_containsLanguage(futureLocales, locale)) {
      return LocaleSupportStatus.future;
    }
    return LocaleSupportStatus.unsupported;
  }

  TextDirection getTextDirection(Locale locale) {
    return textDirectionOf(locale);
  }

  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    if (device == null) {
      return fallbackLocale;
    }
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) {
        return locale;
      }
    }
    return fallbackLocale;
  }

  static bool isRtl(Locale locale) {
    return const {'ar', 'he', 'fa', 'ur'}.contains(locale.languageCode);
  }

  static TextDirection textDirectionOf(Locale locale) {
    return isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  static bool _containsLanguage(Iterable<Locale> locales, Locale target) {
    return locales.any((locale) => locale.languageCode == target.languageCode);
  }
}
