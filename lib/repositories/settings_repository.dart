import 'dart:convert';

import 'package:flutter/material.dart';

import '../storage/local_store.dart';
import 'storage_recovery.dart';

class UserSettings {
  static const fallbackLocale = Locale('en');
  static const supportedLanguageCodes = <String>{'en', 'es', 'fr'};
  static const defaultDailyGoalMl = 2200;
  static const minDailyGoalMl = 500;
  static const maxDailyGoalMl = 5000;

  final Locale locale;
  final bool nonLocalProviderConsentGranted;
  final int dailyGoalMl;
  final bool reusableContainerEnabled;

  const UserSettings({
    required this.locale,
    this.nonLocalProviderConsentGranted = false,
    this.dailyGoalMl = defaultDailyGoalMl,
    this.reusableContainerEnabled = false,
  });

  UserSettings copyWith({
    Locale? locale,
    bool? nonLocalProviderConsentGranted,
    int? dailyGoalMl,
    bool? reusableContainerEnabled,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      nonLocalProviderConsentGranted:
          nonLocalProviderConsentGranted ?? this.nonLocalProviderConsentGranted,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      reusableContainerEnabled:
          reusableContainerEnabled ?? this.reusableContainerEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'nonLocalProviderConsentGranted': nonLocalProviderConsentGranted,
      'dailyGoalMl': dailyGoalMl,
      'reusableContainerEnabled': reusableContainerEnabled,
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
        dailyGoalMl: _safeDailyGoal(value['dailyGoalMl']),
        reusableContainerEnabled: value['reusableContainerEnabled'] == true,
      );
    }
    final countryCode = _countryCode(value['countryCode']);
    return UserSettings(
      locale: Locale(languageCode, countryCode),
      nonLocalProviderConsentGranted:
          value['nonLocalProviderConsentGranted'] == true,
      dailyGoalMl: _safeDailyGoal(value['dailyGoalMl']),
      reusableContainerEnabled: value['reusableContainerEnabled'] == true,
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

  static int _safeDailyGoal(Object? value) {
    if (value is! num || !value.isFinite) {
      return defaultDailyGoalMl;
    }
    final goal = value.round();
    if (goal < minDailyGoalMl || goal > maxDailyGoalMl) {
      return defaultDailyGoalMl;
    }
    return goal;
  }
}

class UserSettingsRepository extends ChangeNotifier {
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
    int dailyGoalMl = UserSettings.defaultDailyGoalMl,
    bool reusableContainerEnabled = false,
  ]) : this._(
          MemoryHydrionStore(),
          UserSettings(
            locale: locale,
            nonLocalProviderConsentGranted: nonLocalProviderConsentGranted,
            dailyGoalMl: dailyGoalMl,
            reusableContainerEnabled: reusableContainerEnabled,
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
    notifyListeners();
  }

  Future<void> setNonLocalProviderConsentGranted(bool value) async {
    _settings = _settings.copyWith(nonLocalProviderConsentGranted: value);
    await _persist();
    notifyListeners();
  }

  Future<bool> setDailyGoalMl(int value) async {
    if (value < UserSettings.minDailyGoalMl ||
        value > UserSettings.maxDailyGoalMl) {
      return false;
    }
    _settings = _settings.copyWith(dailyGoalMl: value);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> setReusableContainerEnabled(bool value) async {
    _settings = _settings.copyWith(reusableContainerEnabled: value);
    await _persist();
    notifyListeners();
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
    final events = <StorageRecoveryEvent>[];
    final languageCode = value['languageCode'];
    if (languageCode is! String ||
        !UserSettings.supportedLanguageCodes
            .contains(languageCode.trim().toLowerCase())) {
      events.add(
        const StorageRecoveryEvent(
          category: _category,
          code: StorageRecoveryCodes.invalidValue,
          action: StorageRecoveryActions.fallbackDefaults,
        ),
      );
    }
    final dailyGoal = value['dailyGoalMl'];
    if (dailyGoal is num &&
        dailyGoal.isFinite &&
        dailyGoal.round() >= UserSettings.minDailyGoalMl &&
        dailyGoal.round() <= UserSettings.maxDailyGoalMl) {
      return events;
    }
    if (value.containsKey('dailyGoalMl')) {
      events.add(
        const StorageRecoveryEvent(
          category: _category,
          code: StorageRecoveryCodes.invalidValue,
          action: StorageRecoveryActions.fallbackDefaults,
        ),
      );
    }
    return events;
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
