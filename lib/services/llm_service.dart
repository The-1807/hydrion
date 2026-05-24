import 'dart:convert';

import 'core_bridge.dart';

enum LlmMode { localEdge, byok, gemini, fallback }

enum DigestKey {
  weeklyDigest,
  reminderNudge,
  sentimentAnalysis,
  commandParsing,
}

class LLMService {
  final CoreBridge _coreBridge;
  bool _initialized = false;

  LLMService({CoreBridge? coreBridge})
      : _coreBridge = coreBridge ?? CoreBridge();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    await initialize();

    final hydration = hydrationPercent.clamp(0.0, 100.0);
    final entries = (entryCount ?? activityMinutes ?? 0).clamp(0, 24);
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
    return _coreBridge.coreValidateLlmResponse('$advice$entryNote');
  }

  Future<String> getCoachingAdvice({
    required String userQuery,
    required DigestKey digestKey,
    LlmMode mode = LlmMode.localEdge,
  }) async {
    await initialize();
    final digest = jsonDecode(await _coreBridge.coreGetDigest(digestKey.name))
        as Map<String, dynamic>;
    final totalMl = digest['totalMl'] as int? ?? 0;
    final lifetimeMl = digest['lifetimeMl'] as int? ?? 0;
    final eventCount = digest['eventCount'] as int? ?? 0;
    final suffix =
        userQuery.trim().isEmpty ? '' : ' You asked: ${userQuery.trim()}';
    final eventLabel = eventCount == 1 ? 'log' : 'logs';
    final context = eventCount == 0
        ? 'No saved hydration logs yet.'
        : 'Today: $totalMl ml. Lifetime tracked: $lifetimeMl ml across $eventCount saved $eventLabel.';

    return _coreBridge.coreValidateLlmResponse(
      'Hydrion is running in local deterministic mode. $context$suffix',
    );
  }

  Future<Map<String, dynamic>> parseCommandToJson(String command) async {
    await initialize();
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
