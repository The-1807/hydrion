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

enum HydrationCoachDigestKey {
  weeklyDigest,
  reminderNudge,
  sentimentAnalysis,
  commandParsing,
}

class AppCapabilities {
  final bool localPersistence;
  final bool elkaConfigured;
  final bool cloudAi;
  final bool voiceInput;
  final bool bleSync;
  final bool healthSync;
  final bool osNotifications;
  final bool arVisualization;
  final bool socialSync;

  const AppCapabilities({
    required this.localPersistence,
    required this.elkaConfigured,
    required this.cloudAi,
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
        cloudAi = false,
        voiceInput = false,
        bleSync = false,
        healthSync = false,
        osNotifications = false,
        arVisualization = false,
        socialSync = false;

  String get modeLabel =>
      elkaConfigured ? 'ELKA adapter configured' : 'Standalone local mode';
}

abstract class HydrationSummaryService {
  Future<HydrationSummary> getHydrationSummary();
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
