import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/avatar_manifest.dart';
import '../storage/local_store.dart';
import 'storage_recovery.dart';

enum HydrionSex {
  female,
  male,
  intersex,
  preferNotToSay,
}

enum HydrionGoalMode {
  manual,
  weatherInformed,
}

enum HydrionVolumeUnit {
  milliliters,
  ounces,
}

class UserSettings {
  static const fallbackLocale = Locale('en');
  static const supportedLanguageCodes = <String>{'en', 'es', 'fr'};
  static const defaultDailyGoalMl = 2200;
  static const minDailyGoalMl = 500;
  static const maxDailyGoalMl = 5000;
  static const defaultContainerSizeMl = 500;
  static const minContainerSizeMl = 100;
  static const maxContainerSizeMl = 2000;
  static const maxNicknameLength = 32;

  final Locale locale;
  final bool nonLocalProviderConsentGranted;
  final int dailyGoalMl;
  final bool reusableContainerEnabled;
  final String? nickname;
  final int? age;
  final HydrionSex? sex;
  final String avatarId;
  final HydrionGoalMode goalMode;
  final HydrionVolumeUnit volumeUnit;
  final int containerSizeMl;
  final bool onboardingCompleted;
  final bool legalAndHealthAcknowledged;
  final bool weatherGoalAutoApplyEnabled;
  final DateTime? lastWeatherGoalDecisionAt;

  const UserSettings({
    required this.locale,
    this.nonLocalProviderConsentGranted = false,
    this.dailyGoalMl = defaultDailyGoalMl,
    this.reusableContainerEnabled = false,
    this.nickname,
    this.age,
    this.sex,
    this.avatarId = 'savvy-eco_shark',
    this.goalMode = HydrionGoalMode.manual,
    this.volumeUnit = HydrionVolumeUnit.milliliters,
    this.containerSizeMl = defaultContainerSizeMl,
    this.onboardingCompleted = false,
    this.legalAndHealthAcknowledged = false,
    this.weatherGoalAutoApplyEnabled = false,
    this.lastWeatherGoalDecisionAt,
  });

  UserSettings copyWith({
    Locale? locale,
    bool? nonLocalProviderConsentGranted,
    int? dailyGoalMl,
    bool? reusableContainerEnabled,
    String? nickname,
    bool clearNickname = false,
    int? age,
    bool clearAge = false,
    HydrionSex? sex,
    bool clearSex = false,
    String? avatarId,
    HydrionGoalMode? goalMode,
    HydrionVolumeUnit? volumeUnit,
    int? containerSizeMl,
    bool? onboardingCompleted,
    bool? legalAndHealthAcknowledged,
    bool? weatherGoalAutoApplyEnabled,
    DateTime? lastWeatherGoalDecisionAt,
    bool clearLastWeatherGoalDecisionAt = false,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      nonLocalProviderConsentGranted:
          nonLocalProviderConsentGranted ?? this.nonLocalProviderConsentGranted,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      reusableContainerEnabled:
          reusableContainerEnabled ?? this.reusableContainerEnabled,
      nickname: clearNickname ? null : nickname ?? this.nickname,
      age: clearAge ? null : age ?? this.age,
      sex: clearSex ? null : sex ?? this.sex,
      avatarId: avatarId ?? this.avatarId,
      goalMode: goalMode ?? this.goalMode,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      containerSizeMl: containerSizeMl ?? this.containerSizeMl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      legalAndHealthAcknowledged:
          legalAndHealthAcknowledged ?? this.legalAndHealthAcknowledged,
      weatherGoalAutoApplyEnabled:
          weatherGoalAutoApplyEnabled ?? this.weatherGoalAutoApplyEnabled,
      lastWeatherGoalDecisionAt: clearLastWeatherGoalDecisionAt
          ? null
          : lastWeatherGoalDecisionAt ?? this.lastWeatherGoalDecisionAt,
    );
  }

  bool get hasProfileName => nickname != null && nickname!.trim().isNotEmpty;

  bool get weatherGoalEligible {
    return age != null &&
        sex != null &&
        sex != HydrionSex.preferNotToSay &&
        goalMode == HydrionGoalMode.weatherInformed;
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'nonLocalProviderConsentGranted': nonLocalProviderConsentGranted,
      'dailyGoalMl': dailyGoalMl,
      'reusableContainerEnabled': reusableContainerEnabled,
      'nickname': nickname,
      'age': age,
      'sex': sex?.name,
      'avatarId': avatarId,
      'goalMode': goalMode.name,
      'volumeUnit': volumeUnit.name,
      'containerSizeMl': containerSizeMl,
      'onboardingCompleted': onboardingCompleted,
      'legalAndHealthAcknowledged': legalAndHealthAcknowledged,
      'weatherGoalAutoApplyEnabled': weatherGoalAutoApplyEnabled,
      'lastWeatherGoalDecisionAt': lastWeatherGoalDecisionAt?.toIso8601String(),
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
        nickname: _safeNickname(value['nickname']),
        age: _safeAge(value['age']),
        sex: _safeSex(value['sex']),
        avatarId: _safeAvatarId(value['avatarId']),
        goalMode: _safeGoalMode(value['goalMode']),
        volumeUnit: _safeVolumeUnit(value['volumeUnit']),
        containerSizeMl: _safeContainerSize(value['containerSizeMl']),
        onboardingCompleted: value['onboardingCompleted'] == true,
        legalAndHealthAcknowledged: value['legalAndHealthAcknowledged'] == true,
        weatherGoalAutoApplyEnabled:
            value['weatherGoalAutoApplyEnabled'] == true,
        lastWeatherGoalDecisionAt:
            _safeDateTime(value['lastWeatherGoalDecisionAt']),
      );
    }
    final countryCode = _countryCode(value['countryCode']);
    return UserSettings(
      locale: Locale(languageCode, countryCode),
      nonLocalProviderConsentGranted:
          value['nonLocalProviderConsentGranted'] == true,
      dailyGoalMl: _safeDailyGoal(value['dailyGoalMl']),
      reusableContainerEnabled: value['reusableContainerEnabled'] == true,
      nickname: _safeNickname(value['nickname']),
      age: _safeAge(value['age']),
      sex: _safeSex(value['sex']),
      avatarId: _safeAvatarId(value['avatarId']),
      goalMode: _safeGoalMode(value['goalMode']),
      volumeUnit: _safeVolumeUnit(value['volumeUnit']),
      containerSizeMl: _safeContainerSize(value['containerSizeMl']),
      onboardingCompleted: value['onboardingCompleted'] == true,
      legalAndHealthAcknowledged: value['legalAndHealthAcknowledged'] == true,
      weatherGoalAutoApplyEnabled: value['weatherGoalAutoApplyEnabled'] == true,
      lastWeatherGoalDecisionAt:
          _safeDateTime(value['lastWeatherGoalDecisionAt']),
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

  static String? _safeNickname(Object? value) {
    if (value is! String) {
      return null;
    }
    final nickname = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (nickname.isEmpty || nickname.length > maxNicknameLength) {
      return null;
    }
    return nickname;
  }

  static int? _safeAge(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }
    final age = value.round();
    if (age < 13 || age > 120) {
      return null;
    }
    return age;
  }

  static HydrionSex? _safeSex(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final sex in HydrionSex.values) {
      if (sex.name == value) {
        return sex;
      }
    }
    return null;
  }

  static HydrionGoalMode _safeGoalMode(Object? value) {
    if (value is String) {
      for (final mode in HydrionGoalMode.values) {
        if (mode.name == value) {
          return mode;
        }
      }
    }
    return HydrionGoalMode.manual;
  }

  static HydrionVolumeUnit _safeVolumeUnit(Object? value) {
    if (value is String) {
      for (final unit in HydrionVolumeUnit.values) {
        if (unit.name == value) {
          return unit;
        }
      }
    }
    return HydrionVolumeUnit.milliliters;
  }

  static String _safeAvatarId(Object? value) {
    final id = value is String ? value.trim() : null;
    return HydrionAvatarManifest.byId(id).id;
  }

  static int _safeContainerSize(Object? value) {
    if (value is! num || !value.isFinite) {
      return defaultContainerSizeMl;
    }
    final size = value.round();
    if (size < minContainerSizeMl || size > maxContainerSizeMl) {
      return defaultContainerSizeMl;
    }
    return size;
  }

  static DateTime? _safeDateTime(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
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
    bool onboardingCompleted = true,
  ]) : this._(
          MemoryHydrionStore(),
          UserSettings(
            locale: locale,
            nonLocalProviderConsentGranted: nonLocalProviderConsentGranted,
            dailyGoalMl: dailyGoalMl,
            reusableContainerEnabled: reusableContainerEnabled,
            onboardingCompleted: onboardingCompleted,
            legalAndHealthAcknowledged: onboardingCompleted,
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

  Future<bool> setProfile({
    required String nickname,
    int? age,
    HydrionSex? sex,
  }) async {
    final safeNickname = UserSettings._safeNickname(nickname);
    if (safeNickname == null) {
      return false;
    }
    _settings = _settings.copyWith(
      nickname: safeNickname,
      age: age,
      clearAge: age == null,
      sex: sex,
      clearSex: sex == null,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> setAvatarId(String avatarId) async {
    final safeAvatarId = UserSettings._safeAvatarId(avatarId);
    if (safeAvatarId != avatarId) {
      return false;
    }
    _settings = _settings.copyWith(avatarId: safeAvatarId);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> setGoalMode(HydrionGoalMode mode) async {
    _settings = _settings.copyWith(goalMode: mode);
    await _persist();
    notifyListeners();
  }

  Future<void> setVolumeUnit(HydrionVolumeUnit unit) async {
    _settings = _settings.copyWith(volumeUnit: unit);
    await _persist();
    notifyListeners();
  }

  Future<bool> setContainerSizeMl(int value) async {
    if (value < UserSettings.minContainerSizeMl ||
        value > UserSettings.maxContainerSizeMl) {
      return false;
    }
    _settings = _settings.copyWith(containerSizeMl: value);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> setWeatherGoalAutoApplyEnabled(bool value) async {
    _settings = _settings.copyWith(weatherGoalAutoApplyEnabled: value);
    await _persist();
    notifyListeners();
  }

  Future<void> recordWeatherGoalDecision(DateTime value) async {
    _settings = _settings.copyWith(lastWeatherGoalDecisionAt: value);
    await _persist();
    notifyListeners();
  }

  Future<void> setOnboardingCompleted({
    required bool completed,
    required bool legalAndHealthAcknowledged,
  }) async {
    _settings = _settings.copyWith(
      onboardingCompleted: completed,
      legalAndHealthAcknowledged: legalAndHealthAcknowledged,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> reopenOnboarding() async {
    _settings = _settings.copyWith(onboardingCompleted: false);
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
      _addProfileRecoveryEvents(value, events);
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
    _addProfileRecoveryEvents(value, events);
    return events;
  }

  static void _addProfileRecoveryEvents(
    Map value,
    List<StorageRecoveryEvent> events,
  ) {
    if (value.containsKey('nickname') &&
        UserSettings._safeNickname(value['nickname']) == null) {
      events.add(
        const StorageRecoveryEvent(
          category: _category,
          code: StorageRecoveryCodes.invalidValue,
          action: StorageRecoveryActions.fallbackDefaults,
        ),
      );
    }
    if (value.containsKey('avatarId') &&
        UserSettings._safeAvatarId(value['avatarId']) != value['avatarId']) {
      events.add(
        const StorageRecoveryEvent(
          category: _category,
          code: StorageRecoveryCodes.invalidValue,
          action: StorageRecoveryActions.fallbackDefaults,
        ),
      );
    }
    if (value.containsKey('containerSizeMl')) {
      final containerSize = value['containerSizeMl'];
      if (containerSize is! num ||
          !containerSize.isFinite ||
          containerSize.round() < UserSettings.minContainerSizeMl ||
          containerSize.round() > UserSettings.maxContainerSizeMl) {
        events.add(
          const StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.invalidValue,
            action: StorageRecoveryActions.fallbackDefaults,
          ),
        );
      }
    }
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
