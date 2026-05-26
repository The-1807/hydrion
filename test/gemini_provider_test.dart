import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/gemini/gemini_adapter.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/ai_provider_config.dart';
import 'package:hydrion/services/hydration_ai_orchestrator.dart';
import 'package:hydrion/services/provider_health.dart';

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

    expect(response, contains('local deterministic mode'));
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

    expect(response, contains('local deterministic mode'));
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
