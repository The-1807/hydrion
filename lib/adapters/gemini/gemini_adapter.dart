import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/hydration_contracts.dart';
import '../../services/ai_provider_config.dart';
import '../../services/secret_redaction.dart';

abstract class GeminiContentClient {
  Future<String> generateContent({
    required GeminiProviderConfig config,
    required String prompt,
  });
}

class GeminiRequestBodyBuilder {
  const GeminiRequestBodyBuilder();

  Map<String, Object?> build({
    required GeminiProviderConfig config,
    required String prompt,
  }) {
    return config.useResponseSchema
        ? buildSchemaEnabledJsonModeRequest(prompt: prompt)
        : buildSchemaFreeJsonModeRequest(prompt: prompt);
  }

  Map<String, Object?> buildSchemaFreeJsonModeRequest({
    required String prompt,
  }) {
    return {
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
    };
  }

  Map<String, Object?> buildSchemaEnabledJsonModeRequest({
    required String prompt,
  }) {
    final body = buildSchemaFreeJsonModeRequest(prompt: prompt);
    final generationConfig = body['generationConfig']! as Map<String, Object?>;
    generationConfig
      ..remove('responseMimeType')
      ..['responseFormat'] = {
        'text': {
          'mimeType': 'application/json',
          'schema': _minimalHydrionActionResponseSchema,
        },
      };
    return body;
  }

  static const Map<String, Object?> _minimalHydrionActionResponseSchema = {
    'type': 'object',
    'properties': {
      'actions': {
        'type': 'array',
        'maxItems': 3,
        'items': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': [
                'coachMessage',
                'suggestReminder',
                'suggestHydrationLog',
                'explainTrend',
                'suggestChallenge',
                'unsupportedCapabilityNotice',
              ],
            },
            'message': {'type': 'string'},
            'volumeMl': {'type': 'integer'},
            'delayMinutes': {'type': 'integer'},
            'priority': {'type': 'integer'},
            'claimsOsNotificationScheduled': {'type': 'boolean'},
            'challengeId': {'type': 'string'},
            'name': {'type': 'string'},
            'description': {'type': 'string'},
            'targetMl': {'type': 'integer'},
            'durationDays': {'type': 'integer'},
            'claimsSocialSync': {'type': 'boolean'},
            'capability': {
              'type': 'string',
              'enum': [
                'localPersistence',
                'elka',
                'gemini',
                'cloudAi',
                'cloudSync',
                'voiceInput',
                'bleSync',
                'healthSync',
                'osNotifications',
                'socialSync',
              ],
            },
            'requiredCapabilities': {
              'type': 'array',
              'items': {
                'type': 'string',
                'enum': [
                  'localPersistence',
                  'elka',
                  'gemini',
                  'cloudAi',
                  'cloudSync',
                  'voiceInput',
                  'bleSync',
                  'healthSync',
                  'osNotifications',
                  'socialSync',
                ],
              },
            },
          },
          'required': ['type', 'message'],
        },
      },
    },
    'required': ['actions'],
  };
}

class GeminiHttpContentClient implements GeminiContentClient {
  final http.Client _client;
  final GeminiRequestBodyBuilder _requestBodyBuilder;

  GeminiHttpContentClient({
    http.Client? client,
    GeminiRequestBodyBuilder requestBodyBuilder =
        const GeminiRequestBodyBuilder(),
  })  : _client = client ?? http.Client(),
        _requestBodyBuilder = requestBodyBuilder;

  @override
  Future<String> generateContent({
    required GeminiProviderConfig config,
    required String prompt,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            config.generateContentUri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': config.trimmedApiKey,
            },
            body: jsonEncode(
              _requestBodyBuilder.build(config: config, prompt: prompt),
            ),
          )
          .timeout(config.timeout);
    } on TimeoutException {
      throw const GeminiProviderException(
        'Gemini request timed out.',
        diagnosticCode: ProviderDiagnosticCodes.timeout,
        timedOut: true,
        responseEnvelopePhase: ProviderDiagnosticCodes.timeout,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _safeErrorDetails(response.body);
      throw GeminiProviderException(
        'Gemini request failed with HTTP ${response.statusCode}.',
        diagnosticCode: ProviderDiagnosticCodes.httpFailure,
        httpStatusCode: response.statusCode,
        responseEnvelopePhase: ProviderDiagnosticCodes.httpFailure,
        providerErrorStatus: error.status,
        providerErrorMessage: error.message,
        providerErrorDetailTypes: error.detailTypes,
      );
    }

    final Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw const GeminiProviderException(
        'Gemini returned malformed JSON.',
        diagnosticCode: ProviderDiagnosticCodes.responseJsonDecodeFailed,
        responseEnvelopePhase: ProviderDiagnosticCodes.responseJsonDecodeFailed,
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const GeminiProviderException(
        'Gemini returned malformed JSON.',
        diagnosticCode: ProviderDiagnosticCodes.responseJsonDecodeFailed,
        responseEnvelopePhase: ProviderDiagnosticCodes.responseJsonDecodeFailed,
      );
    }
    return _extractText(payload);
  }

  static String _extractText(Map<String, dynamic> payload) {
    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiProviderException(
        'Gemini returned no candidates.',
        diagnosticCode: ProviderDiagnosticCodes.noCandidates,
        responseEnvelopePhase: ProviderDiagnosticCodes.noCandidates,
      );
    }

    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw const GeminiProviderException(
        'Gemini candidate was malformed.',
        diagnosticCode: ProviderDiagnosticCodes.noContent,
        responseEnvelopePhase: ProviderDiagnosticCodes.noContent,
      );
    }

    final content = candidate['content'];
    if (content is! Map<String, dynamic>) {
      throw const GeminiProviderException(
        'Gemini content was malformed.',
        diagnosticCode: ProviderDiagnosticCodes.noContent,
        responseEnvelopePhase: ProviderDiagnosticCodes.noContent,
      );
    }

    final parts = content['parts'];
    if (parts is! List) {
      throw const GeminiProviderException(
        'Gemini parts were malformed.',
        diagnosticCode: ProviderDiagnosticCodes.noParts,
        responseEnvelopePhase: ProviderDiagnosticCodes.noParts,
      );
    }

    final text = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text.isEmpty) {
      throw const GeminiProviderException(
        'Gemini returned empty text.',
        diagnosticCode: ProviderDiagnosticCodes.emptyText,
        responseEnvelopePhase: ProviderDiagnosticCodes.emptyText,
      );
    }
    return text;
  }

  static _SafeGeminiErrorDetails _safeErrorDetails(String body) {
    if (body.trim().isEmpty) {
      return const _SafeGeminiErrorDetails();
    }

    final Object? payload;
    try {
      payload = jsonDecode(body);
    } on FormatException {
      return const _SafeGeminiErrorDetails();
    }
    if (payload is! Map<String, dynamic>) {
      return const _SafeGeminiErrorDetails();
    }

    final error = payload['error'];
    if (error is! Map<String, dynamic>) {
      return const _SafeGeminiErrorDetails();
    }

    final status = _safeShortString(error['status']);
    final message = _safeErrorMessage(error['message']);
    final details = error['details'];
    final detailTypes = <String>[];
    if (details is List) {
      for (final detail in details) {
        if (detail is! Map) {
          continue;
        }
        final type = _safeShortString(detail['@type'] ?? detail['type']);
        if (type != null) {
          detailTypes.add(type);
        }
      }
    }

    return _SafeGeminiErrorDetails(
      status: status,
      message: message,
      detailTypes: detailTypes.take(4).toList(growable: false),
    );
  }

  static String? _safeShortString(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty || normalized.length > 160) {
      return null;
    }
    return _redactSecrets(normalized);
  }

  static String? _safeErrorMessage(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    const contextMarkers = [
      'hydrationcontext',
      'dailysummary',
      'lifetimeml',
      'eventcount',
      'user query',
      'consumedml',
      'targetml',
    ];
    if (contextMarkers.any(lower.contains)) {
      return null;
    }
    final redacted = _redactSecrets(normalized);
    return redacted.length <= 240
        ? redacted
        : '${redacted.substring(0, 237)}...';
  }

  static String _redactSecrets(String value) {
    return SecretRedactor.sanitize(value);
  }
}

class _SafeGeminiErrorDetails {
  final String? status;
  final String? message;
  final List<String> detailTypes;

  const _SafeGeminiErrorDetails({
    this.status,
    this.message,
    this.detailTypes = const <String>[],
  });
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
        diagnosticCode: ProviderDiagnosticCodes.noApiKey,
        responseEnvelopePhase: ProviderDiagnosticCodes.noApiKey,
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
        diagnosticCode: ProviderDiagnosticCodes.emptyActions,
        parserRejectionCode: ProviderDiagnosticCodes.emptyActions,
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
      throw const GeminiProviderException(
        'Gemini output was invalid JSON.',
        diagnosticCode: ProviderDiagnosticCodes.jsonDecodeFailed,
        parserRejectionCode: ProviderDiagnosticCodes.jsonDecodeFailed,
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw const GeminiProviderException(
        'Gemini output must be an object with an actions list.',
        diagnosticCode: ProviderDiagnosticCodes.missingActions,
        parserRejectionCode: ProviderDiagnosticCodes.missingActions,
      );
    }
    final rawActions = payload['actions'];
    if (rawActions is! List) {
      throw const GeminiProviderException(
        'Gemini output did not contain an actions list.',
        diagnosticCode: ProviderDiagnosticCodes.missingActions,
        parserRejectionCode: ProviderDiagnosticCodes.missingActions,
      );
    }
    if (rawActions.isEmpty) {
      throw const GeminiProviderException(
        'Gemini output must contain at least 1 action.',
        diagnosticCode: ProviderDiagnosticCodes.emptyActions,
        parserRejectionCode: ProviderDiagnosticCodes.emptyActions,
      );
    }
    if (rawActions.length > maxActions) {
      throw const GeminiProviderException(
        'Gemini output must contain no more than 3 actions.',
        diagnosticCode: ProviderDiagnosticCodes.tooManyActions,
        parserRejectionCode: ProviderDiagnosticCodes.tooManyActions,
      );
    }

    return [
      for (final rawAction in rawActions)
        if (rawAction is Map<String, dynamic>)
          _parseAction(rawAction)
        else
          throw const GeminiProviderException(
            'Gemini action entries must be JSON objects.',
            diagnosticCode: ProviderDiagnosticCodes.invalidActionSchema,
            parserRejectionCode: ProviderDiagnosticCodes.invalidActionSchema,
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
          diagnosticCode: ProviderDiagnosticCodes.unknownActionType,
          parserRejectionCode: ProviderDiagnosticCodes.unknownActionType,
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
    throw const GeminiProviderException(
      'Gemini output was not JSON.',
      diagnosticCode: ProviderDiagnosticCodes.outputNotJson,
      parserRejectionCode: ProviderDiagnosticCodes.jsonDecodeFailed,
    );
  }

  String _requiredString(
    Map<String, dynamic> payload,
    String key, {
    required int maxLength,
  }) {
    final value = payload[key];
    if (value is! String) {
      throw GeminiProviderException(
        'Gemini field "$key" must be a string.',
        diagnosticCode: ProviderDiagnosticCodes.missingRequiredField,
        parserRejectionCode: ProviderDiagnosticCodes.missingRequiredField,
      );
    }
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty || normalized.length > maxLength) {
      final code = key == 'message'
          ? ProviderDiagnosticCodes.oversizedMessage
          : ProviderDiagnosticCodes.missingRequiredField;
      throw GeminiProviderException(
        'Gemini field "$key" must be 1 to $maxLength characters.',
        diagnosticCode: code,
        parserRejectionCode: code,
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
      final code = _intFieldCode(key);
      throw GeminiProviderException(
        'Gemini field "$key" must be an integer from $min to $max.',
        diagnosticCode: code,
        parserRejectionCode: code,
      );
    }
    return parsed;
  }

  String _intFieldCode(String key) {
    return switch (key) {
      'volumeMl' => ProviderDiagnosticCodes.invalidHydrationAmount,
      'delayMinutes' ||
      'priority' =>
        ProviderDiagnosticCodes.invalidReminderDelay,
      'targetMl' ||
      'durationDays' =>
        ProviderDiagnosticCodes.invalidChallengeShape,
      _ => ProviderDiagnosticCodes.missingRequiredField,
    };
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
          diagnosticCode: ProviderDiagnosticCodes.unknownCapability,
          parserRejectionCode: ProviderDiagnosticCodes.unknownCapability,
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
      'social' || 'socialsync' => HydrionCapability.socialSync,
      _ => null,
    };
  }
}

class GeminiProviderUnavailable implements ProviderDiagnosticFailure {
  final String message;
  @override
  final String diagnosticCode;
  @override
  final int? httpStatusCode;
  @override
  final bool timedOut;
  @override
  final String? responseEnvelopePhase;
  @override
  final String? parserRejectionCode;
  @override
  final String? validatorRejectionCode;
  @override
  final List<String> blockedCapabilityLabels;
  @override
  final String? providerErrorStatus;
  @override
  final String? providerErrorMessage;
  @override
  final List<String> providerErrorDetailTypes;

  const GeminiProviderUnavailable(
    this.message, {
    this.diagnosticCode = ProviderDiagnosticCodes.noApiKey,
    this.httpStatusCode,
    this.timedOut = false,
    this.responseEnvelopePhase,
    this.parserRejectionCode,
    this.validatorRejectionCode,
    this.blockedCapabilityLabels = const <String>[],
    this.providerErrorStatus,
    this.providerErrorMessage,
    this.providerErrorDetailTypes = const <String>[],
  });

  @override
  String toString() => message;
}

class GeminiProviderException implements ProviderDiagnosticFailure {
  final String message;
  @override
  final String diagnosticCode;
  @override
  final int? httpStatusCode;
  @override
  final bool timedOut;
  @override
  final String? responseEnvelopePhase;
  @override
  final String? parserRejectionCode;
  @override
  final String? validatorRejectionCode;
  @override
  final List<String> blockedCapabilityLabels;
  @override
  final String? providerErrorStatus;
  @override
  final String? providerErrorMessage;
  @override
  final List<String> providerErrorDetailTypes;

  const GeminiProviderException(
    this.message, {
    this.diagnosticCode = ProviderDiagnosticCodes.providerFailure,
    this.httpStatusCode,
    this.timedOut = false,
    this.responseEnvelopePhase,
    this.parserRejectionCode,
    this.validatorRejectionCode,
    this.blockedCapabilityLabels = const <String>[],
    this.providerErrorStatus,
    this.providerErrorMessage,
    this.providerErrorDetailTypes = const <String>[],
  });

  @override
  String toString() => message;
}
