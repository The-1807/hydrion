import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/locale_registry.dart';
import '../storage/local_store.dart';

enum HydrionLocaleMode { device, explicit }

class AppLocaleRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.app_locale.v1';
  static const _platformChannel = MethodChannel('hydrion/app_locale');

  final HydrionLocalStore _store;
  HydrionLocaleMode _mode;
  Locale _locale;
  bool _selectionCompleted;

  AppLocaleRepository._(
    this._store, {
    required HydrionLocaleMode mode,
    required Locale locale,
    required bool selectionCompleted,
  })  : _mode = mode,
        _locale = HydrionLocaleRegistry.resolve(locale),
        _selectionCompleted = selectionCompleted;

  factory AppLocaleRepository.memory({
    Locale locale = HydrionLocaleRegistry.fallback,
    bool selectionCompleted = true,
    HydrionLocaleMode mode = HydrionLocaleMode.explicit,
  }) =>
      AppLocaleRepository._(
        MemoryHydrionStore(),
        mode: mode,
        locale: locale,
        selectionCompleted: selectionCompleted,
      );

  static Future<AppLocaleRepository> load(
    HydrionLocalStore store, {
    Locale? deviceLocale,
    Locale? legacyLocale,
    bool establishedUser = false,
  }) async {
    final raw = await store.readString(storageKey);
    if (raw != null) {
      try {
        final value = jsonDecode(raw) as Map<String, Object?>;
        final mode = value['mode'] == 'explicit'
            ? HydrionLocaleMode.explicit
            : HydrionLocaleMode.device;
        final tag = value['languageTag']?.toString();
        final requested = tag == null ? deviceLocale : _localeFromTag(tag);
        return AppLocaleRepository._(
          store,
          mode: mode,
          locale: mode == HydrionLocaleMode.device
              ? deviceLocale ?? HydrionLocaleRegistry.fallback
              : requested ?? HydrionLocaleRegistry.fallback,
          selectionCompleted: value['selectionCompleted'] == true,
        );
      } catch (_) {
        // A corrupt preference safely returns to an unselected device locale.
      }
    }
    return AppLocaleRepository._(
      store,
      mode: establishedUser
          ? HydrionLocaleMode.explicit
          : HydrionLocaleMode.device,
      locale: establishedUser
          ? legacyLocale ?? HydrionLocaleRegistry.fallback
          : deviceLocale ?? PlatformDispatcher.instance.locale,
      selectionCompleted: establishedUser,
    );
  }

  Locale get locale => _locale;
  HydrionLocaleMode get mode => _mode;
  bool get selectionCompleted => _selectionCompleted;

  Future<void> useDeviceLocale([Locale? deviceLocale]) => _set(
        mode: HydrionLocaleMode.device,
        locale: deviceLocale ?? PlatformDispatcher.instance.locale,
      );

  Future<void> selectLocale(Locale locale) => _set(
        mode: HydrionLocaleMode.explicit,
        locale: locale,
      );

  Future<void> refreshFromAndroid() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final value = await _platformChannel
          .invokeMapMethod<String, Object?>('getApplicationLocale');
      if (value == null) return;
      final usesDeviceLocale = value['usesDeviceLocale'] == true;
      final tag = value['languageTag']?.toString().trim() ?? '';
      final nextMode = usesDeviceLocale
          ? HydrionLocaleMode.device
          : HydrionLocaleMode.explicit;
      final requested = usesDeviceLocale || tag.isEmpty
          ? PlatformDispatcher.instance.locale
          : _localeFromTag(tag);
      final nextLocale = HydrionLocaleRegistry.resolve(requested);
      if (_mode == nextMode && _locale == nextLocale) return;
      _mode = nextMode;
      _locale = nextLocale;
      if (!_selectionCompleted) {
        await _persist();
        notifyListeners();
        return;
      }
      await _persist();
      notifyListeners();
    } on PlatformException {
      // The saved Hydrion locale remains authoritative when Android is unavailable.
    } on MissingPluginException {
      // Tests and non-Android hosts do not install the native channel.
    }
  }

  Future<void> resetChoice() async {
    _selectionCompleted = false;
    _mode = HydrionLocaleMode.device;
    _locale = HydrionLocaleRegistry.resolve(PlatformDispatcher.instance.locale);
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _set({
    required HydrionLocaleMode mode,
    required Locale locale,
  }) async {
    _mode = mode;
    _locale = HydrionLocaleRegistry.resolve(locale);
    _selectionCompleted = true;
    await _persist();
    notifyListeners();
    unawaited(_synchronizeAndroidLocale(_locale));
  }

  Future<void> _persist() => _store.writeString(
        storageKey,
        jsonEncode({
          'mode': _mode.name,
          'languageTag': _languageTag(_locale),
          'selectionCompleted': _selectionCompleted,
        }),
      );

  static Future<void> _synchronizeAndroidLocale(Locale locale) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _platformChannel.invokeMethod<void>(
        'setApplicationLocale',
        {'languageTag': _languageTag(locale)},
      );
    } on PlatformException {
      // Flutter still uses the persisted locale when native sync is unavailable.
    } on MissingPluginException {
      // Unit tests and unsupported platforms do not install the Android channel.
    }
  }

  static Locale _localeFromTag(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }

  static String _languageTag(Locale locale) => locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
}
