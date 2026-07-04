import '../../domain/hydration_contracts.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';

typedef LocalHydrationAdviceBuilder = String Function({
  required double hydrationPercent,
  required int entryCount,
  required double temperatureC,
});

class LocalHydrationSummaryService implements HydrationSummaryService {
  final HydrationRepository _hydrationRepository;
  final UserSettingsRepository _settingsRepository;

  LocalHydrationSummaryService({
    required HydrationRepository hydrationRepository,
    required UserSettingsRepository settingsRepository,
  })  : _hydrationRepository = hydrationRepository,
        _settingsRepository = settingsRepository;

  @override
  Future<HydrationSummary> getHydrationSummary() async {
    final today = DateTime.now();
    final consumedMl = _hydrationRepository.totalForDay(today);
    final logsToday = _hydrationRepository.fetch(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    final targetMl = _settingsRepository.settings.dailyGoalMl;
    final hydrationPercent = (consumedMl / targetMl * 100).clamp(0.0, 100.0);

    return HydrationSummary(
      hydrationPercent: hydrationPercent,
      entryCount: logsToday.length,
      consumedMl: consumedMl,
      targetMl: targetMl,
    );
  }
}

class LocalChallengeGenerator implements ChallengeGenerator {
  const LocalChallengeGenerator();

  @override
  Future<HydrationChallenge> createChallenge({
    required String userLevel,
  }) async {
    return HydrationChallenge(
      id: 'steady-sip-7-day-${userLevel.toLowerCase()}',
      name: 'Seven Day Steady Sip',
      description: 'Reach your daily hydration goal for one week.',
      targetMl: UserSettings.defaultDailyGoalMl,
      durationDays: 7,
    );
  }
}

class LocalHydrationCoach implements HydrationCoach, HydrationAiProvider {
  final HydrationContextProvider _contextProvider;
  final HydrationAiActionValidator _actionValidator;
  final LocalHydrationAdviceBuilder? _adviceBuilder;
  bool _initialized = false;

  LocalHydrationCoach({
    required HydrationContextProvider contextProvider,
    HydrationAiActionValidator actionValidator =
        const HydrationAiActionValidator(),
    LocalHydrationAdviceBuilder? adviceBuilder,
  })  : _contextProvider = contextProvider,
        _actionValidator = actionValidator,
        _adviceBuilder = adviceBuilder;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    await initialize();

    final hydration = hydrationPercent.clamp(0.0, 100.0);
    final entries = (entryCount ?? activityMinutes ?? 0).clamp(0, 24);
    final localizedAdvice = _adviceBuilder?.call(
      hydrationPercent: hydration,
      entryCount: entries,
      temperatureC: temperatureC,
    );
    if (localizedAdvice != null) {
      final action = CoachMessageAction(message: _normalize(localizedAdvice));
      return _actionValidator
          .validate(action, const CapabilityContext.standalone())
          .action
          .message;
    }

    final heat =
        temperatureC >= 28 ? ' Warm conditions raise your fluid needs.' : '';

    final advice = switch (hydration) {
      >= 85.0 =>
        'You are on a strong hydration pace. Keep taking small sips through the day.$heat',
      >= 65.0 =>
        'You are close to target. Add a glass of water in the next hour to stay steady.$heat',
      _ =>
        'Start with 300 to 500 ml now, then check in again after your next drink.$heat',
    };

    final entryNote = entries >= 3
        ? ' You have $entries local entries today, which makes the trend more reliable.'
        : ' Add entries when you drink so Hydrion can track the day honestly.';
    final action = CoachMessageAction(message: _normalize('$advice$entryNote'));
    return _actionValidator
        .validate(action, const CapabilityContext.standalone())
        .action
        .message;
  }

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    await initialize();
    final context = await _contextProvider.getHydrationContext(
      digestKey: digestKey,
    );
    final actions = await proposeActions(
      context: context,
      userQuery: userQuery,
    );
    final result = _actionValidator.validate(
      actions.first,
      context.capabilities,
    );
    return result.action.message;
  }

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    await initialize();
    final totalMl = context.dailySummary.consumedMl;
    final lifetimeMl = context.lifetimeMl;
    final eventCount = context.eventCount;
    final suffix =
        userQuery.trim().isEmpty ? '' : ' You asked: ${userQuery.trim()}';
    final eventLabel = eventCount == 1 ? 'log' : 'logs';
    final contextText = eventCount == 0
        ? 'No saved hydration logs yet.'
        : 'Today: $totalMl ml. Lifetime tracked: $lifetimeMl ml across $eventCount saved $eventLabel.';

    return [
      CoachMessageAction(
        message: _normalize(
          'Hydrion is using on-device guidance. $contextText$suffix',
        ),
      ),
    ];
  }

  String _normalize(String response) {
    final oneLine = response.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) {
      return 'Hydrion is running locally. Take a steady sip and keep tracking.';
    }
    return oneLine.length > 220 ? '${oneLine.substring(0, 217)}...' : oneLine;
  }
}

class LocalHydrationCommandParser implements HydrationCommandParser {
  const LocalHydrationCommandParser();

  @override
  Future<Map<String, dynamic>> parseCommandToJson(String command) async {
    final normalized = command.toLowerCase().trim();

    if (normalized.contains('remind')) {
      return {
        'intent': 'schedule_reminder',
        'entities': <String, Object?>{},
      };
    }

    final amountMatch =
        RegExp(r'(\d{2,4})\s*(ml|milliliters?)?').firstMatch(normalized);
    if (normalized.contains('drink') ||
        normalized.contains('log') ||
        amountMatch != null) {
      return {
        'intent': 'log_hydration',
        'entities': {
          'volumeMl':
              amountMatch == null ? null : int.parse(amountMatch.group(1)!),
        },
      };
    }

    return {
      'intent': 'unknown_command',
      'entities': {'command': command},
    };
  }
}

class LocalAppCapabilityReporter implements AppCapabilityReporter {
  AppCapabilities _capabilities;

  LocalAppCapabilityReporter({
    AppCapabilities capabilities = const AppCapabilities.standalone(),
  }) : _capabilities = capabilities;

  @override
  AppCapabilities get capabilities => _capabilities;

  @override
  void updateCapabilities(AppCapabilities capabilities) {
    _capabilities = capabilities;
  }
}
