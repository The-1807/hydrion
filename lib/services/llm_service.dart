import '../adapters/local/local_hydrion_adapters.dart';
import '../domain/hydration_contracts.dart';
import 'core_bridge.dart';

export '../domain/hydration_contracts.dart' show HydrationCoachDigestKey;

typedef DigestKey = HydrationCoachDigestKey;

enum LlmMode { localEdge, byok, gemini, fallback }

@Deprecated('Use HydrationCoach and HydrationCommandParser instead.')
class LLMService implements HydrationCoach, HydrationCommandParser {
  final LocalHydrationCoach _coach;
  final LocalHydrationCommandParser _commandParser;

  LLMService({CoreBridge? coreBridge})
      : _coach = LocalHydrationCoach(coreBridge: coreBridge ?? CoreBridge()),
        _commandParser = const LocalHydrationCommandParser();

  Future<void> initialize() {
    return _coach.initialize();
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) {
    return _coach.getHydrationCoachResponse(
      hydrationPercent: hydrationPercent,
      entryCount: entryCount,
      activityMinutes: activityMinutes,
      temperatureC: temperatureC,
    );
  }

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
    LlmMode mode = LlmMode.localEdge,
  }) {
    return _coach.getCoachingAdvice(
      userQuery: userQuery,
      digestKey: digestKey,
    );
  }

  @override
  Future<Map<String, dynamic>> parseCommandToJson(String command) {
    return _commandParser.parseCommandToJson(command);
  }
}
