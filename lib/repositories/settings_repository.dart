import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/avatar_manifest.dart';
import '../domain/legal_document_registry.dart';
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

enum HydrionThemePreference {
  system,
  automatic,
  light,
  dark,
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
  static const maxProfilePhotoBase64Length = 1600000;
  static const maxOnboardingStep = 7;

  final Locale locale;
  final bool nonLocalProviderConsentGranted;
  final int dailyGoalMl;
  final bool reusableContainerEnabled;
  final String? nickname;
  final String? profilePhotoBase64;
  final int? age;
  final HydrionSex? sex;
  final String avatarId;
  final HydrionGoalMode goalMode;
  final HydrionVolumeUnit volumeUnit;
  final HydrionThemePreference themePreference;
  final int containerSizeMl;

  int? get usableContainerSizeMl =>
      reusableContainerEnabled ? containerSizeMl : null;
  final bool onboardingCompleted;
  final bool legalAndHealthAcknowledged;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;
  final String? acknowledgedHealthDisclaimerVersion;
  final DateTime? acknowledgedHealthDisclaimerAt;
  final String? privacyPolicyVersionShown;
  final DateTime? privacyPolicyShownAt;
  final bool weatherGoalAutoApplyEnabled;
  final DateTime? lastWeatherGoalDecisionAt;
  final int baselineDailyGoalMl;
  final String? lastWeatherGoalLocalDate;
  final String? lastWeatherGoalExplanation;
  final bool weatherGoalDailyConfirmationEnabled;
  final bool weatherAdjustedGoalActive;
  final DateTime? lastManualGoalEditAt;
  final DateTime? locationPermissionPromptedAt;
  final DateTime? notificationPermissionPromptedAt;
  final int onboardingStep;

  const UserSettings({
    required this.locale,
    this.nonLocalProviderConsentGranted = false,
    this.dailyGoalMl = defaultDailyGoalMl,
    this.reusableContainerEnabled = false,
    this.nickname,
    this.profilePhotoBase64,
    this.age,
    this.sex,
    this.avatarId = 'savvy-eco_shark',
    this.goalMode = HydrionGoalMode.manual,
    this.volumeUnit = HydrionVolumeUnit.milliliters,
    this.themePreference = HydrionThemePreference.system,
    this.containerSizeMl = defaultContainerSizeMl,
    this.onboardingCompleted = false,
    this.legalAndHealthAcknowledged = false,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
    this.acknowledgedHealthDisclaimerVersion,
    this.acknowledgedHealthDisclaimerAt,
    this.privacyPolicyVersionShown,
    this.privacyPolicyShownAt,
    this.weatherGoalAutoApplyEnabled = false,
    this.lastWeatherGoalDecisionAt,
    this.baselineDailyGoalMl = defaultDailyGoalMl,
    this.lastWeatherGoalLocalDate,
    this.lastWeatherGoalExplanation,
    this.weatherGoalDailyConfirmationEnabled = true,
    this.weatherAdjustedGoalActive = false,
    this.lastManualGoalEditAt,
    this.locationPermissionPromptedAt,
    this.notificationPermissionPromptedAt,
    this.onboardingStep = 0,
  });

  UserSettings copyWith({
    Locale? locale,
    bool? nonLocalProviderConsentGranted,
    int? dailyGoalMl,
    bool? reusableContainerEnabled,
    String? nickname,
    bool clearNickname = false,
    String? profilePhotoBase64,
    bool clearProfilePhotoBase64 = false,
    int? age,
    bool clearAge = false,
    HydrionSex? sex,
    bool clearSex = false,
    String? avatarId,
    HydrionGoalMode? goalMode,
    HydrionVolumeUnit? volumeUnit,
    HydrionThemePreference? themePreference,
    int? containerSizeMl,
    bool? onboardingCompleted,
    bool? legalAndHealthAcknowledged,
    String? acceptedTermsVersion,
    bool clearAcceptedTermsVersion = false,
    DateTime? acceptedTermsAt,
    bool clearAcceptedTermsAt = false,
    String? acknowledgedHealthDisclaimerVersion,
    bool clearAcknowledgedHealthDisclaimerVersion = false,
    DateTime? acknowledgedHealthDisclaimerAt,
    bool clearAcknowledgedHealthDisclaimerAt = false,
    String? privacyPolicyVersionShown,
    bool clearPrivacyPolicyVersionShown = false,
    DateTime? privacyPolicyShownAt,
    bool clearPrivacyPolicyShownAt = false,
    bool? weatherGoalAutoApplyEnabled,
    DateTime? lastWeatherGoalDecisionAt,
    bool clearLastWeatherGoalDecisionAt = false,
    int? baselineDailyGoalMl,
    String? lastWeatherGoalLocalDate,
    bool clearLastWeatherGoalLocalDate = false,
    String? lastWeatherGoalExplanation,
    bool clearLastWeatherGoalExplanation = false,
    bool? weatherGoalDailyConfirmationEnabled,
    bool? weatherAdjustedGoalActive,
    DateTime? lastManualGoalEditAt,
    bool clearLastManualGoalEditAt = false,
    DateTime? locationPermissionPromptedAt,
    bool clearLocationPermissionPromptedAt = false,
    DateTime? notificationPermissionPromptedAt,
    bool clearNotificationPermissionPromptedAt = false,
    int? onboardingStep,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      nonLocalProviderConsentGranted:
          nonLocalProviderConsentGranted ?? this.nonLocalProviderConsentGranted,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      reusableContainerEnabled:
          reusableContainerEnabled ?? this.reusableContainerEnabled,
      nickname: clearNickname ? null : nickname ?? this.nickname,
      profilePhotoBase64: clearProfilePhotoBase64
          ? null
          : profilePhotoBase64 ?? this.profilePhotoBase64,
      age: clearAge ? null : age ?? this.age,
      sex: clearSex ? null : sex ?? this.sex,
      avatarId: avatarId ?? this.avatarId,
      goalMode: goalMode ?? this.goalMode,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      themePreference: themePreference ?? this.themePreference,
      containerSizeMl: containerSizeMl ?? this.containerSizeMl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      legalAndHealthAcknowledged:
          legalAndHealthAcknowledged ?? this.legalAndHealthAcknowledged,
      acceptedTermsVersion: clearAcceptedTermsVersion
          ? null
          : acceptedTermsVersion ?? this.acceptedTermsVersion,
      acceptedTermsAt:
          clearAcceptedTermsAt ? null : acceptedTermsAt ?? this.acceptedTermsAt,
      acknowledgedHealthDisclaimerVersion:
          clearAcknowledgedHealthDisclaimerVersion
              ? null
              : acknowledgedHealthDisclaimerVersion ??
                  this.acknowledgedHealthDisclaimerVersion,
      acknowledgedHealthDisclaimerAt: clearAcknowledgedHealthDisclaimerAt
          ? null
          : acknowledgedHealthDisclaimerAt ??
              this.acknowledgedHealthDisclaimerAt,
      privacyPolicyVersionShown: clearPrivacyPolicyVersionShown
          ? null
          : privacyPolicyVersionShown ?? this.privacyPolicyVersionShown,
      privacyPolicyShownAt: clearPrivacyPolicyShownAt
          ? null
          : privacyPolicyShownAt ?? this.privacyPolicyShownAt,
      weatherGoalAutoApplyEnabled:
          weatherGoalAutoApplyEnabled ?? this.weatherGoalAutoApplyEnabled,
      lastWeatherGoalDecisionAt: clearLastWeatherGoalDecisionAt
          ? null
          : lastWeatherGoalDecisionAt ?? this.lastWeatherGoalDecisionAt,
      baselineDailyGoalMl: baselineDailyGoalMl ?? this.baselineDailyGoalMl,
      lastWeatherGoalLocalDate: clearLastWeatherGoalLocalDate
          ? null
          : lastWeatherGoalLocalDate ?? this.lastWeatherGoalLocalDate,
      lastWeatherGoalExplanation: clearLastWeatherGoalExplanation
          ? null
          : lastWeatherGoalExplanation ?? this.lastWeatherGoalExplanation,
      weatherGoalDailyConfirmationEnabled:
          weatherGoalDailyConfirmationEnabled ??
              this.weatherGoalDailyConfirmationEnabled,
      weatherAdjustedGoalActive:
          weatherAdjustedGoalActive ?? this.weatherAdjustedGoalActive,
      lastManualGoalEditAt: clearLastManualGoalEditAt
          ? null
          : lastManualGoalEditAt ?? this.lastManualGoalEditAt,
      locationPermissionPromptedAt: clearLocationPermissionPromptedAt
          ? null
          : locationPermissionPromptedAt ?? this.locationPermissionPromptedAt,
      notificationPermissionPromptedAt: clearNotificationPermissionPromptedAt
          ? null
          : notificationPermissionPromptedAt ??
              this.notificationPermissionPromptedAt,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }

  bool get hasProfileName => nickname != null && nickname!.trim().isNotEmpty;

  bool get hasCurrentLegalReview {
    return HydrionLegalAcceptancePolicy.hasCurrentTermsAcceptance(
          acceptedTermsVersion,
        ) &&
        HydrionLegalAcceptancePolicy.hasCurrentHealthAcknowledgement(
          acknowledgedHealthDisclaimerVersion,
        );
  }

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
      'profilePhotoBase64': profilePhotoBase64,
      'age': age,
      'sex': sex?.name,
      'avatarId': avatarId,
      'goalMode': goalMode.name,
      'volumeUnit': volumeUnit.name,
      'themePreference': themePreference.name,
      'containerSizeMl': containerSizeMl,
      'onboardingCompleted': onboardingCompleted,
      'legalAndHealthAcknowledged': legalAndHealthAcknowledged,
      'acceptedTermsVersion': acceptedTermsVersion,
      'acceptedTermsAt': acceptedTermsAt?.toIso8601String(),
      'acknowledgedHealthDisclaimerVersion':
          acknowledgedHealthDisclaimerVersion,
      'acknowledgedHealthDisclaimerAt':
          acknowledgedHealthDisclaimerAt?.toIso8601String(),
      'privacyPolicyVersionShown': privacyPolicyVersionShown,
      'privacyPolicyShownAt': privacyPolicyShownAt?.toIso8601String(),
      'weatherGoalAutoApplyEnabled': weatherGoalAutoApplyEnabled,
      'lastWeatherGoalDecisionAt': lastWeatherGoalDecisionAt?.toIso8601String(),
      'baselineDailyGoalMl': baselineDailyGoalMl,
      'lastWeatherGoalLocalDate': lastWeatherGoalLocalDate,
      'lastWeatherGoalExplanation': lastWeatherGoalExplanation,
      'weatherGoalDailyConfirmationEnabled':
          weatherGoalDailyConfirmationEnabled,
      'weatherAdjustedGoalActive': weatherAdjustedGoalActive,
      'lastManualGoalEditAt': lastManualGoalEditAt?.toIso8601String(),
      'locationPermissionPromptedAt':
          locationPermissionPromptedAt?.toIso8601String(),
      'notificationPermissionPromptedAt':
          notificationPermissionPromptedAt?.toIso8601String(),
      'onboardingStep': onboardingStep,
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
        profilePhotoBase64:
            _safeProfilePhotoBase64(value['profilePhotoBase64']),
        age: _safeAge(value['age']),
        sex: _safeSex(value['sex']),
        avatarId: _safeAvatarId(value['avatarId']),
        goalMode: _safeGoalMode(value['goalMode']),
        volumeUnit: _safeVolumeUnit(value['volumeUnit']),
        themePreference: _safeThemePreference(value['themePreference']),
        containerSizeMl: _safeContainerSize(value['containerSizeMl']),
        onboardingCompleted: _safeOnboardingCompleted(value),
        legalAndHealthAcknowledged: value['legalAndHealthAcknowledged'] == true,
        acceptedTermsVersion: _safeLegalVersion(value['acceptedTermsVersion']),
        acceptedTermsAt: _safeDateTime(value['acceptedTermsAt']),
        acknowledgedHealthDisclaimerVersion:
            _safeLegalVersion(value['acknowledgedHealthDisclaimerVersion']),
        acknowledgedHealthDisclaimerAt:
            _safeDateTime(value['acknowledgedHealthDisclaimerAt']),
        privacyPolicyVersionShown:
            _safeLegalVersion(value['privacyPolicyVersionShown']),
        privacyPolicyShownAt: _safeDateTime(value['privacyPolicyShownAt']),
        weatherGoalAutoApplyEnabled:
            value['weatherGoalAutoApplyEnabled'] == true,
        lastWeatherGoalDecisionAt:
            _safeDateTime(value['lastWeatherGoalDecisionAt']),
        baselineDailyGoalMl: _safeBaselineGoal(value),
        lastWeatherGoalLocalDate:
            _safeLocalDateKey(value['lastWeatherGoalLocalDate']),
        lastWeatherGoalExplanation:
            _safeShortText(value['lastWeatherGoalExplanation'], 360),
        weatherGoalDailyConfirmationEnabled:
            value['weatherGoalDailyConfirmationEnabled'] != false,
        weatherAdjustedGoalActive: value['weatherAdjustedGoalActive'] == true,
        lastManualGoalEditAt: _safeDateTime(value['lastManualGoalEditAt']),
        locationPermissionPromptedAt:
            _safeDateTime(value['locationPermissionPromptedAt']),
        notificationPermissionPromptedAt:
            _safeDateTime(value['notificationPermissionPromptedAt']),
        onboardingStep: _safeOnboardingStep(value),
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
      profilePhotoBase64: _safeProfilePhotoBase64(value['profilePhotoBase64']),
      age: _safeAge(value['age']),
      sex: _safeSex(value['sex']),
      avatarId: _safeAvatarId(value['avatarId']),
      goalMode: _safeGoalMode(value['goalMode']),
      volumeUnit: _safeVolumeUnit(value['volumeUnit']),
      themePreference: _safeThemePreference(value['themePreference']),
      containerSizeMl: _safeContainerSize(value['containerSizeMl']),
      onboardingCompleted: _safeOnboardingCompleted(value),
      legalAndHealthAcknowledged: value['legalAndHealthAcknowledged'] == true,
      acceptedTermsVersion: _safeLegalVersion(value['acceptedTermsVersion']),
      acceptedTermsAt: _safeDateTime(value['acceptedTermsAt']),
      acknowledgedHealthDisclaimerVersion:
          _safeLegalVersion(value['acknowledgedHealthDisclaimerVersion']),
      acknowledgedHealthDisclaimerAt:
          _safeDateTime(value['acknowledgedHealthDisclaimerAt']),
      privacyPolicyVersionShown:
          _safeLegalVersion(value['privacyPolicyVersionShown']),
      privacyPolicyShownAt: _safeDateTime(value['privacyPolicyShownAt']),
      weatherGoalAutoApplyEnabled: value['weatherGoalAutoApplyEnabled'] == true,
      lastWeatherGoalDecisionAt:
          _safeDateTime(value['lastWeatherGoalDecisionAt']),
      baselineDailyGoalMl: _safeBaselineGoal(value),
      lastWeatherGoalLocalDate:
          _safeLocalDateKey(value['lastWeatherGoalLocalDate']),
      lastWeatherGoalExplanation:
          _safeShortText(value['lastWeatherGoalExplanation'], 360),
      weatherGoalDailyConfirmationEnabled:
          value['weatherGoalDailyConfirmationEnabled'] != false,
      weatherAdjustedGoalActive: value['weatherAdjustedGoalActive'] == true,
      lastManualGoalEditAt: _safeDateTime(value['lastManualGoalEditAt']),
      locationPermissionPromptedAt:
          _safeDateTime(value['locationPermissionPromptedAt']),
      notificationPermissionPromptedAt:
          _safeDateTime(value['notificationPermissionPromptedAt']),
      onboardingStep: _safeOnboardingStep(value),
    );
  }

  static bool _safeOnboardingCompleted(Map value) {
    final completed = value['onboardingCompleted'];
    if (completed is bool) {
      return completed;
    }
    if (value.containsKey('onboardingStep')) {
      return false;
    }
    return _hasLegacyCompletedUserEvidence(value);
  }

  static bool _hasLegacyCompletedUserEvidence(Map value) {
    if (value['legalAndHealthAcknowledged'] == true) {
      return true;
    }
    final hasProfile = _safeNickname(value['nickname']) != null;
    final dailyGoal = value['dailyGoalMl'];
    final hasValidGoal = dailyGoal is num &&
        dailyGoal.isFinite &&
        dailyGoal.round() >= minDailyGoalMl &&
        dailyGoal.round() <= maxDailyGoalMl;
    return hasProfile && hasValidGoal;
  }

  static int _safeOnboardingStep(Map value) {
    if (_safeOnboardingCompleted(value)) {
      return 0;
    }
    final step = value['onboardingStep'];
    if (step is! num || !step.isFinite) {
      return 0;
    }
    return step.round().clamp(0, maxOnboardingStep).toInt();
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

  static int _safeBaselineGoal(Map value) {
    if (value.containsKey('baselineDailyGoalMl')) {
      return _safeDailyGoal(value['baselineDailyGoalMl']);
    }
    return _safeDailyGoal(value['dailyGoalMl']);
  }

  static String? _safeLocalDateKey(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  static String? _safeShortText(Object? value, int maxLength) {
    if (value is! String) {
      return null;
    }
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || text.length > maxLength) {
      return null;
    }
    return text;
  }

  static String? _safeLegalVersion(Object? value) {
    if (value is! String) {
      return null;
    }
    final version = value.trim();
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      return null;
    }
    return version;
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

  static String? _safeProfilePhotoBase64(Object? value) {
    if (value is! String) {
      return null;
    }
    final photo = value.trim();
    if (photo.isEmpty || photo.length > maxProfilePhotoBase64Length) {
      return null;
    }
    if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(photo)) {
      return null;
    }
    return photo;
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
    if (HydrionAvatarManifest.isRemovedHumanAvatarId(id)) {
      return HydrionAvatarManifest.defaultAvatarId;
    }
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

  static HydrionThemePreference _safeThemePreference(Object? value) {
    for (final preference in HydrionThemePreference.values) {
      if (preference.name == value) {
        return preference;
      }
    }
    return HydrionThemePreference.system;
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
            baselineDailyGoalMl: dailyGoalMl,
            reusableContainerEnabled: reusableContainerEnabled,
            onboardingCompleted: onboardingCompleted,
            legalAndHealthAcknowledged: onboardingCompleted,
            acceptedTermsVersion: onboardingCompleted
                ? HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion
                : null,
            acceptedTermsAt:
                onboardingCompleted ? DateTime(2026, 7, 6, 12) : null,
            acknowledgedHealthDisclaimerVersion: onboardingCompleted
                ? HydrionLegalAcceptancePolicy
                    .requiredHealthAcknowledgementVersion
                : null,
            acknowledgedHealthDisclaimerAt:
                onboardingCompleted ? DateTime(2026, 7, 6, 12) : null,
            privacyPolicyVersionShown: onboardingCompleted
                ? HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion
                : null,
            privacyPolicyShownAt:
                onboardingCompleted ? DateTime(2026, 7, 6, 12) : null,
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

  Future<void> refreshFromStore() async {
    final raw = await _store.readString(storageKey);
    _settings = _decodeSettings(raw).settings;
    notifyListeners();
  }

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

  Future<bool> setDailyGoalMl(
    int value, {
    bool updateBaseline = true,
    bool markManualEdit = true,
    DateTime? now,
  }) async {
    if (value < UserSettings.minDailyGoalMl ||
        value > UserSettings.maxDailyGoalMl) {
      return false;
    }
    _settings = _settings.copyWith(
      dailyGoalMl: value,
      baselineDailyGoalMl:
          updateBaseline ? value : _settings.baselineDailyGoalMl,
      weatherAdjustedGoalActive:
          updateBaseline ? false : _settings.weatherAdjustedGoalActive,
      lastManualGoalEditAt: markManualEdit ? now ?? DateTime.now() : null,
      clearLastManualGoalEditAt: !markManualEdit,
    );
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

  Future<bool> setProfilePhotoBase64(String value) async {
    final safePhoto = UserSettings._safeProfilePhotoBase64(value);
    if (safePhoto == null) {
      return false;
    }
    _settings = _settings.copyWith(profilePhotoBase64: safePhoto);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> clearProfilePhoto() async {
    _settings = _settings.copyWith(clearProfilePhotoBase64: true);
    await _persist();
    notifyListeners();
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

  Future<void> setThemePreference(HydrionThemePreference preference) async {
    _settings = _settings.copyWith(themePreference: preference);
    await _persist();
    notifyListeners();
  }

  Future<bool> setContainerSizeMl(int value) async {
    if (value < UserSettings.minContainerSizeMl ||
        value > UserSettings.maxContainerSizeMl) {
      return false;
    }
    _settings = _settings.copyWith(
      containerSizeMl: value,
      reusableContainerEnabled: true,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> clearContainerSize() async {
    _settings = _settings.copyWith(reusableContainerEnabled: false);
    await _persist();
    notifyListeners();
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

  Future<bool> applyWeatherGoal({
    required int goalMl,
    required DateTime decidedAt,
    required String explanation,
    required String localDateKey,
    bool autoApplyEnabled = false,
  }) async {
    if (goalMl < UserSettings.minDailyGoalMl ||
        goalMl > UserSettings.maxDailyGoalMl) {
      return false;
    }
    _settings = _settings.copyWith(
      dailyGoalMl: goalMl,
      lastWeatherGoalDecisionAt: decidedAt,
      lastWeatherGoalLocalDate: localDateKey,
      lastWeatherGoalExplanation: explanation,
      weatherAdjustedGoalActive: true,
      weatherGoalAutoApplyEnabled: autoApplyEnabled,
      clearLastManualGoalEditAt: true,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> keepPreviousWeatherGoal({
    required DateTime decidedAt,
    required String localDateKey,
    required String explanation,
  }) async {
    _settings = _settings.copyWith(
      lastWeatherGoalDecisionAt: decidedAt,
      lastWeatherGoalLocalDate: localDateKey,
      lastWeatherGoalExplanation: explanation,
      weatherAdjustedGoalActive: false,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setWeatherGoalDailyConfirmationEnabled(bool value) async {
    _settings = _settings.copyWith(
      weatherGoalDailyConfirmationEnabled: value,
      weatherGoalAutoApplyEnabled: !value,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> recordLocationPermissionPrompt(DateTime value) async {
    _settings = _settings.copyWith(locationPermissionPromptedAt: value);
    await _persist();
    notifyListeners();
  }

  Future<void> recordNotificationPermissionPrompt(DateTime value) async {
    _settings = _settings.copyWith(notificationPermissionPromptedAt: value);
    await _persist();
    notifyListeners();
  }

  Future<void> setOnboardingCompleted({
    required bool completed,
    required bool legalAndHealthAcknowledged,
  }) async {
    final shouldRecordCurrentLegal = completed && legalAndHealthAcknowledged;
    final now = shouldRecordCurrentLegal ? DateTime.now() : null;
    _settings = _settings.copyWith(
      onboardingCompleted: completed,
      legalAndHealthAcknowledged: legalAndHealthAcknowledged,
      acceptedTermsVersion: shouldRecordCurrentLegal
          ? _settings.acceptedTermsVersion ??
              HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion
          : null,
      clearAcceptedTermsVersion: !shouldRecordCurrentLegal,
      acceptedTermsAt:
          shouldRecordCurrentLegal ? _settings.acceptedTermsAt ?? now : null,
      clearAcceptedTermsAt: !shouldRecordCurrentLegal,
      acknowledgedHealthDisclaimerVersion: shouldRecordCurrentLegal
          ? _settings.acknowledgedHealthDisclaimerVersion ??
              HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion
          : null,
      clearAcknowledgedHealthDisclaimerVersion: !shouldRecordCurrentLegal,
      acknowledgedHealthDisclaimerAt: shouldRecordCurrentLegal
          ? _settings.acknowledgedHealthDisclaimerAt ?? now
          : null,
      clearAcknowledgedHealthDisclaimerAt: !shouldRecordCurrentLegal,
      privacyPolicyVersionShown: shouldRecordCurrentLegal
          ? _settings.privacyPolicyVersionShown ??
              HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion
          : null,
      clearPrivacyPolicyVersionShown: !shouldRecordCurrentLegal,
      privacyPolicyShownAt: shouldRecordCurrentLegal
          ? _settings.privacyPolicyShownAt ?? now
          : null,
      clearPrivacyPolicyShownAt: !shouldRecordCurrentLegal,
      onboardingStep: completed ? 0 : _settings.onboardingStep,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setOnboardingStep(int step) async {
    final safeStep = step.clamp(0, UserSettings.maxOnboardingStep).toInt();
    if (_settings.onboardingStep == safeStep) {
      return;
    }
    _settings = _settings.copyWith(onboardingStep: safeStep);
    await _persist();
    notifyListeners();
  }

  Future<void> completeOnboardingWithLegalReview({
    required DateTime reviewedAt,
  }) async {
    _settings = _settings.copyWith(
      onboardingCompleted: true,
      legalAndHealthAcknowledged: true,
      acceptedTermsVersion:
          HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
      acceptedTermsAt: reviewedAt,
      acknowledgedHealthDisclaimerVersion:
          HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
      acknowledgedHealthDisclaimerAt: reviewedAt,
      privacyPolicyVersionShown:
          HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion,
      privacyPolicyShownAt: reviewedAt,
      onboardingStep: 0,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> recordLegalReview({
    DateTime? reviewedAt,
    String? termsVersion,
    String? healthDisclaimerVersion,
    String? privacyPolicyVersion,
  }) async {
    final timestamp = reviewedAt ?? DateTime.now();
    _settings = _settings.copyWith(
      legalAndHealthAcknowledged: true,
      acceptedTermsVersion: termsVersion ??
          HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
      acceptedTermsAt: timestamp,
      acknowledgedHealthDisclaimerVersion: healthDisclaimerVersion ??
          HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
      acknowledgedHealthDisclaimerAt: timestamp,
      privacyPolicyVersionShown: privacyPolicyVersion ??
          HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion,
      privacyPolicyShownAt: timestamp,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> reopenOnboarding() async {
    _settings = _settings.copyWith(
      onboardingCompleted: false,
      onboardingStep: 0,
    );
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
    if (value.containsKey('profilePhotoBase64') &&
        UserSettings._safeProfilePhotoBase64(value['profilePhotoBase64']) ==
            null) {
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
