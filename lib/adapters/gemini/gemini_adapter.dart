import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/hydration_contracts.dart';
import '../../services/ai_provider_config.dart';

abstract class GeminiContentClient {
  Future<String> generateContent({
    required GeminiProviderConfig config,
    required String prompt,
  });
}

class GeminiHttpContentClient implements GeminiContentClient {
  final http.Client _client;

  GeminiHttpContentClient({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<String> generateContent({
    required GeminiProviderConfig config,
    required String prompt,
  }) async {
    final response = await _client
        .post(
          config.generateContentUri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': config.apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(config.timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiProviderException(
        'Gemini request failed with HTTP ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const GeminiProviderException('Gemini returned malformed JSON.');
    }
    return _extractText(payload);
  }

  static String _extractText(Map<String, dynamic> payload) {
    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiProviderException('Gemini returned no candidates.');
    }

    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw const GeminiProviderException('Gemini candidate was malformed.');
    }

    final content = candidate['content'];
    if (content is! Map<String, dynamic>) {
      throw const GeminiProviderException('Gemini content was malformed.');
    }

    final parts = content['parts'];
    if (parts is! List) {
      throw const GeminiProviderException('Gemini parts were malformed.');
    }

    final text = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text.isEmpty) {
      throw const GeminiProviderException('Gemini returned empty text.');
    }
    return text;
  }
}

class GeminiHydrationAiProvider implements HydrationAiProvider {
  static const int maxActions = 3;
  static const int maxMessageLength = 600;
  static const int maxIdentifierLength = 96;
  static const int maxNameLength = 120;
  static const int maxDescriptionLength = 400;
  static const int maxReminderDelayMinutes = 1440;
  static const int maxChallengeDurationDays = 365;

  final GeminiProviderConfig config;
  final GeminiContentClient _client;

  GeminiHydrationAiProvider({
    required this.config,
    GeminiContentClient? client,
  }) : _client = client ?? GeminiHttpContentClient();

  bool get isConfigured => config.isConfigured;

  bool get isAvailable => isConfigured;

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    if (!isAvailable) {
      throw const GeminiProviderUnavailable(
        'Gemini provider is unavailable because no API key is configured.',
      );
    }

    final generatedText = await _client.generateContent(
      config: config,
      prompt: _buildPrompt(context: context, userQuery: userQuery),
    );
    final actions = _parseActions(generatedText);
    if (actions.isEmpty) {
      throw const GeminiProviderException(
        'Gemini returned no Hydrion action proposals.',
      );
    }
    return actions;
  }

  String _buildPrompt({
    required HydrationContext context,
    required String userQuery,
  }) {
    final contextJson = jsonEncode({
      'dailySummary': {
        'date': context.dailySummary.date.toIso8601String(),
        'consumedMl': context.dailySummary.consumedMl,
        'targetMl': context.dailySummary.targetMl,
        'entryCount': context.dailySummary.entryCount,
        'hydrationPercent': context.dailySummary.hydrationPercent,
      },
      'lifetimeMl': context.lifetimeMl,
      'eventCount': context.eventCount,
      'reminder': {
        'savedReminderCount': context.reminder.savedReminderCount,
        'nextReminderAt': context.reminder.nextReminderAt?.toIso8601String(),
        'osNotificationsAvailable': context.reminder.osNotificationsAvailable,
      },
      'challenge': {
        'hasActiveChallenge': context.challenge.hasActiveChallenge,
        'activeChallengeId': context.challenge.activeChallengeId,
        'activeChallengeName': context.challenge.activeChallengeName,
        'targetMl': context.challenge.targetMl,
        'durationDays': context.challenge.durationDays,
        'completedDays': context.challenge.completedDays,
        'todayMl': context.challenge.todayMl,
        'progressPercent': context.challenge.progressPercent,
      },
      'capabilities': {
        'localPersistence': context.capabilities.localPersistence,
        'elkaConfigured': context.capabilities.elkaConfigured,
        'geminiConfigured': context.capabilities.geminiConfigured,
        'cloudAi': context.capabilities.cloudAi,
        'cloudSync': context.capabilities.cloudSync,
        'voiceInput': context.capabilities.voiceInput,
        'bleSync': context.capabilities.bleSync,
        'healthSync': context.capabilities.healthSync,
        'osNotifications': context.capabilities.osNotifications,
        'arVisualization': context.capabilities.arVisualization,
        'socialSync': context.capabilities.socialSync,
      },
    });

    return '''
You are Hydrion's optional Gemini provider. Consume this typed HydrationContext JSON and return HydrationAiAction proposals only.

Provider rules:
- Never claim disabled capabilities are active, connected, configured, scheduled, syncing, or working.
- Never mutate app state. Hydrion validates and executes after user confirmation.
- Prefer one concise coachMessage unless the user explicitly asks for a reminder, hydration log, trend explanation, challenge, or unavailable feature.
- Return JSON only. No Markdown fences.

HydrationContext:
$contextJson

User query:
${userQuery.trim()}

Allowed JSON shape:
{
  "actions": [
    {
      "type": "coachMessage",
      "message": "short safe text"
    }
  ]
}

Supported action types and fields:
- coachMessage: message
- suggestHydrationLog: message, volumeMl
- suggestReminder: message, delayMinutes, priority, claimsOsNotificationScheduled
- explainTrend: message
- suggestChallenge: message, challengeId, name, description, targetMl, durationDays, claimsSocialSync
- unsupportedCapabilityNotice: message, capability
''';
  }

  List<HydrationAiAction> _parseActions(String generatedText) {
    final Object? payload;
    try {
      payload = jsonDecode(_extractJson(generatedText));
    } on FormatException {
      throw const GeminiProviderException('Gemini output was invalid JSON.');
    }

    if (payload is! Map<String, dynamic>) {
      throw const GeminiProviderException(
        'Gemini output must be an object with an actions list.',
      );
    }
    final rawActions = payload['actions'];
    if (rawActions is! List) {
      throw const GeminiProviderException(
        'Gemini output did not contain an actions list.',
      );
    }
    if (rawActions.isEmpty || rawActions.length > maxActions) {
      throw const GeminiProviderException(
        'Gemini output must contain 1 to 3 actions.',
      );
    }

    return [
      for (final rawAction in rawActions)
        if (rawAction is Map<String, dynamic>)
          _parseAction(rawAction)
        else
          throw const GeminiProviderException(
            'Gemini action entries must be JSON objects.',
          ),
    ];
  }

  HydrationAiAction _parseAction(Map<String, dynamic> action) {
    final type = _requiredString(
      action,
      'type',
      maxLength: 64,
    );
    final message = _requiredString(
      action,
      'message',
      maxLength: maxMessageLength,
    );
    final requiredCapabilities = _readCapabilities(
      action['requiredCapabilities'],
    );

    return switch (type) {
      'coachMessage' => CoachMessageAction(
          message: message,
          requiredCapabilities: requiredCapabilities,
        ),
      'suggestHydrationLog' => SuggestHydrationLogAction(
          message: message,
          volumeMl: _requiredIntInRange(
            action,
            'volumeMl',
            min: 1,
            max: 5000,
          ),
          requiredCapabilities: requiredCapabilities,
        ),
      'suggestReminder' => SuggestReminderAction(
          message: message,
          delay: Duration(
            minutes: _requiredIntInRange(
              action,
              'delayMinutes',
              min: 0,
              max: maxReminderDelayMinutes,
            ),
          ),
          priority: _optionalIntInRange(
            action,
            'priority',
            min: 1,
            max: 3,
            fallback: 1,
          ),
          claimsOsNotificationScheduled:
              _readBool(action, 'claimsOsNotificationScheduled'),
          requiredCapabilities: requiredCapabilities,
        ),
      'explainTrend' => ExplainTrendAction(
          message: message,
          requiredCapabilities: requiredCapabilities,
        ),
      'suggestChallenge' => SuggestChallengeAction(
          message: message,
          challengeId: _requiredString(
            action,
            'challengeId',
            maxLength: maxIdentifierLength,
          ),
          name: _requiredString(
            action,
            'name',
            maxLength: maxNameLength,
          ),
          description: _requiredString(
            action,
            'description',
            maxLength: maxDescriptionLength,
          ),
          targetMl: _requiredIntInRange(
            action,
            'targetMl',
            min: 1,
            max: 5000,
          ),
          durationDays: _requiredIntInRange(
            action,
            'durationDays',
            min: 1,
            max: maxChallengeDurationDays,
          ),
          claimsSocialSync: _readBool(action, 'claimsSocialSync'),
          requiredCapabilities: requiredCapabilities,
        ),
      'unsupportedCapabilityNotice' => UnsupportedCapabilityNoticeAction(
          message: message,
          capability: _readCapability(action['capability']),
        ),
      _ => throw GeminiProviderException(
          'Gemini returned unsupported action type "$type".',
        ),
    };
  }

  String _extractJson(String text) {
    final trimmed = text.trim();
    final withoutFence = trimmed.startsWith('```')
        ? trimmed
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim()
        : trimmed;
    final firstObject = withoutFence.indexOf('{');
    final lastObject = withoutFence.lastIndexOf('}');
    final firstArray = withoutFence.indexOf('[');
    final lastArray = withoutFence.lastIndexOf(']');

    if (firstObject >= 0 &&
        lastObject > firstObject &&
        (firstArray < 0 || firstObject < firstArray)) {
      return withoutFence.substring(firstObject, lastObject + 1);
    }
    if (firstArray >= 0 && lastArray > firstArray) {
      return withoutFence.substring(firstArray, lastArray + 1);
    }
    throw const GeminiProviderException('Gemini output was not JSON.');
  }

  String _requiredString(
    Map<String, dynamic> payload,
    String key, {
    required int maxLength,
  }) {
    final value = payload[key];
    if (value is! String) {
      throw GeminiProviderException('Gemini field "$key" must be a string.');
    }
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty || normalized.length > maxLength) {
      throw GeminiProviderException(
        'Gemini field "$key" must be 1 to $maxLength characters.',
      );
    }
    return normalized;
  }

  int _requiredIntInRange(
    Map<String, dynamic> payload,
    String key, {
    required int min,
    required int max,
  }) {
    final value = payload[key];
    final parsed = value is int
        ? value
        : value is String
            ? int.tryParse(value)
            : null;
    if (parsed == null || parsed < min || parsed > max) {
      throw GeminiProviderException(
        'Gemini field "$key" must be an integer from $min to $max.',
      );
    }
    return parsed;
  }

  int _optionalIntInRange(
    Map<String, dynamic> payload,
    String key, {
    required int min,
    required int max,
    required int fallback,
  }) {
    if (!payload.containsKey(key)) {
      return fallback;
    }
    return _requiredIntInRange(payload, key, min: min, max: max);
  }

  bool _readBool(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  Set<HydrionCapability> _readCapabilities(Object? value) {
    if (value is! List) {
      return const <HydrionCapability>{};
    }
    final capabilities = <HydrionCapability>{};
    for (final item in value) {
      final capability = _readCapability(item);
      if (capability == null) {
        throw const GeminiProviderException(
          'Gemini returned an unknown required capability.',
        );
      }
      capabilities.add(capability);
    }
    return capabilities;
  }

  HydrionCapability? _readCapability(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized =
        value.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    return switch (normalized) {
      'localpersistence' => HydrionCapability.localPersistence,
      'elka' => HydrionCapability.elka,
      'gemini' => HydrionCapability.gemini,
      'cloudai' => HydrionCapability.cloudAi,
      'cloudsync' => HydrionCapability.cloudSync,
      'voice' || 'voiceinput' => HydrionCapability.voiceInput,
      'ble' || 'blesync' || 'bluetooth' => HydrionCapability.bleSync,
      'health' || 'healthsync' => HydrionCapability.healthSync,
      'notifications' || 'osnotifications' => HydrionCapability.osNotifications,
      'ar' || 'arvisualization' => HydrionCapability.arVisualization,
      'social' || 'socialsync' => HydrionCapability.socialSync,
      _ => null,
    };
  }
}

class GeminiProviderUnavailable implements Exception {
  final String message;

  const GeminiProviderUnavailable(this.message);

  @override
  String toString() => message;
}

class GeminiProviderException implements Exception {
  final String message;

  const GeminiProviderException(this.message);

  @override
  String toString() => message;
}
