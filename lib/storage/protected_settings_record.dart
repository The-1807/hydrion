import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/validated_profile_photo.dart';
import 'protected_app_store.dart';

/// Closed, typed I03/I04 payload. Ordinary configuration and photo text cannot
/// enter this record. Consent semantics remain owned by UserSettings.
final class ProtectedProfileFields {
  final bool nonLocalProviderConsentGranted;
  final int dailyGoalMl;
  final String? nickname;
  final int? age;
  final String? sex;
  final String goalMode;
  final String baselineSource;
  final bool weatherModifierEnabled;
  final bool onboardingCompleted;
  final bool missionIntroductionHandled;
  final List<String> recognitionEventIds;
  final bool legalAndHealthAcknowledged;
  final String? acceptedTermsVersion;
  final String? acceptedTermsAt;
  final String? acknowledgedHealthDisclaimerVersion;
  final String? acknowledgedHealthDisclaimerAt;
  final String? privacyPolicyVersionShown;
  final String? privacyPolicyShownAt;
  final bool weatherGoalAutoApplyEnabled;
  final String? lastWeatherGoalDecisionAt;
  final int baselineDailyGoalMl;
  final String? lastWeatherGoalLocalDate;
  final String? lastWeatherGoalExplanation;
  final bool weatherGoalDailyConfirmationEnabled;
  final bool weatherAdjustedGoalActive;
  final String? lastManualGoalEditAt;
  final String? locationPermissionPromptedAt;
  final String? notificationPermissionPromptedAt;
  final int onboardingStep;
  ProtectedProfileFields({
    required this.nonLocalProviderConsentGranted,
    required this.dailyGoalMl,
    required this.nickname,
    required this.age,
    required this.sex,
    required this.goalMode,
    required this.baselineSource,
    required this.weatherModifierEnabled,
    required this.onboardingCompleted,
    required this.missionIntroductionHandled,
    required this.recognitionEventIds,
    required this.legalAndHealthAcknowledged,
    required this.acceptedTermsVersion,
    required this.acceptedTermsAt,
    required this.acknowledgedHealthDisclaimerVersion,
    required this.acknowledgedHealthDisclaimerAt,
    required this.privacyPolicyVersionShown,
    required this.privacyPolicyShownAt,
    required this.weatherGoalAutoApplyEnabled,
    required this.lastWeatherGoalDecisionAt,
    required this.baselineDailyGoalMl,
    required this.lastWeatherGoalLocalDate,
    required this.lastWeatherGoalExplanation,
    required this.weatherGoalDailyConfirmationEnabled,
    required this.weatherAdjustedGoalActive,
    required this.lastManualGoalEditAt,
    required this.locationPermissionPromptedAt,
    required this.notificationPermissionPromptedAt,
    required this.onboardingStep,
  });

  static const fieldNames = {
    'nonLocalProviderConsentGranted',
    'dailyGoalMl',
    'nickname',
    'age',
    'sex',
    'goalMode',
    'baselineSource',
    'weatherModifierEnabled',
    'onboardingCompleted',
    'missionIntroductionHandled',
    'recognitionEventIds',
    'legalAndHealthAcknowledged',
    'acceptedTermsVersion',
    'acceptedTermsAt',
    'acknowledgedHealthDisclaimerVersion',
    'acknowledgedHealthDisclaimerAt',
    'privacyPolicyVersionShown',
    'privacyPolicyShownAt',
    'weatherGoalAutoApplyEnabled',
    'lastWeatherGoalDecisionAt',
    'baselineDailyGoalMl',
    'lastWeatherGoalLocalDate',
    'lastWeatherGoalExplanation',
    'weatherGoalDailyConfirmationEnabled',
    'weatherAdjustedGoalActive',
    'lastManualGoalEditAt',
    'locationPermissionPromptedAt',
    'notificationPermissionPromptedAt',
    'onboardingStep',
  };

  factory ProtectedProfileFields.fromJson(Map<String, dynamic> value) {
    if (value.keys.toSet().difference(fieldNames).isNotEmpty ||
        fieldNames.difference(value.keys.toSet()).isNotEmpty) {
      throw const FormatException('Invalid protected profile fields');
    }
    try {
      return ProtectedProfileFields(
        nonLocalProviderConsentGranted:
            value['nonLocalProviderConsentGranted'] as bool,
        dailyGoalMl: value['dailyGoalMl'] as int,
        nickname: value['nickname'] as String?,
        age: value['age'] as int?,
        sex: value['sex'] as String?,
        goalMode: value['goalMode'] as String,
        baselineSource: value['baselineSource'] as String,
        weatherModifierEnabled: value['weatherModifierEnabled'] as bool,
        onboardingCompleted: value['onboardingCompleted'] as bool,
        missionIntroductionHandled: value['missionIntroductionHandled'] as bool,
        recognitionEventIds: List<String>.unmodifiable(
            (value['recognitionEventIds'] as List).cast<String>()),
        legalAndHealthAcknowledged: value['legalAndHealthAcknowledged'] as bool,
        acceptedTermsVersion: value['acceptedTermsVersion'] as String?,
        acceptedTermsAt: value['acceptedTermsAt'] as String?,
        acknowledgedHealthDisclaimerVersion:
            value['acknowledgedHealthDisclaimerVersion'] as String?,
        acknowledgedHealthDisclaimerAt:
            value['acknowledgedHealthDisclaimerAt'] as String?,
        privacyPolicyVersionShown:
            value['privacyPolicyVersionShown'] as String?,
        privacyPolicyShownAt: value['privacyPolicyShownAt'] as String?,
        weatherGoalAutoApplyEnabled:
            value['weatherGoalAutoApplyEnabled'] as bool,
        lastWeatherGoalDecisionAt:
            value['lastWeatherGoalDecisionAt'] as String?,
        baselineDailyGoalMl: value['baselineDailyGoalMl'] as int,
        lastWeatherGoalLocalDate: value['lastWeatherGoalLocalDate'] as String?,
        lastWeatherGoalExplanation:
            value['lastWeatherGoalExplanation'] as String?,
        weatherGoalDailyConfirmationEnabled:
            value['weatherGoalDailyConfirmationEnabled'] as bool,
        weatherAdjustedGoalActive: value['weatherAdjustedGoalActive'] as bool,
        lastManualGoalEditAt: value['lastManualGoalEditAt'] as String?,
        locationPermissionPromptedAt:
            value['locationPermissionPromptedAt'] as String?,
        notificationPermissionPromptedAt:
            value['notificationPermissionPromptedAt'] as String?,
        onboardingStep: value['onboardingStep'] as int,
      );
    } catch (_) {
      throw const FormatException('Invalid protected profile types');
    }
  }

  Map<String, dynamic> toJson() => {
        'nonLocalProviderConsentGranted': nonLocalProviderConsentGranted,
        'dailyGoalMl': dailyGoalMl,
        'nickname': nickname,
        'age': age,
        'sex': sex,
        'goalMode': goalMode,
        'baselineSource': baselineSource,
        'weatherModifierEnabled': weatherModifierEnabled,
        'onboardingCompleted': onboardingCompleted,
        'missionIntroductionHandled': missionIntroductionHandled,
        'recognitionEventIds': recognitionEventIds,
        'legalAndHealthAcknowledged': legalAndHealthAcknowledged,
        'acceptedTermsVersion': acceptedTermsVersion,
        'acceptedTermsAt': acceptedTermsAt,
        'acknowledgedHealthDisclaimerVersion':
            acknowledgedHealthDisclaimerVersion,
        'acknowledgedHealthDisclaimerAt': acknowledgedHealthDisclaimerAt,
        'privacyPolicyVersionShown': privacyPolicyVersionShown,
        'privacyPolicyShownAt': privacyPolicyShownAt,
        'weatherGoalAutoApplyEnabled': weatherGoalAutoApplyEnabled,
        'lastWeatherGoalDecisionAt': lastWeatherGoalDecisionAt,
        'baselineDailyGoalMl': baselineDailyGoalMl,
        'lastWeatherGoalLocalDate': lastWeatherGoalLocalDate,
        'lastWeatherGoalExplanation': lastWeatherGoalExplanation,
        'weatherGoalDailyConfirmationEnabled':
            weatherGoalDailyConfirmationEnabled,
        'weatherAdjustedGoalActive': weatherAdjustedGoalActive,
        'lastManualGoalEditAt': lastManualGoalEditAt,
        'locationPermissionPromptedAt': locationPermissionPromptedAt,
        'notificationPermissionPromptedAt': notificationPermissionPromptedAt,
        'onboardingStep': onboardingStep,
      };
  String encode() => jsonEncode(toJson());
  @override
  String toString() => 'ProtectedProfileFields';
}

final class ProtectedSettingsRecord {
  static const schemaVersion = 1;
  final int revision;
  final ContextRecordPhase phase;
  final ProtectedProfileFields profile;
  final ValidatedProfilePhoto? photo;
  ProtectedSettingsRecord(
      {required this.revision,
      required this.phase,
      required this.profile,
      this.photo}) {
    if (revision < 1) throw const FormatException('Invalid settings revision');
  }
  bool equivalentTo(ProtectedSettingsRecord other) =>
      revision == other.revision &&
      phase == other.phase &&
      profile.encode() == other.profile.encode() &&
      photo?.width == other.photo?.width &&
      photo?.height == other.photo?.height &&
      listEquals(photo?.bytes, other.photo?.bytes);
  @override
  String toString() => 'ProtectedSettingsRecord(${phase.name})';
}

final class ProtectedSettingsRead {
  final ProtectedReadStatus status;
  final ProtectedSettingsRecord? record;
  const ProtectedSettingsRead(this.status, [this.record]);
  @override
  String toString() => 'ProtectedSettingsRead(${status.name})';
}

abstract interface class ProtectedSettingsStore {
  Future<ProtectedSettingsRead> readSettings();
  Future<ProtectedWriteStatus> writeSettings(ProtectedSettingsRecord record);
}
