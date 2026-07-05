import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/ai_provider_config.dart';
import 'package:hydrion/services/coach_suggestion_service.dart';

void main() {
  Future<void> pumpHydrion(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    required HydrionServices services,
  }) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await services.i18n.setLocale(locale);
    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
  }

  Future<void> openCoach(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const Key('route-/chat')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('route-/chat')));
    await tester.pumpAndSettle();
  }

  Future<void> sendCoachMessage(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'suggest next steps');
    final sendButton = find.widgetWithIcon(FilledButton, Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
  }

  testWidgets('suggestion cards render, confirm, and dismiss safely',
      (tester) async {
    const fullKey = 'AIza-test-key-tail';
    final base = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: fullKey),
      ),
    );
    final services = _withSuggestionService(
      base,
      LocalCoachSuggestionService(
        provider: const _FakeProvider([
          CoachMessageAction(message: 'Here are safe suggestions.'),
          SuggestHydrationLogAction(
            message: 'Log 250 ml from that bottle.',
            volumeMl: 250,
          ),
          SuggestReminderAction(
            message: 'Check in again in 30 minutes.',
            delay: Duration(minutes: 30),
            priority: 2,
          ),
          SuggestChallengeAction(
            message: 'Try a steady week.',
            challengeId: 'steady-week',
            name: 'Steady Week',
            description: 'Reach target for seven days.',
            targetMl: 2200,
            durationDays: 7,
          ),
          UnsupportedCapabilityNoticeAction(
            message: 'Voice input is not available in this build.',
            capability: HydrionCapability.voiceInput,
          ),
        ]),
        contextProvider: base.hydrationContextProvider,
        validator: base.aiActionValidator,
        executor: base.aiActionExecutor,
        providerHealth: base.providerHealthReporter,
      ),
    );

    await pumpHydrion(tester, services: services);
    await openCoach(tester);
    await sendCoachMessage(tester);

    expect(find.text('Here are safe suggestions.'), findsOneWidget);
    expect(find.text('Hydration log suggestion'), findsOneWidget);
    expect(find.text('Needs confirmation'), findsWidgets);
    expect(find.textContaining(fullKey), findsNothing);
    expect(find.textContaining('HydrationAiAction'), findsNothing);
    expect(find.textContaining('request_attempted'), findsNothing);
    expect(services.hydrationRepository.logs, isEmpty);

    final logApply = find.byKey(const Key(
      'coach-suggestion-confirm-coach-suggestion-1',
    ));
    await tester.ensureVisible(logApply);
    await tester.tap(logApply);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reminder suggestion'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reminder suggestion'), findsOneWidget);
    final reminderApply = find.byKey(const Key(
      'coach-suggestion-confirm-coach-suggestion-2',
    ));
    await tester.ensureVisible(reminderApply);
    await tester.tap(reminderApply);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Challenge suggestion'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Challenge suggestion'), findsOneWidget);
    final challengeApply = find.byKey(const Key(
      'coach-suggestion-confirm-coach-suggestion-3',
    ));
    await tester.ensureVisible(challengeApply);
    await tester.tap(challengeApply);
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.logs.single.volumeMl, 250);
    expect(services.reminderRepository.reminders.single.priority, 2);
    expect(services.challengeRepository.activeChallenge?.id, 'steady-week');
    expect(find.text('Suggestion applied'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Unavailable capability'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Display only'), findsOneWidget);
    final unsupportedDismiss = find.byKey(const Key(
      'coach-suggestion-dismiss-coach-suggestion-4',
    ));
    await tester.ensureVisible(unsupportedDismiss);
    await tester.tap(unsupportedDismiss);
    await tester.pumpAndSettle();

    expect(find.text('Unavailable capability'), findsNothing);
  });

  testWidgets('suggestion card strings render in Spanish', (tester) async {
    final base = HydrionServices.memory();
    final services = _withSuggestionService(
      base,
      LocalCoachSuggestionService(
        provider: const _FakeProvider([
          SuggestHydrationLogAction(
            message: 'Registra 250 ml.',
            volumeMl: 250,
          ),
        ]),
        contextProvider: base.hydrationContextProvider,
        validator: base.aiActionValidator,
        executor: base.aiActionExecutor,
        providerHealth: base.providerHealthReporter,
      ),
    );

    await pumpHydrion(
      tester,
      locale: const Locale('es'),
      services: services,
    );
    await openCoach(tester);
    await sendCoachMessage(tester);

    expect(
      find.text('Sugerencia de registro de hidratación'),
      findsOneWidget,
    );
    expect(find.text('Necesita confirmación'), findsOneWidget);
  });

  testWidgets('suggestion card strings render in French', (tester) async {
    final base = HydrionServices.memory();
    final services = _withSuggestionService(
      base,
      LocalCoachSuggestionService(
        provider: const _FakeProvider([
          SuggestReminderAction(
            message: 'Revenez dans 30 minutes.',
            delay: Duration(minutes: 30),
          ),
        ]),
        contextProvider: base.hydrationContextProvider,
        validator: base.aiActionValidator,
        executor: base.aiActionExecutor,
        providerHealth: base.providerHealthReporter,
      ),
    );

    await pumpHydrion(
      tester,
      locale: const Locale('fr'),
      services: services,
    );
    await openCoach(tester);
    await sendCoachMessage(tester);

    expect(find.text('Suggestion de rappel'), findsOneWidget);
    expect(find.text('Confirmation requise'), findsOneWidget);
  });
}

HydrionServices _withSuggestionService(
  HydrionServices base,
  CoachSuggestionService suggestionService,
) {
  return HydrionServices(
    aiRuntimeConfig: base.aiRuntimeConfig,
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
    hydrationSummaryService: base.hydrationSummaryService,
    hydrationContextProvider: base.hydrationContextProvider,
    aiActionValidator: base.aiActionValidator,
    hydrationCoach: base.hydrationCoach,
    coachSuggestionService: suggestionService,
    aiActionExecutor: base.aiActionExecutor,
    challengeGenerator: base.challengeGenerator,
    commandParser: base.commandParser,
    capabilityReporter: base.capabilityReporter,
    providerHealthReporter: base.providerHealthReporter,
    elkaAdapter: base.elkaAdapter,
    voice: base.voice,
    voiceBridge: base.voiceBridge,
    wearables: base.wearables,
    ecoTracker: base.ecoTracker,
  );
}

class _FakeProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;

  const _FakeProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return actions;
  }
}
