import 'package:flutter/foundation.dart';

class HydrationSummary {
  final double hydrationPercent;
  final int entryCount;
  final int consumedMl;
  final int targetMl;

  const HydrationSummary({
    required this.hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required this.consumedMl,
    required this.targetMl,
  }) : entryCount = entryCount ?? activityMinutes ?? 0;

  @Deprecated('Use entryCount; Hydrion does not read platform activity data.')
  int get activityMinutes => entryCount;
}

class HydrationChallenge {
  final String id;
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;

  const HydrationChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
  });
}

enum HydrionCapability {
  localPersistence,
  elka,
  gemini,
  cloudAi,
  cloudSync,
  voiceInput,
  bleSync,
  healthSync,
  osNotifications,
  arVisualization,
  socialSync,
}

enum HydrationCoachDigestKey {
  weeklyDigest,
  reminderNudge,
  sentimentAnalysis,
  commandParsing,
}

enum HydrionAiProviderKind {
  localRules,
  gemini,
  elka,
}

class ExternalIntegrationActivation {
  final bool configured;
  final bool enabledByUser;
  final bool disclosureVisible;
  final bool consentGranted;
  final bool localFallbackAvailable;

  const ExternalIntegrationActivation({
    required this.configured,
    required this.enabledByUser,
    required this.disclosureVisible,
    required this.consentGranted,
    this.localFallbackAvailable = true,
  });

  const ExternalIntegrationActivation.disabled()
      : configured = false,
        enabledByUser = false,
        disclosureVisible = false,
        consentGranted = false,
        localFallbackAvailable = true;

  bool get canTransmit =>
      configured &&
      enabledByUser &&
      disclosureVisible &&
      consentGranted &&
      localFallbackAvailable;

  bool get canReportActive => canTransmit;
}

class AppCapabilities {
  final bool localPersistence;
  final bool elkaConfigured;
  final bool geminiConfigured;
  final bool cloudAi;
  final bool cloudSync;
  final bool voiceInput;
  final bool bleSync;
  final bool healthSync;
  final bool osNotifications;
  final bool arVisualization;
  final bool socialSync;

  const AppCapabilities({
    required this.localPersistence,
    required this.elkaConfigured,
    this.geminiConfigured = false,
    required this.cloudAi,
    this.cloudSync = false,
    required this.voiceInput,
    required this.bleSync,
    required this.healthSync,
    required this.osNotifications,
    required this.arVisualization,
    required this.socialSync,
  });

  const AppCapabilities.standalone()
      : localPersistence = true,
        elkaConfigured = false,
        geminiConfigured = false,
        cloudAi = false,
        cloudSync = false,
        voiceInput = false,
        bleSync = false,
        healthSync = false,
        osNotifications = false,
        arVisualization = false,
        socialSync = false;

  AppCapabilities copyWith({
    bool? localPersistence,
    bool? elkaConfigured,
    bool? geminiConfigured,
    bool? cloudAi,
    bool? cloudSync,
    bool? voiceInput,
    bool? bleSync,
    bool? healthSync,
    bool? osNotifications,
    bool? arVisualization,
    bool? socialSync,
  }) {
    return AppCapabilities(
      localPersistence: localPersistence ?? this.localPersistence,
      elkaConfigured: elkaConfigured ?? this.elkaConfigured,
      geminiConfigured: geminiConfigured ?? this.geminiConfigured,
      cloudAi: cloudAi ?? this.cloudAi,
      cloudSync: cloudSync ?? this.cloudSync,
      voiceInput: voiceInput ?? this.voiceInput,
      bleSync: bleSync ?? this.bleSync,
      healthSync: healthSync ?? this.healthSync,
      osNotifications: osNotifications ?? this.osNotifications,
      arVisualization: arVisualization ?? this.arVisualization,
      socialSync: socialSync ?? this.socialSync,
    );
  }

  String get modeLabel => elkaConfigured
      ? 'ELKA adapter configured'
      : geminiConfigured
          ? 'Gemini provider configured'
          : 'Standalone local mode';
}

class DailyHydrationSummary {
  final DateTime date;
  final int consumedMl;
  final int targetMl;
  final int entryCount;

  const DailyHydrationSummary({
    required this.date,
    required this.consumedMl,
    required this.targetMl,
    required this.entryCount,
  });

  double get hydrationPercent {
    if (targetMl <= 0) {
      return 0;
    }
    return (consumedMl / targetMl * 100).clamp(0.0, 100.0);
  }
}

class ReminderContext {
  final int savedReminderCount;
  final DateTime? nextReminderAt;
  final bool osNotificationsAvailable;

  const ReminderContext({
    required this.savedReminderCount,
    required this.nextReminderAt,
    required this.osNotificationsAvailable,
  });

  const ReminderContext.empty({this.osNotificationsAvailable = false})
      : savedReminderCount = 0,
        nextReminderAt = null;
}

class ChallengeContext {
  final bool hasActiveChallenge;
  final String? activeChallengeId;
  final String? activeChallengeName;
  final int targetMl;
  final int durationDays;
  final int completedDays;
  final int todayMl;

  const ChallengeContext({
    required this.hasActiveChallenge,
    required this.activeChallengeId,
    required this.activeChallengeName,
    required this.targetMl,
    required this.durationDays,
    required this.completedDays,
    required this.todayMl,
  });

  const ChallengeContext.none()
      : hasActiveChallenge = false,
        activeChallengeId = null,
        activeChallengeName = null,
        targetMl = 0,
        durationDays = 0,
        completedDays = 0,
        todayMl = 0;

  double get progressPercent {
    if (durationDays <= 0) {
      return 0;
    }
    return (completedDays / durationDays * 100).clamp(0.0, 100.0);
  }
}

class CapabilityContext {
  final bool localPersistence;
  final bool elkaConfigured;
  final bool geminiConfigured;
  final bool cloudAi;
  final bool cloudSync;
  final bool voiceInput;
  final bool bleSync;
  final bool healthSync;
  final bool osNotifications;
  final bool arVisualization;
  final bool socialSync;

  const CapabilityContext({
    required this.localPersistence,
    required this.elkaConfigured,
    required this.geminiConfigured,
    required this.cloudAi,
    required this.cloudSync,
    required this.voiceInput,
    required this.bleSync,
    required this.healthSync,
    required this.osNotifications,
    required this.arVisualization,
    required this.socialSync,
  });

  const CapabilityContext.standalone()
      : localPersistence = true,
        elkaConfigured = false,
        geminiConfigured = false,
        cloudAi = false,
        cloudSync = false,
        voiceInput = false,
        bleSync = false,
        healthSync = false,
        osNotifications = false,
        arVisualization = false,
        socialSync = false;

  factory CapabilityContext.fromAppCapabilities(AppCapabilities capabilities) {
    return CapabilityContext(
      localPersistence: capabilities.localPersistence,
      elkaConfigured: capabilities.elkaConfigured,
      geminiConfigured: capabilities.geminiConfigured,
      cloudAi: capabilities.cloudAi,
      cloudSync: capabilities.cloudSync,
      voiceInput: capabilities.voiceInput,
      bleSync: capabilities.bleSync,
      healthSync: capabilities.healthSync,
      osNotifications: capabilities.osNotifications,
      arVisualization: capabilities.arVisualization,
      socialSync: capabilities.socialSync,
    );
  }

  bool isAvailable(HydrionCapability capability) {
    return switch (capability) {
      HydrionCapability.localPersistence => localPersistence,
      HydrionCapability.elka => elkaConfigured,
      HydrionCapability.gemini => geminiConfigured,
      HydrionCapability.cloudAi => cloudAi,
      HydrionCapability.cloudSync => cloudSync,
      HydrionCapability.voiceInput => voiceInput,
      HydrionCapability.bleSync => bleSync,
      HydrionCapability.healthSync => healthSync,
      HydrionCapability.osNotifications => osNotifications,
      HydrionCapability.arVisualization => arVisualization,
      HydrionCapability.socialSync => socialSync,
    };
  }
}

class HydrationContext {
  final DailyHydrationSummary dailySummary;
  final int lifetimeMl;
  final int eventCount;
  final ReminderContext reminder;
  final ChallengeContext challenge;
  final CapabilityContext capabilities;

  const HydrationContext({
    required this.dailySummary,
    required this.lifetimeMl,
    required this.eventCount,
    required this.reminder,
    required this.challenge,
    required this.capabilities,
  });
}

enum HydrationAiActionType {
  coachMessage,
  suggestReminder,
  suggestHydrationLog,
  explainTrend,
  suggestChallenge,
  unsupportedCapabilityNotice,
}

abstract class HydrationAiAction {
  final String message;
  final Set<HydrionCapability> requiredCapabilities;

  const HydrationAiAction({
    required this.message,
    this.requiredCapabilities = const <HydrionCapability>{},
  });

  HydrationAiActionType get type;

  bool get changesAppState => false;

  bool get requiresUserConfirmation => changesAppState;
}

class CoachMessageAction extends HydrationAiAction {
  const CoachMessageAction({
    required super.message,
    super.requiredCapabilities,
  });

  @override
  HydrationAiActionType get type => HydrationAiActionType.coachMessage;
}

class SuggestReminderAction extends HydrationAiAction {
  final Duration delay;
  final int priority;
  final bool claimsOsNotificationScheduled;

  const SuggestReminderAction({
    required super.message,
    required this.delay,
    this.priority = 1,
    this.claimsOsNotificationScheduled = false,
    super.requiredCapabilities,
  });

  @override
  HydrationAiActionType get type => HydrationAiActionType.suggestReminder;

  @override
  bool get changesAppState => true;
}

class SuggestHydrationLogAction extends HydrationAiAction {
  final int volumeMl;
  final String source;

  const SuggestHydrationLogAction({
    required super.message,
    required this.volumeMl,
    this.source = 'provider_suggestion',
    super.requiredCapabilities,
  });

  @override
  HydrationAiActionType get type => HydrationAiActionType.suggestHydrationLog;

  @override
  bool get changesAppState => true;
}

class ExplainTrendAction extends HydrationAiAction {
  const ExplainTrendAction({
    required super.message,
    super.requiredCapabilities,
  });

  @override
  HydrationAiActionType get type => HydrationAiActionType.explainTrend;
}

class SuggestChallengeAction extends HydrationAiAction {
  final String challengeId;
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;
  final bool claimsSocialSync;

  const SuggestChallengeAction({
    required super.message,
    required this.challengeId,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
    this.claimsSocialSync = false,
    super.requiredCapabilities,
  });

  @override
  HydrationAiActionType get type => HydrationAiActionType.suggestChallenge;

  @override
  bool get changesAppState => true;
}

class UnsupportedCapabilityNoticeAction extends HydrationAiAction {
  final HydrionCapability? capability;

  const UnsupportedCapabilityNoticeAction({
    required super.message,
    this.capability,
  });

  @override
  HydrationAiActionType get type =>
      HydrationAiActionType.unsupportedCapabilityNotice;
}

class HydrationAiActionValidationResult {
  final HydrationAiAction originalAction;
  final HydrationAiAction action;
  final bool isAllowed;
  final List<HydrionCapability> blockedCapabilities;
  final String reason;

  const HydrationAiActionValidationResult({
    required this.originalAction,
    required this.action,
    required this.isAllowed,
    required this.blockedCapabilities,
    required this.reason,
  });

  bool canExecute({required bool userConfirmed}) {
    if (!isAllowed) {
      return false;
    }
    if (!action.requiresUserConfirmation) {
      return true;
    }
    return userConfirmed;
  }
}

enum HydrationAiActionExecutionStatus {
  applied,
  displayOnly,
  rejected,
}

class HydrationAiActionExecutionResult {
  final HydrationAiAction originalAction;
  final HydrationAiActionValidationResult validationResult;
  final HydrationAiActionExecutionStatus status;
  final String message;
  final String? appliedEntityId;

  const HydrationAiActionExecutionResult({
    required this.originalAction,
    required this.validationResult,
    required this.status,
    required this.message,
    this.appliedEntityId,
  });

  bool get isApplied => status == HydrationAiActionExecutionStatus.applied;

  bool get isRejected => status == HydrationAiActionExecutionStatus.rejected;

  bool get changesAppState =>
      status == HydrationAiActionExecutionStatus.applied;
}

class HydrationAiActionValidator {
  const HydrationAiActionValidator();

  HydrationAiActionValidationResult validate(
    HydrationAiAction action,
    CapabilityContext capabilities,
  ) {
    final blocked = <HydrionCapability>[
      for (final capability in action.requiredCapabilities)
        if (!capabilities.isAvailable(capability)) capability,
    ];

    blocked.addAll(_blockedActionCapabilities(action, capabilities));
    blocked.addAll(_claimedUnavailableCapabilities(
      action.message,
      capabilities,
    ));

    final distinctBlocked = <HydrionCapability>[
      for (final capability in HydrionCapability.values)
        if (blocked.contains(capability)) capability,
    ];

    final structuralReason = _structuralReason(action);
    if (distinctBlocked.isEmpty && structuralReason == null) {
      return HydrationAiActionValidationResult(
        originalAction: action,
        action: action,
        isAllowed: true,
        blockedCapabilities: const <HydrionCapability>[],
        reason: 'Allowed',
      );
    }

    final reason = structuralReason ??
        'Blocked because this action requires unavailable capabilities: '
            '${distinctBlocked.map(_capabilityLabel).join(', ')}.';
    return HydrationAiActionValidationResult(
      originalAction: action,
      action: UnsupportedCapabilityNoticeAction(
        message: reason,
        capability: distinctBlocked.isEmpty ? null : distinctBlocked.first,
      ),
      isAllowed: false,
      blockedCapabilities: distinctBlocked,
      reason: reason,
    );
  }

  List<HydrationAiActionValidationResult> validateAll(
    Iterable<HydrationAiAction> actions,
    CapabilityContext capabilities,
  ) {
    return [
      for (final action in actions) validate(action, capabilities),
    ];
  }

  List<HydrionCapability> _blockedActionCapabilities(
    HydrationAiAction action,
    CapabilityContext capabilities,
  ) {
    final blocked = <HydrionCapability>[];
    if (action is SuggestReminderAction &&
        action.claimsOsNotificationScheduled &&
        !capabilities.osNotifications) {
      blocked.add(HydrionCapability.osNotifications);
    }
    if (action is SuggestChallengeAction &&
        action.claimsSocialSync &&
        !capabilities.socialSync) {
      blocked.add(HydrionCapability.socialSync);
    }
    return blocked;
  }

  String? _structuralReason(HydrationAiAction action) {
    if (action is SuggestHydrationLogAction &&
        (action.volumeMl <= 0 || action.volumeMl > 5000)) {
      return 'Blocked because the suggested hydration amount is outside the '
          'allowed 1 to 5000 ml range.';
    }
    if (action is SuggestReminderAction && action.delay.isNegative) {
      return 'Blocked because the suggested reminder delay is negative.';
    }
    if (action is SuggestChallengeAction &&
        (action.targetMl <= 0 || action.durationDays <= 0)) {
      return 'Blocked because the suggested challenge target or duration is '
          'invalid.';
    }
    return null;
  }

  List<HydrionCapability> _claimedUnavailableCapabilities(
    String message,
    CapabilityContext capabilities,
  ) {
    final text = message.toLowerCase();
    final rules = <HydrionCapability, List<String>>{
      HydrionCapability.voiceInput: ['voice'],
      HydrionCapability.osNotifications: ['os notifications', 'notifications'],
      HydrionCapability.bleSync: ['ble', 'bluetooth'],
      HydrionCapability.healthSync: ['health sync', 'healthkit', 'google fit'],
      HydrionCapability.arVisualization: ['ar ', 'ar visualization'],
      HydrionCapability.socialSync: ['social sync', 'social'],
      HydrionCapability.cloudAi: ['cloud ai', 'cloud model'],
      HydrionCapability.cloudSync: ['cloud sync'],
      HydrionCapability.gemini: ['gemini'],
      HydrionCapability.elka: ['elka'],
    };

    return [
      for (final entry in rules.entries)
        if (!capabilities.isAvailable(entry.key) &&
            _containsActiveClaim(text, entry.value))
          entry.key,
    ];
  }

  bool _containsActiveClaim(String text, List<String> keywords) {
    const activeWords = [
      'active',
      'available',
      'configured',
      'connected',
      'enabled',
      'scheduled',
      'started',
      'syncing',
      'will fire',
      'working',
      'works',
    ];
    const negations = [
      'disabled',
      'not ',
      'no ',
      'unavailable',
      'without',
    ];

    for (final keyword in keywords) {
      var index = text.indexOf(keyword);
      while (index >= 0) {
        final start = index - 32 < 0 ? 0 : index - 32;
        final end = index + 96 > text.length ? text.length : index + 96;
        final window = text.substring(start, end);
        final activeClaim = activeWords.any(window.contains);
        final negated = negations.any(window.contains);
        if (activeClaim && !negated) {
          return true;
        }
        index = text.indexOf(keyword, index + keyword.length);
      }
    }
    return false;
  }

  String _capabilityLabel(HydrionCapability capability) {
    return switch (capability) {
      HydrionCapability.localPersistence => 'local persistence',
      HydrionCapability.elka => 'ELKA',
      HydrionCapability.gemini => 'Gemini',
      HydrionCapability.cloudAi => 'cloud AI',
      HydrionCapability.cloudSync => 'cloud sync',
      HydrionCapability.voiceInput => 'voice input',
      HydrionCapability.bleSync => 'BLE sync',
      HydrionCapability.healthSync => 'Health sync',
      HydrionCapability.osNotifications => 'OS notifications',
      HydrionCapability.arVisualization => 'AR visualization',
      HydrionCapability.socialSync => 'social sync',
    };
  }
}

abstract class HydrationSummaryService {
  Future<HydrationSummary> getHydrationSummary();
}

abstract class HydrationContextProvider {
  Future<HydrationContext> getHydrationContext({
    DateTime? now,
    HydrationCoachDigestKey digestKey = HydrationCoachDigestKey.weeklyDigest,
  });
}

abstract class HydrationAiProvider {
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  });
}

abstract class HydrationAiActionExecutionService {
  Future<HydrationAiActionExecutionResult> execute(
    HydrationAiAction action, {
    required bool userConfirmed,
    DateTime? now,
  });
}

enum CoachSuggestionKind {
  hydrationLog,
  reminder,
  challenge,
  trendInsight,
  unsupportedCapability,
}

enum CoachSuggestionDetailKind {
  volumeMl,
  delayMinutes,
  priority,
  challengeName,
  targetMl,
  durationDays,
  capability,
}

enum CoachSuggestionStatus {
  validated,
  applied,
  dismissed,
  rejected,
  displayOnly,
}

class CoachSuggestionDetail {
  final CoachSuggestionDetailKind kind;
  final int? intValue;
  final String? textValue;
  final HydrionCapability? capability;

  const CoachSuggestionDetail({
    required this.kind,
    this.intValue,
    this.textValue,
    this.capability,
  });
}

class CoachSuggestionCard {
  final String id;
  final CoachSuggestionKind kind;
  final HydrionAiProviderKind providerSource;
  final String message;
  final List<CoachSuggestionDetail> details;
  final bool changesAppState;
  final bool requiresConfirmation;
  final CoachSuggestionStatus status;

  const CoachSuggestionCard({
    required this.id,
    required this.kind,
    required this.providerSource,
    required this.message,
    this.details = const <CoachSuggestionDetail>[],
    required this.changesAppState,
    required this.requiresConfirmation,
    this.status = CoachSuggestionStatus.validated,
  });

  CoachSuggestionCard copyWith({
    CoachSuggestionStatus? status,
  }) {
    return CoachSuggestionCard(
      id: id,
      kind: kind,
      providerSource: providerSource,
      message: message,
      details: details,
      changesAppState: changesAppState,
      requiresConfirmation: requiresConfirmation,
      status: status ?? this.status,
    );
  }
}

class CoachTurn {
  final String message;
  final List<CoachSuggestionCard> suggestions;
  final bool usedFallback;

  const CoachTurn({
    this.message = '',
    this.suggestions = const <CoachSuggestionCard>[],
    this.usedFallback = false,
  });
}

class CoachSuggestionExecutionView {
  final String suggestionId;
  final CoachSuggestionStatus status;
  final String? appliedEntityId;

  const CoachSuggestionExecutionView({
    required this.suggestionId,
    required this.status,
    this.appliedEntityId,
  });
}

abstract class CoachSuggestionService {
  Future<CoachTurn> ask({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  });

  Future<CoachSuggestionExecutionView> confirm(String suggestionId);

  void dismiss(String suggestionId);
}

abstract class HydrationCoach {
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  });

  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  });
}

abstract class ChallengeGenerator {
  Future<HydrationChallenge> createChallenge({required String userLevel});
}

abstract class HydrationCommandParser {
  Future<Map<String, dynamic>> parseCommandToJson(String command);
}

abstract class AppCapabilityReporter {
  AppCapabilities get capabilities;

  void updateCapabilities(AppCapabilities capabilities) {}
}

class ProviderHealthSnapshot {
  final HydrionAiProviderKind selectedProvider;
  final HydrionAiProviderKind activeProvider;
  final bool localRulesAvailable;
  final bool geminiConfigured;
  final bool geminiAvailable;
  final bool elkaAvailable;
  final String? lastProviderFailure;
  final String? fallbackReason;
  final bool privacyDisclosureRequired;
  final bool privacyConsentRecorded;
  final ProviderDiagnosticSnapshot diagnostic;

  const ProviderHealthSnapshot({
    required this.selectedProvider,
    required this.activeProvider,
    required this.localRulesAvailable,
    required this.geminiConfigured,
    required this.geminiAvailable,
    required this.elkaAvailable,
    this.lastProviderFailure,
    this.fallbackReason,
    required this.privacyDisclosureRequired,
    required this.privacyConsentRecorded,
    required this.diagnostic,
  });

  const ProviderHealthSnapshot.localRules()
      : selectedProvider = HydrionAiProviderKind.localRules,
        activeProvider = HydrionAiProviderKind.localRules,
        localRulesAvailable = true,
        geminiConfigured = false,
        geminiAvailable = false,
        elkaAvailable = false,
        lastProviderFailure = null,
        fallbackReason = null,
        privacyDisclosureRequired = false,
        privacyConsentRecorded = true,
        diagnostic = const ProviderDiagnosticSnapshot.localRules();

  ProviderHealthSnapshot copyWith({
    HydrionAiProviderKind? selectedProvider,
    HydrionAiProviderKind? activeProvider,
    bool? localRulesAvailable,
    bool? geminiConfigured,
    bool? geminiAvailable,
    bool? elkaAvailable,
    Object? lastProviderFailure = _unchanged,
    Object? fallbackReason = _unchanged,
    bool? privacyDisclosureRequired,
    bool? privacyConsentRecorded,
    ProviderDiagnosticSnapshot? diagnostic,
  }) {
    return ProviderHealthSnapshot(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      activeProvider: activeProvider ?? this.activeProvider,
      localRulesAvailable: localRulesAvailable ?? this.localRulesAvailable,
      geminiConfigured: geminiConfigured ?? this.geminiConfigured,
      geminiAvailable: geminiAvailable ?? this.geminiAvailable,
      elkaAvailable: elkaAvailable ?? this.elkaAvailable,
      lastProviderFailure: identical(lastProviderFailure, _unchanged)
          ? this.lastProviderFailure
          : lastProviderFailure as String?,
      fallbackReason: identical(fallbackReason, _unchanged)
          ? this.fallbackReason
          : fallbackReason as String?,
      privacyDisclosureRequired:
          privacyDisclosureRequired ?? this.privacyDisclosureRequired,
      privacyConsentRecorded:
          privacyConsentRecorded ?? this.privacyConsentRecorded,
      diagnostic: diagnostic ?? this.diagnostic,
    );
  }

  static const Object _unchanged = Object();
}

class ProviderDiagnosticCodes {
  static const String localRulesActive = 'local_rules_active';
  static const String notAttempted = 'not_attempted';
  static const String noApiKey = 'no_api_key';
  static const String providerConsentRequired = 'provider_consent_required';
  static const String requestAttempted = 'request_attempted';
  static const String httpFailure = 'http_failure';
  static const String timeout = 'timeout';
  static const String responseDecoded = 'response_decoded';
  static const String noCandidates = 'no_candidates';
  static const String noContent = 'no_content';
  static const String noParts = 'no_parts';
  static const String emptyText = 'empty_text';
  static const String responseJsonDecodeFailed = 'response_json_decode_failed';
  static const String jsonDecodeFailed = 'json_decode_failed';
  static const String outputNotJson = 'output_not_json';
  static const String missingActions = 'missing_actions';
  static const String emptyActions = 'empty_actions';
  static const String tooManyActions = 'too_many_actions';
  static const String invalidActionSchema = 'invalid_action_schema';
  static const String unknownActionType = 'unknown_action_type';
  static const String missingRequiredField = 'missing_required_field';
  static const String oversizedMessage = 'oversized_message';
  static const String invalidHydrationAmount = 'invalid_hydration_amount';
  static const String invalidReminderDelay = 'invalid_reminder_delay';
  static const String invalidChallengeShape = 'invalid_challenge_shape';
  static const String unknownCapability = 'unknown_capability';
  static const String validatorRejected = 'validator_rejected';
  static const String unsafeCapabilityClaim = 'unsafe_capability_claim';
  static const String success = 'success';
  static const String providerFailure = 'provider_failure';
}

abstract class ProviderDiagnosticFailure implements Exception {
  String get diagnosticCode;
  int? get httpStatusCode;
  bool get timedOut;
  String? get responseEnvelopePhase;
  String? get parserRejectionCode;
  String? get validatorRejectionCode;
  List<String> get blockedCapabilityLabels;
  String? get providerErrorStatus;
  String? get providerErrorMessage;
  List<String> get providerErrorDetailTypes;
}

class ProviderDiagnosticSnapshot {
  final HydrionAiProviderKind selectedProvider;
  final HydrionAiProviderKind activeProvider;
  final bool configured;
  final String? modelId;
  final String? endpointHost;
  final String? modelPath;
  final bool? apiKeyPresent;
  final int? apiKeyLength;
  final String? apiKeyFingerprint;
  final bool? apiKeyContainsWhitespace;
  final bool? apiKeyWasTrimmed;
  final bool? apiKeyStartsWithExpectedGooglePrefix;
  final bool? authHeaderPresent;
  final int? authHeaderValueLength;
  final bool requestAttempted;
  final String? httpStatusClass;
  final bool timedOut;
  final String? responseEnvelopePhase;
  final String? parserRejectionCode;
  final String? validatorRejectionCode;
  final List<String> blockedCapabilityLabels;
  final String? providerErrorStatus;
  final String? providerErrorMessage;
  final List<String> providerErrorDetailTypes;
  final String? fallbackReason;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;

  const ProviderDiagnosticSnapshot({
    required this.selectedProvider,
    required this.activeProvider,
    required this.configured,
    this.modelId,
    this.endpointHost,
    this.modelPath,
    this.apiKeyPresent,
    this.apiKeyLength,
    this.apiKeyFingerprint,
    this.apiKeyContainsWhitespace,
    this.apiKeyWasTrimmed,
    this.apiKeyStartsWithExpectedGooglePrefix,
    this.authHeaderPresent,
    this.authHeaderValueLength,
    this.requestAttempted = false,
    this.httpStatusClass,
    this.timedOut = false,
    this.responseEnvelopePhase,
    this.parserRejectionCode,
    this.validatorRejectionCode,
    this.blockedCapabilityLabels = const <String>[],
    this.providerErrorStatus,
    this.providerErrorMessage,
    this.providerErrorDetailTypes = const <String>[],
    this.fallbackReason,
    this.lastSuccessAt,
    this.lastFailureAt,
  });

  const ProviderDiagnosticSnapshot.localRules()
      : selectedProvider = HydrionAiProviderKind.localRules,
        activeProvider = HydrionAiProviderKind.localRules,
        configured = true,
        modelId = null,
        endpointHost = null,
        modelPath = null,
        apiKeyPresent = null,
        apiKeyLength = null,
        apiKeyFingerprint = null,
        apiKeyContainsWhitespace = null,
        apiKeyWasTrimmed = null,
        apiKeyStartsWithExpectedGooglePrefix = null,
        authHeaderPresent = null,
        authHeaderValueLength = null,
        requestAttempted = false,
        httpStatusClass = null,
        timedOut = false,
        responseEnvelopePhase = ProviderDiagnosticCodes.localRulesActive,
        parserRejectionCode = null,
        validatorRejectionCode = null,
        blockedCapabilityLabels = const <String>[],
        providerErrorStatus = null,
        providerErrorMessage = null,
        providerErrorDetailTypes = const <String>[],
        fallbackReason = null,
        lastSuccessAt = null,
        lastFailureAt = null;

  ProviderDiagnosticSnapshot copyWith({
    HydrionAiProviderKind? selectedProvider,
    HydrionAiProviderKind? activeProvider,
    bool? configured,
    Object? modelId = _unchanged,
    Object? endpointHost = _unchanged,
    Object? modelPath = _unchanged,
    Object? apiKeyPresent = _unchanged,
    Object? apiKeyLength = _unchanged,
    Object? apiKeyFingerprint = _unchanged,
    Object? apiKeyContainsWhitespace = _unchanged,
    Object? apiKeyWasTrimmed = _unchanged,
    Object? apiKeyStartsWithExpectedGooglePrefix = _unchanged,
    Object? authHeaderPresent = _unchanged,
    Object? authHeaderValueLength = _unchanged,
    bool? requestAttempted,
    Object? httpStatusClass = _unchanged,
    bool? timedOut,
    Object? responseEnvelopePhase = _unchanged,
    Object? parserRejectionCode = _unchanged,
    Object? validatorRejectionCode = _unchanged,
    List<String>? blockedCapabilityLabels,
    Object? providerErrorStatus = _unchanged,
    Object? providerErrorMessage = _unchanged,
    List<String>? providerErrorDetailTypes,
    Object? fallbackReason = _unchanged,
    Object? lastSuccessAt = _unchanged,
    Object? lastFailureAt = _unchanged,
  }) {
    return ProviderDiagnosticSnapshot(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      activeProvider: activeProvider ?? this.activeProvider,
      configured: configured ?? this.configured,
      modelId:
          identical(modelId, _unchanged) ? this.modelId : modelId as String?,
      endpointHost: identical(endpointHost, _unchanged)
          ? this.endpointHost
          : endpointHost as String?,
      modelPath: identical(modelPath, _unchanged)
          ? this.modelPath
          : modelPath as String?,
      apiKeyPresent: identical(apiKeyPresent, _unchanged)
          ? this.apiKeyPresent
          : apiKeyPresent as bool?,
      apiKeyLength: identical(apiKeyLength, _unchanged)
          ? this.apiKeyLength
          : apiKeyLength as int?,
      apiKeyFingerprint: identical(apiKeyFingerprint, _unchanged)
          ? this.apiKeyFingerprint
          : apiKeyFingerprint as String?,
      apiKeyContainsWhitespace: identical(apiKeyContainsWhitespace, _unchanged)
          ? this.apiKeyContainsWhitespace
          : apiKeyContainsWhitespace as bool?,
      apiKeyWasTrimmed: identical(apiKeyWasTrimmed, _unchanged)
          ? this.apiKeyWasTrimmed
          : apiKeyWasTrimmed as bool?,
      apiKeyStartsWithExpectedGooglePrefix:
          identical(apiKeyStartsWithExpectedGooglePrefix, _unchanged)
              ? this.apiKeyStartsWithExpectedGooglePrefix
              : apiKeyStartsWithExpectedGooglePrefix as bool?,
      authHeaderPresent: identical(authHeaderPresent, _unchanged)
          ? this.authHeaderPresent
          : authHeaderPresent as bool?,
      authHeaderValueLength: identical(authHeaderValueLength, _unchanged)
          ? this.authHeaderValueLength
          : authHeaderValueLength as int?,
      requestAttempted: requestAttempted ?? this.requestAttempted,
      httpStatusClass: identical(httpStatusClass, _unchanged)
          ? this.httpStatusClass
          : httpStatusClass as String?,
      timedOut: timedOut ?? this.timedOut,
      responseEnvelopePhase: identical(responseEnvelopePhase, _unchanged)
          ? this.responseEnvelopePhase
          : responseEnvelopePhase as String?,
      parserRejectionCode: identical(parserRejectionCode, _unchanged)
          ? this.parserRejectionCode
          : parserRejectionCode as String?,
      validatorRejectionCode: identical(validatorRejectionCode, _unchanged)
          ? this.validatorRejectionCode
          : validatorRejectionCode as String?,
      blockedCapabilityLabels:
          blockedCapabilityLabels ?? this.blockedCapabilityLabels,
      providerErrorStatus: identical(providerErrorStatus, _unchanged)
          ? this.providerErrorStatus
          : providerErrorStatus as String?,
      providerErrorMessage: identical(providerErrorMessage, _unchanged)
          ? this.providerErrorMessage
          : providerErrorMessage as String?,
      providerErrorDetailTypes:
          providerErrorDetailTypes ?? this.providerErrorDetailTypes,
      fallbackReason: identical(fallbackReason, _unchanged)
          ? this.fallbackReason
          : fallbackReason as String?,
      lastSuccessAt: identical(lastSuccessAt, _unchanged)
          ? this.lastSuccessAt
          : lastSuccessAt as DateTime?,
      lastFailureAt: identical(lastFailureAt, _unchanged)
          ? this.lastFailureAt
          : lastFailureAt as DateTime?,
    );
  }

  String get lastDiagnosticCode =>
      validatorRejectionCode ??
      parserRejectionCode ??
      responseEnvelopePhase ??
      (timedOut ? ProviderDiagnosticCodes.timeout : null) ??
      httpStatusClass ??
      ProviderDiagnosticCodes.notAttempted;

  static const Object _unchanged = Object();
}

abstract class ProviderHealthReporter extends ChangeNotifier {
  ProviderHealthSnapshot get providerHealth;

  void updatePrivacyConsent(bool consentGranted) {}
}
