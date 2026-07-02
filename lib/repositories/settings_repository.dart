import 'dart:convert';

import 'package:flutter/material.dart';

import '../storage/local_store.dart';
import 'storage_recovery.dart';

class UserSettings {
  static const fallbackLocale = Locale('en');
  static const supportedLanguageCodes = <String>{'en', 'es', 'fr'};

  final Locale locale;
  final bool nonLocalProviderConsentGranted;

  const UserSettings({
    required this.locale,
    this.nonLocalProviderConsentGranted = false,
  });

  UserSettings copyWith({
    Locale? locale,
    bool? nonLocalProviderConsentGranted,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      nonLocalProviderConsentGranted:
          nonLocalProviderConsentGranted ?? this.nonLocalProviderConsentGranted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'nonLocalProviderConsentGranted': nonLocalProviderConsentGranted,
    };
  }

  static UserSettings fromJson(Object? value) {
    if (value is! Map) {
      return const UserSettings(locale: fallbackLocale);
    }
    final languageCode = _supportedLanguageCode(value['languageCode']);
    if (languageCode == null) {
      return UserSettings(
        locale: fallbackLocale,
        nonLocalProviderConsentGranted:
            value['nonLocalProviderConsentGranted'] == true,
      );
    }
    final countryCode = _countryCode(value['countryCode']);
    return UserSettings(
      locale: Locale(languageCode, countryCode),
      nonLocalProviderConsentGranted:
          value['nonLocalProviderConsentGranted'] == true,
    );
  }

  static String? _supportedLanguageCode(Object? value) {
    if (value is! String) {
      return null;
    }
    final languageCode = value.trim().toLowerCase();
    if (!supportedLanguageCodes.contains(languageCode)) {
      return null;
    }
    return languageCode;
  }

  static String? _countryCode(Object? value) {
    if (value is! String) {
      return null;
    }
    final countryCode = value.trim().toUpperCase();
    return countryCode.isEmpty ? null : countryCode;
  }
}

class UserSettingsRepository {
  static const storageKey = 'hydrion.user_settings.v1';
  static const _category = 'user_settings';
  static const _currentSchemaVersion = 1;

  final HydrionLocalStore _store;
  final List<StorageRecoveryEvent> _recoveryEvents;
  UserSettings _settings;

  UserSettingsRepository._(
    this._store,
    this._settings, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ]) : _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        );

  UserSettingsRepository.memory([
    Locale locale = UserSettings.fallbackLocale,
    bool nonLocalProviderConsentGranted = false,
  ]) : this._(
          MemoryHydrionStore(),
          UserSettings(
            locale: locale,
            nonLocalProviderConsentGranted: nonLocalProviderConsentGranted,
          ),
        );

  static Future<UserSettingsRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final result = _decodeSettings(raw);
    return UserSettingsRepository._(
      store,
      result.settings,
      result.recoveryEvents,
    );
  }

  UserSettings get settings => _settings;

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  Future<void> setLocale(Locale locale) async {
    _settings = _settings.copyWith(locale: locale);
    await _persist();
  }

  Future<void> setNonLocalProviderConsentGranted(bool value) async {
    _settings = _settings.copyWith(nonLocalProviderConsentGranted: value);
    await _persist();
  }

  Future<void> _persist() async {
    await _store.writeString(storageKey, jsonEncode(_settings.toJson()));
  }

  static _SettingsDecodeResult _decodeSettings(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _SettingsDecodeResult(
        UserSettings(locale: UserSettings.fallbackLocale),
      );
    }

    try {
      final decoded = jsonDecode(raw);
      final schemaVersion = storageSchemaVersion(decoded);
      if (schemaVersion != null && schemaVersion > _currentSchemaVersion) {
        return _SettingsDecodeResult(
          const UserSettings(locale: UserSettings.fallbackLocale),
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.unsupportedSchemaVersion,
              action: StorageRecoveryActions.preserveRawFallback,
              schemaVersion: schemaVersion,
            ),
          ],
        );
      }
      if (decoded is! Map) {
        return const _SettingsDecodeResult(
          UserSettings(locale: UserSettings.fallbackLocale),
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.fallbackDefaults,
            ),
          ],
        );
      }
      return _SettingsDecodeResult(
        UserSettings.fromJson(decoded),
        recoveryEvents: _settingsRecoveryEvents(decoded),
      );
    } on FormatException {
      return const _SettingsDecodeResult(
        UserSettings(locale: UserSettings.fallbackLocale),
        recoveryEvents: <StorageRecoveryEvent>[
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.malformedJson,
            action: StorageRecoveryActions.fallbackDefaults,
            errorType: 'FormatException',
          ),
        ],
      );
    }
  }

  static List<StorageRecoveryEvent> _settingsRecoveryEvents(Map value) {
    final languageCode = value['languageCode'];
    if (languageCode is String &&
        UserSettings.supportedLanguageCodes
            .contains(languageCode.trim().toLowerCase())) {
      return const <StorageRecoveryEvent>[];
    }
    return const <StorageRecoveryEvent>[
      StorageRecoveryEvent(
        category: _category,
        code: StorageRecoveryCodes.invalidValue,
        action: StorageRecoveryActions.fallbackDefaults,
      ),
    ];
  }
}

class _SettingsDecodeResult {
  final UserSettings settings;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _SettingsDecodeResult(
    this.settings, {
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
