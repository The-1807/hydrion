import 'package:flutter/widgets.dart';

enum HydrionLocaleReadiness { production, inProgress }

class HydrionLocaleDefinition {
  final String languageTag;
  final String nativeName;
  final Locale locale;
  final TextDirection textDirection;
  final HydrionLocaleReadiness readiness;
  final bool flutterAvailable;
  final bool androidResourcesAvailable;
  final bool widgetResourcesAvailable;
  final bool notificationResourcesAvailable;

  const HydrionLocaleDefinition({
    required this.languageTag,
    required this.nativeName,
    required this.locale,
    required this.textDirection,
    required this.readiness,
    required this.flutterAvailable,
    required this.androidResourcesAvailable,
    required this.widgetResourcesAvailable,
    required this.notificationResourcesAvailable,
  });

  bool get productionReady =>
      readiness == HydrionLocaleReadiness.production &&
      flutterAvailable &&
      androidResourcesAvailable &&
      widgetResourcesAvailable &&
      notificationResourcesAvailable;
}

class HydrionLocaleRegistry {
  const HydrionLocaleRegistry._();

  static const fallback = Locale('en');

  static const locales = <HydrionLocaleDefinition>[
    HydrionLocaleDefinition(
      languageTag: 'en',
      nativeName: 'English',
      locale: Locale('en'),
      textDirection: TextDirection.ltr,
      readiness: HydrionLocaleReadiness.production,
      flutterAvailable: true,
      androidResourcesAvailable: true,
      widgetResourcesAvailable: true,
      notificationResourcesAvailable: true,
    ),
    HydrionLocaleDefinition(
      languageTag: 'fr',
      nativeName: 'Fran\u00e7ais',
      locale: Locale('fr'),
      textDirection: TextDirection.ltr,
      readiness: HydrionLocaleReadiness.production,
      flutterAvailable: true,
      androidResourcesAvailable: true,
      widgetResourcesAvailable: true,
      notificationResourcesAvailable: true,
    ),
    HydrionLocaleDefinition(
      languageTag: 'es',
      nativeName: 'Espa\u00f1ol',
      locale: Locale('es'),
      textDirection: TextDirection.ltr,
      readiness: HydrionLocaleReadiness.production,
      flutterAvailable: true,
      androidResourcesAvailable: true,
      widgetResourcesAvailable: true,
      notificationResourcesAvailable: true,
    ),
    HydrionLocaleDefinition(
      languageTag: 'pt-BR',
      nativeName: 'Portugu\u00eas (Brasil)',
      locale: Locale('pt', 'BR'),
      textDirection: TextDirection.ltr,
      readiness: HydrionLocaleReadiness.inProgress,
      flutterAvailable: false,
      androidResourcesAvailable: false,
      widgetResourcesAvailable: false,
      notificationResourcesAvailable: false,
    ),
    HydrionLocaleDefinition(
      languageTag: 'de',
      nativeName: 'Deutsch',
      locale: Locale('de'),
      textDirection: TextDirection.ltr,
      readiness: HydrionLocaleReadiness.inProgress,
      flutterAvailable: false,
      androidResourcesAvailable: false,
      widgetResourcesAvailable: false,
      notificationResourcesAvailable: false,
    ),
  ];

  static List<HydrionLocaleDefinition> get productionLocales =>
      List.unmodifiable(
          locales.where((definition) => definition.productionReady));

  static Locale resolve(Locale? requested) {
    if (requested == null) return fallback;
    for (final definition in productionLocales) {
      if (definition.locale.languageCode == requested.languageCode &&
          (definition.locale.countryCode == null ||
              definition.locale.countryCode == requested.countryCode)) {
        return definition.locale;
      }
    }
    return fallback;
  }

  static HydrionLocaleDefinition definitionFor(Locale locale) =>
      productionLocales.firstWhere(
        (definition) => definition.locale == resolve(locale),
        orElse: () => locales.first,
      );
}
