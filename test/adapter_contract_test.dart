import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/elka/elka_adapter.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';

void main() {
  test('local summary adapter derives today summary from hydration logs',
      () async {
    final repository = HydrationRepository.memory();
    final timestamp = DateTime.now();
    await repository.addLog(
      volumeMl: 750,
      timestamp: timestamp,
      source: 'test',
    );
    final summaryService = LocalHydrationSummaryService(
      hydrationRepository: repository,
      settingsRepository: UserSettingsRepository.memory(),
    );

    final summary = await summaryService.getHydrationSummary();

    expect(summary.consumedMl, 750);
    expect(summary.entryCount, 1);
    expect(summary.targetMl, 2200);
    expect(summary.hydrationPercent, closeTo(34.09, 0.1));
  });

  test('local coach adapter uses typed persisted hydration context', () async {
    final services = HydrionServices.memory();
    await services.hydrationRepository.addLog(
      volumeMl: 600,
      timestamp: DateTime.now(),
      source: 'test',
    );

    final context =
        await services.hydrationContextProvider.getHydrationContext();
    final response = await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'How am I doing?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(context.dailySummary.consumedMl, 600);
    expect(context.lifetimeMl, 600);
    expect(context.eventCount, 1);
    expect(response, contains('on-device guidance'));
    expect(response, contains('Today: 600 ml'));
    expect(response, contains('across 1 saved log'));
  });

  test('local challenge adapter produces deterministic challenge contracts',
      () async {
    const generator = LocalChallengeGenerator();

    final challenge = await generator.createChallenge(
      userLevel: 'intermediate',
    );

    expect(challenge.id, 'around-the-world-infusion-week');
    expect(challenge.targetMl, 2200);
    expect(challenge.durationDays, 7);
  });

  test('local command parser returns stable hydration intents', () async {
    const parser = LocalHydrationCommandParser();

    final logCommand = await parser.parseCommandToJson('log 450 ml');
    final reminderCommand = await parser.parseCommandToJson('remind me later');

    expect(logCommand['intent'], 'log_hydration');
    expect((logCommand['entities'] as Map)['volumeMl'], 450);
    expect(reminderCommand['intent'], 'schedule_reminder');
  });

  test('local capabilities keep standalone mode explicit', () {
    final reporter = LocalAppCapabilityReporter();
    final capabilities = reporter.capabilities;

    expect(capabilities.localPersistence, isTrue);
    expect(capabilities.elkaConfigured, isFalse);
    expect(capabilities.geminiConfigured, isFalse);
    expect(capabilities.cloudAi, isFalse);
    expect(capabilities.cloudSync, isFalse);
    expect(capabilities.voiceInput, isFalse);
    expect(capabilities.bleSync, isFalse);
    expect(capabilities.healthSync, isFalse);
    expect(capabilities.osNotifications, isFalse);
    expect(capabilities.socialSync, isFalse);
    expect(capabilities.modeLabel, 'Standalone local mode');
  });

  test('ELKA shell is compile-safe but unconfigured and non-networked',
      () async {
    const elka = ElkaAdapterShell.unconfigured();

    expect(elka.isConfigured, isFalse);
    expect(elka.capabilities.elkaConfigured, isFalse);

    await expectLater(
      elka.getCoachingAdvice(
        userQuery: 'hello',
        digestKey: HydrationCoachDigestKey.weeklyDigest,
      ),
      throwsA(isA<UnsupportedError>()),
    );

    await expectLater(
      elka.proposeActions(
        context: _standaloneContext(),
        userQuery: 'hello',
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('fake provider can propose typed actions through domain contracts',
      () async {
    const provider = _FakeAiProvider([
      CoachMessageAction(message: 'Typed fake provider response'),
      SuggestHydrationLogAction(
        message: 'Suggest 250 ml',
        volumeMl: 250,
      ),
    ]);

    final actions = await provider.proposeActions(
      context: _standaloneContext(),
      userQuery: 'what next?',
    );

    expect(actions.first.type, HydrationAiActionType.coachMessage);
    expect(actions.last.type, HydrationAiActionType.suggestHydrationLog);
  });

  test('unsupported provider actions are blocked by capability rules',
      () async {
    const validator = HydrationAiActionValidator();
    final context = _standaloneContext();
    const provider = _FakeAiProvider([
      SuggestReminderAction(
        message: 'OS notifications are scheduled and will fire.',
        delay: Duration(minutes: 20),
        claimsOsNotificationScheduled: true,
      ),
      CoachMessageAction(
        message: 'Gemini is connected and voice input is enabled.',
      ),
    ]);

    final actions = await provider.proposeActions(
      context: context,
      userQuery: 'schedule this',
    );
    final reminderResult = validator.validate(
      actions.first,
      context.capabilities,
    );
    final claimResult = validator.validate(
      actions.last,
      context.capabilities,
    );

    expect(reminderResult.isAllowed, isFalse);
    expect(reminderResult.action.type,
        HydrationAiActionType.unsupportedCapabilityNotice);
    expect(
      reminderResult.blockedCapabilities,
      contains(HydrionCapability.osNotifications),
    );
    expect(claimResult.isAllowed, isFalse);
    expect(claimResult.blockedCapabilities, contains(HydrionCapability.gemini));
    expect(
      claimResult.blockedCapabilities,
      contains(HydrionCapability.voiceInput),
    );
  });

  testWidgets('app shell swaps to fake domain adapters without UI changes',
      (tester) async {
    final base = HydrionServices.memory();
    final services = HydrionServices(
      localStore: base.localStore,
      hydrationRepository: base.hydrationRepository,
      settingsRepository: base.settingsRepository,
      reminderRepository: base.reminderRepository,
      challengeRepository: base.challengeRepository,
      coreBridge: base.coreBridge,
      permissions: base.permissions,
      i18n: base.i18n,
      notificationService: base.notificationService,
      locationService: base.locationService,
      weatherForecastService: base.weatherForecastService,
      dailyWeatherGoalCoordinator: base.dailyWeatherGoalCoordinator,
      profilePhotoPicker: base.profilePhotoPicker,
      hydrationSummaryService: const _FakeSummaryService(),
      hydrationContextProvider: base.hydrationContextProvider,
      aiActionValidator: base.aiActionValidator,
      hydrationCoach: const _FakeCoach(),
      coachSuggestionService: const _FakeCoachSuggestionService(),
      aiActionExecutor: base.aiActionExecutor,
      challengeGenerator: const _FakeChallengeGenerator(),
      commandParser: const _FakeCommandParser(),
      capabilityReporter: const _FakeCapabilityReporter(),
      providerHealthReporter: base.providerHealthReporter,
      elkaAdapter: base.elkaAdapter,
      voice: base.voice,
      voiceBridge: base.voiceBridge,
      wearables: base.wearables,
      ecoTracker: base.ecoTracker,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('0 ml / 2200 ml'), findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    navigationBar.onDestinationSelected?.call(3);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'adapter check');
    final sendButton = find.widgetWithIcon(FilledButton, Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('Fake coach adapter response'), findsOneWidget);
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

class _FakeSummaryService implements HydrationSummaryService {
  const _FakeSummaryService();

  @override
  Future<HydrationSummary> getHydrationSummary() async {
    return const HydrationSummary(
      hydrationPercent: 41.1,
      entryCount: 9,
      consumedMl: 1234,
      targetMl: 3000,
    );
  }
}

class _FakeCoach implements HydrationCoach, HydrationAiProvider {
  const _FakeCoach();

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    return 'Fake coach advice for $userQuery';
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    return 'Fake coach adapter response';
  }

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return const [
      CoachMessageAction(message: 'Fake coach adapter response'),
    ];
  }
}

class _FakeAiProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;

  const _FakeAiProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return actions;
  }
}

class _FakeCoachSuggestionService implements CoachSuggestionService {
  const _FakeCoachSuggestionService();

  @override
  Future<CoachTurn> ask({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    return const CoachTurn(
      message: 'Fake coach adapter response',
      suggestions: <CoachSuggestionCard>[],
    );
  }

  @override
  Future<CoachSuggestionExecutionView> confirm(String suggestionId) async {
    return CoachSuggestionExecutionView(
      suggestionId: suggestionId,
      status: CoachSuggestionStatus.rejected,
    );
  }

  @override
  void dismiss(String suggestionId) {}
}

class _FakeChallengeGenerator implements ChallengeGenerator {
  const _FakeChallengeGenerator();

  @override
  Future<HydrationChallenge> createChallenge(
      {required String userLevel}) async {
    return const HydrationChallenge(
      id: 'fake-challenge',
      name: 'Fake Challenge',
      description: 'Generated by fake adapter.',
      targetMl: 1800,
      durationDays: 3,
    );
  }
}

class _FakeCommandParser implements HydrationCommandParser {
  const _FakeCommandParser();

  @override
  Future<Map<String, dynamic>> parseCommandToJson(String command) async {
    return {
      'intent': 'fake_command',
      'entities': {'command': command},
    };
  }
}

class _FakeCapabilityReporter implements AppCapabilityReporter {
  const _FakeCapabilityReporter();

  @override
  AppCapabilities get capabilities => const AppCapabilities.standalone();

  @override
  void updateCapabilities(AppCapabilities capabilities) {}
}
