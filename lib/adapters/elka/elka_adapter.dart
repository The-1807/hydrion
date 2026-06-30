import '../../domain/hydration_contracts.dart';

class ElkaAdapterShell
    implements
        HydrationCoach,
        HydrationAiProvider,
        ChallengeGenerator,
        HydrationCommandParser,
        AppCapabilityReporter {
  final String reason;

  const ElkaAdapterShell.unconfigured({
    this.reason =
        'ELKA adapter shell is present but not configured in this build.',
  });

  bool get isConfigured => false;

  @override
  AppCapabilities get capabilities => const AppCapabilities(
        localPersistence: true,
        elkaConfigured: false,
        cloudAi: false,
        voiceInput: false,
        bleSync: false,
        healthSync: false,
        osNotifications: false,
        arVisualization: false,
        socialSync: false,
      );

  @override
  void updateCapabilities(AppCapabilities capabilities) {}

  @override
  Future<HydrationChallenge> createChallenge({
    required String userLevel,
  }) {
    return _unconfigured<HydrationChallenge>();
  }

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) {
    return _unconfigured<String>();
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) {
    return _unconfigured<String>();
  }

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) {
    return _unconfigured<List<HydrationAiAction>>();
  }

  @override
  Future<Map<String, dynamic>> parseCommandToJson(String command) {
    return _unconfigured<Map<String, dynamic>>();
  }

  Future<T> _unconfigured<T>() {
    return Future<T>.error(UnsupportedError(reason));
  }
}
