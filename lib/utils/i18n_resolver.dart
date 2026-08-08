import 'package:flutter/material.dart';

import '../domain/locale_registry.dart';
import '../repositories/app_locale_repository.dart';

enum LocaleSupportStatus {
  active,
  future,
  unsupported,
}

class I18nResolver extends ChangeNotifier {
  static const fallbackLocale = HydrionLocaleRegistry.fallback;

  static List<Locale> get supportedLocales =>
      HydrionLocaleRegistry.productionLocales
          .map((definition) => definition.locale)
          .toList(growable: false);

  static const futureLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('pt'),
    Locale('zh'),
  ];

  final AppLocaleRepository? _localeRepository;
  Locale _locale;

  I18nResolver({AppLocaleRepository? localeRepository})
      : _localeRepository = localeRepository,
        _locale = HydrionLocaleRegistry.resolve(localeRepository?.locale) {
    localeRepository?.addListener(_handleRepositoryChange);
  }

  Locale get locale => _locale;

  Future<void> loadLocale(Locale locale) {
    return setLocale(locale);
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = HydrionLocaleRegistry.resolve(locale);
    final changed = _locale != resolved;
    _locale = resolved;
    await _localeRepository?.selectLocale(_locale);
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

  void _handleRepositoryChange() {
    final next = HydrionLocaleRegistry.resolve(_localeRepository?.locale);
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _localeRepository?.removeListener(_handleRepositoryChange);
    super.dispose();
  }
}
