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
}
