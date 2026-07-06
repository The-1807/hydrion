import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/gemini/gemini_adapter.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/ai_provider_config.dart';
import 'package:hydrion/services/hydration_ai_orchestrator.dart';
import 'package:hydrion/services/provider_health.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const validator = HydrationAiActionValidator();

  test('local_rules remains default when Gemini is not configured', () {
    const config = HydrionAiRuntimeConfig();
    final environmentConfig = HydrionAiRuntimeConfig.fromEnvironment();

    expect(config.provider, HydrionAiProviderSelection.localRules);
    expect(config.gemini.isConfigured, isFalse);
    expect(config.shouldUseGemini, isFalse);
    expect(environmentConfig.provider, HydrionAiProviderSelection.localRules);
  });

  test('default web build config does not require a provider credential', () {
    final environmentConfig = HydrionAiRuntimeConfig.fromEnvironment();

    expect(environmentConfig.provider, HydrionAiProviderSelection.localRules);
    expect(environmentConfig.gemini.isConfigured, isFalse);
    expect(environmentConfig.shouldUseGemini, isFalse);
  });

  test('default Android build config does not require a provider credential',
      () {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(),
    );

    expect(
      services.aiRuntimeConfig.provider,
      HydrionAiProviderSelection.localRules,
    );
    expect(services.aiRuntimeConfig.gemini.isConfigured, isFalse);
    expect(services.aiRuntimeConfig.shouldUseGemini, isFalse);
  });

  test('Gemini reports unavailable when no API key/config exists', () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(),
      client: const _FakeGeminiClient('{"actions": []}'),
    );

    expect(provider.isConfigured, isFalse);
    expect(provider.isAvailable, isFalse);
    await expectLater(
      provider.proposeActions(
        context: _standaloneContext(),
        userQuery: 'hello',
      ),
      throwsA(isA<GeminiProviderUnavailable>()),
    );
  });

  test('no API key diagnostic stays redacted through fallback', () async {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
      ),
    );

    final response = await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'try provider',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );
    final health = services.providerHealthReporter.providerHealth;

    expect(response, contains('on-device guidance'));
    expect(health.activeProvider, HydrionAiProviderKind.localRules);
    expect(health.diagnostic.responseEnvelopePhase,
        ProviderDiagnosticCodes.noApiKey);
    expect(health.diagnostic.requestAttempted, isFalse);
    expect(health.fallbackReason, contains('no_api_key'));
  });

  test('Gemini request builder produces minimal schema-free JSON-mode request',
      () {
    const builder = GeminiRequestBodyBuilder();

    final body = builder.build(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      prompt: 'safe prompt',
    );
    final generationConfig = body['generationConfig']! as Map<String, Object?>;

    expect(body['contents'], isA<List>());
    expect(generationConfig['responseMimeType'], 'application/json');
    expect(generationConfig.containsKey('responseSchema'), isFalse);
    expect(generationConfig.containsKey('responseJsonSchema'), isFalse);
    expect(generationConfig.containsKey('responseFormat'), isFalse);
  });

  test('Gemini request builder can produce current structured output request',
      () {
    const builder = GeminiRequestBodyBuilder();

    final body = builder.build(
      config: const GeminiProviderConfig(
        apiKey: 'test-key',
        useResponseSchema: true,
      ),
      prompt: 'safe prompt',
    );
    final generationConfig = body['generationConfig']! as Map<String, Object?>;
    final responseFormat =
        generationConfig['responseFormat']! as Map<String, Object?>;
    final text = responseFormat['text']! as Map<String, Object?>;
    final responseSchema = text['schema']! as Map<String, Object?>;

    expect(generationConfig.containsKey('responseSchema'), isFalse);
    expect(generationConfig.containsKey('responseJsonSchema'), isFalse);
    expect(generationConfig.containsKey('responseMimeType'), isFalse);
    expect(text['mimeType'], 'application/json');
    expect(responseSchema['type'], 'object');
    expect(jsonEncode(responseSchema), contains('coachMessage'));
    expect(jsonEncode(responseSchema), isNot(contains('maxLength')));
    expect(jsonEncode(responseSchema), isNot(contains('minimum')));
  });

  test('Gemini HTTP request uses schema-free JSON mode by default', () async {
    var requestAttempted = false;
    final client = GeminiHttpContentClient(
      client: MockClient((request) async {
        requestAttempted = true;
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final generationConfig =
            payload['generationConfig'] as Map<String, dynamic>;

        expect(request.url.toString(),
            contains('/v1beta/models/gemini-2.5-flash:generateContent'));
        expect(request.headers['x-goog-api-key'], 'test-key');
        expect(generationConfig['responseMimeType'], 'application/json');
        expect(generationConfig.containsKey('responseSchema'), isFalse);
        expect(generationConfig.containsKey('responseFormat'), isFalse);

        return http.Response(
          jsonEncode(_geminiEnvelope(
            '{"actions":[{"type":"coachMessage","message":"Gemini says sip."}]}',
          )),
          200,
        );
      }),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: client,
    );

    final actions = await provider.proposeActions(
      context: _standaloneContext().copyWithGeminiConfigured(),
      userQuery: 'hello',
    );

    expect(requestAttempted, isTrue);
    expect(actions.single.message, 'Gemini says sip.');
  });

  test('Gemini HTTP request sends the same trimmed key shape used by curl',
      () async {
    const rawApiKey = ' \nAIza-safe-key-tail \t';
    var requestAttempted = false;
    final client = GeminiHttpContentClient(
      client: MockClient((request) async {
        requestAttempted = true;
        expect(request.headers['x-goog-api-key'], 'AIza-safe-key-tail');
        return http.Response(
          jsonEncode(_geminiEnvelope(
            '{"actions":[{"type":"coachMessage","message":"Trimmed key worked."}]}',
          )),
          200,
        );
      }),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: rawApiKey),
      client: client,
    );

    final actions = await provider.proposeActions(
      context: _standaloneContext().copyWithGeminiConfigured(),
      userQuery: 'hello',
    );

    expect(requestAttempted, isTrue);
    expect(actions.single.message, 'Trimmed key worked.');
  });

  test('Gemini key and request diagnostics stay safe and useful', () {
    const apiKey = ' \nAIza-safe-key-tail \t';
    const config = GeminiProviderConfig(apiKey: apiKey);
    final key = config.keyDiagnostics;
    final request = config.requestDiagnostics;
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: config,
      ),
    );
    final diagnostic = providerHealth.providerHealth.diagnostic;
    final diagnosticText = [
      diagnostic.endpointHost,
      diagnostic.modelId,
      diagnostic.modelPath,
      diagnostic.apiKeyFingerprint,
      diagnostic.apiKeyLength?.toString(),
      diagnostic.apiKeyContainsWhitespace?.toString(),
      diagnostic.apiKeyWasTrimmed?.toString(),
      diagnostic.apiKeyStartsWithExpectedGooglePrefix?.toString(),
      diagnostic.authHeaderPresent?.toString(),
      diagnostic.authHeaderValueLength?.toString(),
    ].whereType<String>().join(' ');

    expect(key.present, isTrue);
    expect(key.length, 'AIza-safe-key-tail'.length);
    expect(key.fingerprint, isNotNull);
    expect(key.fingerprint, diagnostic.apiKeyFingerprint);
    expect(key.fingerprint, isNot(contains('AIza')));
    expect(key.fingerprint, isNot(contains('tail')));
    expect(key.containsWhitespace, isTrue);
    expect(key.wasTrimmed, isTrue);
    expect(key.startsWithExpectedGoogleApiKeyPrefix, isTrue);
    expect(request.endpointHost, 'generativelanguage.googleapis.com');
    expect(request.modelPath, 'models/gemini-2.5-flash');
    expect(request.authHeaderPresent, isTrue);
    expect(request.authHeaderValueLength, 'AIza-safe-key-tail'.length);
    expect(diagnosticText, isNot(contains('AIza-safe-key-tail')));
    expect(diagnosticText, isNot(contains(apiKey)));
    expect(diagnosticText, isNot(contains('AIza tail')));
  });

  test('successful Gemini action records request and success diagnostics',
      () async {
    final context = _standaloneContext().copyWithGeminiConfigured();
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":"Gemini says sip."}]}',
      ),
    );
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: provider,
      localRulesProvider:
          const _StaticLocalRulesProvider(message: 'local fallback'),
      contextProvider: _StaticContextProvider(context),
      actionValidator: validator,
      providerHealth: providerHealth,
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'try Gemini',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );
    final health = providerHealth.providerHealth;

    expect(response, 'Gemini says sip.');
    expect(health.activeProvider, HydrionAiProviderKind.gemini);
    expect(health.diagnostic.requestAttempted, isTrue);
    expect(health.diagnostic.responseEnvelopePhase,
        ProviderDiagnosticCodes.success);
    expect(health.diagnostic.lastSuccessAt, isNotNull);
    expect(health.fallbackReason, isNull);
  });

  test('Gemini failure falls back to local_rules', () async {
    final context = _standaloneContext();
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: const _ThrowingAiProvider(),
      localRulesProvider: const _StaticLocalRulesProvider(
        message: 'local_rules fallback response',
      ),
      contextProvider: _StaticContextProvider(context),
      actionValidator: validator,
      providerHealth: providerHealth,
      providerTimeout: const Duration(milliseconds: 100),
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'try Gemini',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, 'local_rules fallback response');
    expect(
      providerHealth.providerHealth.activeProvider,
      HydrionAiProviderKind.localRules,
    );
    expect(
        providerHealth.providerHealth.lastProviderFailure, contains('Gemini'));
    expect(
        providerHealth.providerHealth.fallbackReason, contains('local_rules'));
  });

  test('HTTP non-2xx diagnostic is stored without secrets', () async {
    const apiKey = 'test-key-that-must-not-appear';
    const userQuery = 'private hydration question';
    final errorBody = jsonEncode({
      'error': {
        'code': 400,
        'status': 'INVALID_ARGUMENT',
        'message':
            'Invalid JSON payload received. Unknown name "responseSchema".',
        'details': [
          {'@type': 'type.googleapis.com/google.rpc.BadRequest'},
          {'@type': 'type.googleapis.com/google.rpc.Help'},
        ],
      },
    });
    final context = _standaloneContext().copyWithGeminiConfigured();
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: apiKey),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: apiKey),
      client: GeminiHttpContentClient(
        client: MockClient((_) async => http.Response(errorBody, 400)),
      ),
    );
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: provider,
      localRulesProvider:
          const _StaticLocalRulesProvider(message: 'local fallback'),
      contextProvider: _StaticContextProvider(context),
      actionValidator: validator,
      providerHealth: providerHealth,
    );

    final response = await coach.getCoachingAdvice(
      userQuery: userQuery,
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );
    final diagnostic = providerHealth.providerHealth.diagnostic;
    final diagnosticText = [
      providerHealth.providerHealth.fallbackReason,
      providerHealth.providerHealth.lastProviderFailure,
      diagnostic.responseEnvelopePhase,
      diagnostic.parserRejectionCode,
      diagnostic.validatorRejectionCode,
      diagnostic.blockedCapabilityLabels.join(','),
      diagnostic.endpointHost,
      diagnostic.modelId,
      diagnostic.modelPath,
      diagnostic.apiKeyFingerprint,
      diagnostic.apiKeyLength?.toString(),
      diagnostic.apiKeyContainsWhitespace?.toString(),
      diagnostic.apiKeyWasTrimmed?.toString(),
      diagnostic.apiKeyStartsWithExpectedGooglePrefix?.toString(),
      diagnostic.authHeaderPresent?.toString(),
      diagnostic.authHeaderValueLength?.toString(),
      diagnostic.providerErrorStatus,
      diagnostic.providerErrorMessage,
      diagnostic.providerErrorDetailTypes.join(','),
    ].whereType<String>().join(' ');

    expect(response, 'local fallback');
    expect(diagnostic.httpStatusClass, '4xx');
    expect(
        diagnostic.responseEnvelopePhase, ProviderDiagnosticCodes.httpFailure);
    expect(diagnostic.endpointHost, 'generativelanguage.googleapis.com');
    expect(diagnostic.modelPath, 'models/gemini-2.5-flash');
    expect(diagnostic.authHeaderPresent, isTrue);
    expect(diagnostic.authHeaderValueLength, apiKey.length);
    expect(diagnostic.providerErrorStatus, 'INVALID_ARGUMENT');
    expect(diagnostic.providerErrorMessage, contains('Invalid JSON payload'));
    expect(
      diagnostic.providerErrorDetailTypes,
      contains('type.googleapis.com/google.rpc.BadRequest'),
    );
    expect(diagnosticText, isNot(contains(apiKey)));
    expect(diagnosticText, isNot(contains(userQuery)));
  });

  test('HTTP 4xx diagnostics redact unsafe provider error messages', () async {
    final apiKey = _fakeGoogleKey();
    final errorBody = jsonEncode({
      'error': {
        'status': 'INVALID_ARGUMENT',
        'message':
            'Bad request for HydrationContext dailySummary $apiKey should not leak.',
      },
    });
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: apiKey),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: GeminiProviderConfig(apiKey: apiKey),
      client: GeminiHttpContentClient(
        client: MockClient((_) async => http.Response(errorBody, 400)),
      ),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'private user query',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    final diagnostic = providerHealth.providerHealth.diagnostic;
    expect(diagnostic.providerErrorStatus, 'INVALID_ARGUMENT');
    expect(diagnostic.providerErrorMessage, isNull);
    expect(
      providerHealth.providerHealth.lastProviderFailure,
      isNot(contains(apiKey)),
    );
  });

  test('HTTP 4xx diagnostics sanitize auth headers and secret payloads',
      () async {
    final fakeBearer = _fakeOpenAiKey();
    final fakeGoogleKey = _fakeGoogleKey();
    final errorBody = jsonEncode({
      'error': {
        'status': 'PERMISSION_DENIED',
        'message': 'Provider rejected Authorization: Bearer $fakeBearer for '
            'https://example.test/provider?key=$fakeGoogleKey with '
            'x-goog-api-key: $fakeGoogleKey.',
      },
    });
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: GeminiHttpContentClient(
        client: MockClient((_) async => http.Response(errorBody, 403)),
      ),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'private user query',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    final diagnostic = providerHealth.providerHealth.diagnostic;
    final diagnosticText = [
      providerHealth.providerHealth.fallbackReason,
      providerHealth.providerHealth.lastProviderFailure,
      diagnostic.providerErrorStatus,
      diagnostic.providerErrorMessage,
    ].whereType<String>().join(' ');

    expect(diagnostic.providerErrorStatus, 'PERMISSION_DENIED');
    expect(
        diagnostic.providerErrorMessage, contains('[redacted:authorization]'));
    expect(diagnostic.providerErrorMessage, contains('[redacted:credential]'));
    expect(diagnosticText, isNot(contains(fakeBearer)));
    expect(diagnosticText, isNot(contains(fakeGoogleKey)));
  });

  test('timeout diagnostic is stored when Gemini request exceeds timeout',
      () async {
    final context = _standaloneContext().copyWithGeminiConfigured();
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(
          apiKey: 'test-key',
          timeout: Duration(milliseconds: 1),
        ),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(
        apiKey: 'test-key',
        timeout: Duration(milliseconds: 1),
      ),
      client: GeminiHttpContentClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      ),
    );
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: provider,
      localRulesProvider:
          const _StaticLocalRulesProvider(message: 'local fallback'),
      contextProvider: _StaticContextProvider(context),
      actionValidator: validator,
      providerHealth: providerHealth,
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'try timeout',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, 'local fallback');
    expect(providerHealth.providerHealth.diagnostic.timedOut, isTrue);
    expect(providerHealth.providerHealth.diagnostic.responseEnvelopePhase,
        ProviderDiagnosticCodes.timeout);
    expect(providerHealth.providerHealth.fallbackReason, contains('timeout'));
  });

  test('invalid response envelope diagnostic is stored', () async {
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: GeminiHttpContentClient(
        client: MockClient((_) async => http.Response(
              jsonEncode({'candidates': <Object?>[]}),
              200,
            )),
      ),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'bad envelope',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(providerHealth.providerHealth.diagnostic.responseEnvelopePhase,
        ProviderDiagnosticCodes.noCandidates);
    expect(providerHealth.providerHealth.fallbackReason,
        contains('no_candidates'));
  });

  test('invalid JSON diagnostic is stored', () async {
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient('plain text'),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'bad JSON',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(providerHealth.providerHealth.diagnostic.parserRejectionCode,
        ProviderDiagnosticCodes.jsonDecodeFailed);
  });

  test('missing actions diagnostic is stored', () async {
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient('{"notActions":[]}'),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'missing actions',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(providerHealth.providerHealth.diagnostic.parserRejectionCode,
        ProviderDiagnosticCodes.missingActions);
  });

  test('unknown action diagnostic is stored', () async {
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"dance","message":"Unsupported."}]}',
      ),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    await coach.getCoachingAdvice(
      userQuery: 'unknown action',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(providerHealth.providerHealth.diagnostic.parserRejectionCode,
        ProviderDiagnosticCodes.unknownActionType);
  });

  test('validator rejection diagnostic includes blocked capability labels',
      () async {
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":"Voice input is working."}]}',
      ),
    );
    final coach = _geminiCoachWith(
      provider: provider,
      providerHealth: providerHealth,
      context: _standaloneContext().copyWithGeminiConfigured(),
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'voice?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, 'local fallback');
    expect(providerHealth.providerHealth.diagnostic.validatorRejectionCode,
        ProviderDiagnosticCodes.unsafeCapabilityClaim);
    expect(providerHealth.providerHealth.diagnostic.blockedCapabilityLabels,
        contains('voice input'));
  });

  test('invalid Gemini hydration log proposal is rejected by schema', () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"suggestHydrationLog","message":"Log 0 ml.","volumeMl":0}]}',
      ),
    );

    await expectLater(
      provider.proposeActions(
        context: _standaloneContext(),
        userQuery: 'log water',
      ),
      throwsA(isA<GeminiProviderException>()),
    );
  });

  test('invalid Gemini reminder proposal is rejected by schema', () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"suggestReminder","message":"Remind me in the past.","delayMinutes":-5}]}',
      ),
    );

    await expectLater(
      provider.proposeActions(
        context: _standaloneContext(),
        userQuery: 'remind me',
      ),
      throwsA(isA<GeminiProviderException>()),
    );
  });

  test('Gemini cannot claim unavailable capabilities are active', () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":"Gemini is connected and voice input is working."}]}',
      ),
    );

    final actions = await provider.proposeActions(
      context: _standaloneContext(),
      userQuery: 'what works?',
    );
    final result = validator.validate(
      actions.single,
      const CapabilityContext.standalone(),
    );

    expect(result.isAllowed, isFalse);
    expect(result.blockedCapabilities, contains(HydrionCapability.gemini));
    expect(result.blockedCapabilities, contains(HydrionCapability.voiceInput));
  });

  test('Gemini output remains typed HydrationAiAction proposals only',
      () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":"Take steady sips."},{"type":"suggestHydrationLog","message":"Suggest 250 ml.","volumeMl":250}]}',
      ),
    );

    final actions = await provider.proposeActions(
      context: _standaloneContext(),
      userQuery: 'what next?',
    );

    expect(actions, hasLength(2));
    expect(actions, everyElement(isA<HydrationAiAction>()));
    expect(actions.first.type, HydrationAiActionType.coachMessage);
    expect(actions.last.type, HydrationAiActionType.suggestHydrationLog);
  });

  test('malformed Gemini output is rejected', () async {
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: const _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":""}]}',
      ),
    );

    await expectLater(
      provider.proposeActions(
        context: _standaloneContext(),
        userQuery: 'bad output',
      ),
      throwsA(isA<GeminiProviderException>()),
    );
  });

  test('oversized Gemini output is rejected', () async {
    final oversized = List.filled(601, 'a').join();
    final provider = GeminiHydrationAiProvider(
      config: const GeminiProviderConfig(apiKey: 'test-key'),
      client: _FakeGeminiClient(
        '{"actions":[{"type":"coachMessage","message":"$oversized"}]}',
      ),
    );

    await expectLater(
      provider.proposeActions(
        context: _standaloneContext(),
        userQuery: 'too long',
      ),
      throwsA(isA<GeminiProviderException>()),
    );
  });

  test('invalid Gemini proposals fall back before app logic trusts them',
      () async {
    final services = HydrionServices.memory();
    final context =
        await services.hydrationContextProvider.getHydrationContext();
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: const _StaticAiProvider([
        SuggestHydrationLogAction(
          message: 'Log 0 ml.',
          volumeMl: 0,
        ),
      ]),
      localRulesProvider: const _StaticLocalRulesProvider(
        message: 'local_rules handled the unsafe proposal',
      ),
      contextProvider: _StaticContextProvider(context),
      actionValidator: validator,
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'make a bad suggestion',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, 'local_rules handled the unsafe proposal');
    expect(services.hydrationRepository.logs, isEmpty);
  });

  test('Hydrion still works with local rules mode only', () async {
    final services = HydrionServices.memory();

    expect(
      services.aiRuntimeConfig.provider,
      HydrionAiProviderSelection.localRules,
    );
    expect(services.capabilityReporter.capabilities.geminiConfigured, isFalse);

    final response = await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'How am I doing?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, contains('on-device guidance'));
  });

  test('selecting Gemini without configuration still falls back locally',
      () async {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
      ),
    );

    expect(
        services.aiRuntimeConfig.provider, HydrionAiProviderSelection.gemini);
    expect(services.aiRuntimeConfig.shouldUseGemini, isFalse);
    expect(services.capabilityReporter.capabilities.geminiConfigured, isFalse);

    final response = await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'use Gemini',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, contains('on-device guidance'));
  });

  test('configured Gemini does not receive context until consent is enabled',
      () async {
    final context = _standaloneContext().copyWithGeminiConfigured();
    final primaryProvider = _CountingAiProvider(
      const [CoachMessageAction(message: 'external provider response')],
    );
    final contextProvider = _CountingContextProvider(context);
    final providerHealth = LocalProviderHealthReporter.fromConfig(
      const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final coach = ProviderBackedHydrationCoach(
      selectedProvider: HydrionAiProviderSelection.gemini,
      primaryProvider: primaryProvider,
      localRulesProvider:
          const _StaticLocalRulesProvider(message: 'local privacy fallback'),
      contextProvider: contextProvider,
      providerHealth: providerHealth,
      nonLocalProviderEnabled: () => false,
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'use configured provider',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, 'local privacy fallback');
    expect(primaryProvider.callCount, 0);
    expect(contextProvider.callCount, 0);
    expect(providerHealth.providerHealth.activeProvider,
        HydrionAiProviderKind.localRules);
    expect(providerHealth.providerHealth.diagnostic.requestAttempted, isFalse);
  });

  test('configured Gemini is reported as inactive without provider consent',
      () {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    final capabilities = services.capabilityReporter.capabilities;
    final health = services.providerHealthReporter.providerHealth;

    expect(capabilities.geminiConfigured, isTrue);
    expect(capabilities.cloudAi, isFalse);
    expect(health.geminiConfigured, isTrue);
    expect(health.geminiAvailable, isFalse);
    expect(health.activeProvider, HydrionAiProviderKind.localRules);
    expect(health.privacyDisclosureRequired, isTrue);
    expect(health.privacyConsentRecorded, isFalse);
    expect(health.diagnostic.responseEnvelopePhase,
        ProviderDiagnosticCodes.providerConsentRequired);
  });
}

HydrationContext _standaloneContext() {
  return HydrationContext(
    dailySummary: DailyHydrationSummary(
      date: DateTime(2026, 5, 25),
      consumedMl: 0,
      targetMl: 2200,
      entryCount: 0,
    ),
    lifetimeMl: 0,
    eventCount: 0,
    reminder: const ReminderContext.empty(),
    challenge: const ChallengeContext.none(),
    capabilities: const CapabilityContext.standalone(),
  );
}

Map<String, Object?> _geminiEnvelope(String text) {
  return {
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  };
}

String _fakeGoogleKey() => 'AIza${'A' * 35}';

String _fakeOpenAiKey() => 'sk-${'A' * 36}';

ProviderBackedHydrationCoach _geminiCoachWith({
  required HydrationAiProvider provider,
  required LocalProviderHealthReporter providerHealth,
  required HydrationContext context,
}) {
  return ProviderBackedHydrationCoach(
    selectedProvider: HydrionAiProviderSelection.gemini,
    primaryProvider: provider,
    localRulesProvider:
        const _StaticLocalRulesProvider(message: 'local fallback'),
    contextProvider: _StaticContextProvider(context),
    actionValidator: const HydrationAiActionValidator(),
    providerHealth: providerHealth,
  );
}

extension on HydrationContext {
  HydrationContext copyWithGeminiConfigured() {
    return HydrationContext(
      dailySummary: dailySummary,
      lifetimeMl: lifetimeMl,
      eventCount: eventCount,
      reminder: reminder,
      challenge: challenge,
      capabilities: CapabilityContext(
        localPersistence: capabilities.localPersistence,
        elkaConfigured: capabilities.elkaConfigured,
        geminiConfigured: true,
        cloudAi: true,
        cloudSync: capabilities.cloudSync,
        voiceInput: capabilities.voiceInput,
        bleSync: capabilities.bleSync,
        healthSync: capabilities.healthSync,
        osNotifications: capabilities.osNotifications,
        socialSync: capabilities.socialSync,
      ),
    );
  }
}

class _FakeGeminiClient implements GeminiContentClient {
  final String text;

  const _FakeGeminiClient(this.text);

  @override
  Future<String> generateContent({
    required GeminiProviderConfig config,
    required String prompt,
  }) async {
    expect(prompt, contains('HydrationContext'));
    expect(prompt, contains('"dailySummary"'));
    return text;
  }
}

class _ThrowingAiProvider implements HydrationAiProvider {
  const _ThrowingAiProvider();

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) {
    return Future<List<HydrationAiAction>>.error(
      const GeminiProviderException('simulated Gemini failure'),
    );
  }
}

class _StaticAiProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;

  const _StaticAiProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return actions;
  }
}

class _CountingAiProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;
  int callCount = 0;

  _CountingAiProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    callCount += 1;
    return actions;
  }
}

class _StaticLocalRulesProvider implements HydrationCoach, HydrationAiProvider {
  final String message;

  const _StaticLocalRulesProvider({required this.message});

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    return message;
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    return message;
  }

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return [CoachMessageAction(message: message)];
  }
}

class _StaticContextProvider implements HydrationContextProvider {
  final HydrationContext context;

  const _StaticContextProvider(this.context);

  @override
  Future<HydrationContext> getHydrationContext({
    DateTime? now,
    HydrationCoachDigestKey digestKey = HydrationCoachDigestKey.weeklyDigest,
  }) async {
    return context;
  }
}

class _CountingContextProvider implements HydrationContextProvider {
  final HydrationContext context;
  int callCount = 0;

  _CountingContextProvider(this.context);

  @override
  Future<HydrationContext> getHydrationContext({
    DateTime? now,
    HydrationCoachDigestKey digestKey = HydrationCoachDigestKey.weeklyDigest,
  }) async {
    callCount += 1;
    return context;
  }
}
