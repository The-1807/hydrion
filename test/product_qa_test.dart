import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/ai_provider_config.dart';

void main() {
  Future<void> pumpHydrion(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    HydrionServices? services,
  }) async {
    final appServices = services ?? HydrionServices.memory();
    await appServices.i18n.setLocale(locale);
    await tester.pumpWidget(HydrionApp(services: appServices));
    await tester.pumpAndSettle();
  }

  Future<void> openLogHistory(WidgetTester tester) async {
    final history = find.byKey(const Key('home-log-history'));
    await tester.ensureVisible(history);
    await tester.pumpAndSettle();
    await tester.tap(history);
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, Key key) async {
    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    navigationBar.onDestinationSelected?.call(_tabIndex(key));
    await tester.pumpAndSettle();
  }

  Future<void> openDebugDiagnostics(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Debug diagnostics'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug diagnostics'));
    await tester.pumpAndSettle();
  }

  HydrionServices geminiSuccessServices({
    String response = 'Gemini says: take a few steady sips.',
  }) {
    final base = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'AIza-test-key-tail'),
      ),
    );
    base.capabilityReporter.updateCapabilities(
      base.capabilityReporter.capabilities.copyWith(
        geminiConfigured: true,
        cloudAi: true,
      ),
    );
    final coach = _StaticCoach(response);
    return _withOverrides(
      base,
      hydrationCoach: coach,
      coachSuggestionService: _StaticCoachSuggestionService(
        message: response,
      ),
      providerHealthReporter: _StaticProviderHealthReporter(
        _geminiSuccessHealth(),
      ),
    );
  }

  testWidgets('product QA: English localized app shell', (tester) async {
    await pumpHydrion(tester);

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Log hydration'), findsOneWidget);
    expect(find.text('Log 250 ml'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('product QA: Spanish localized app shell', (tester) async {
    await pumpHydrion(tester, locale: const Locale('es'));

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Registrar hidratación'), findsOneWidget);
    expect(find.text('Registrar 250 ml'), findsOneWidget);
  });

  testWidgets('product QA: French localized app shell', (tester) async {
    await pumpHydrion(tester, locale: const Locale('fr'));

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Enregistrer hydratation'), findsOneWidget);
    expect(find.text('Enregistrer 250 ml'), findsOneWidget);
  });

  testWidgets('product QA: small mobile viewport keeps Home usable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final services = HydrionServices.memory();
    await pumpHydrion(tester, services: services);

    expect(find.byKey(const Key('home-logo')), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
    await tester.pumpAndSettle();
    final amountChip = find.byKey(const Key('quick-volume-350'));
    expect(amountChip, findsOneWidget);
    tester.widget<ChoiceChip>(amountChip).onSelected?.call(true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('log-water-button')));
    await tester.pumpAndSettle();
    final dynamic logButton =
        tester.widget(find.byKey(const Key('log-water-button')));
    logButton.onPressed();
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.totalForDay(DateTime.now()), 350);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('350 ml / 2200 ml'), findsOneWidget);
  });

  testWidgets('product QA: Settings capability dashboard is honest',
      (tester) async {
    await pumpHydrion(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Standalone local mode'), findsOneWidget);
    expect(find.text('Language choice is saved locally.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily hydration goal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily hydration goal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reusable container'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reusable container'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Local-first privacy'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Local-first privacy'), findsOneWidget);
    expect(find.text('AI provider status'), findsNothing);
    expect(find.text('Provider privacy'), findsNothing);
    expect(find.text('local_rules'), findsNothing);

    await openDebugDiagnostics(tester);

    expect(find.text('AI provider status'), findsOneWidget);
    expect(find.text('On-device guidance'), findsWidgets);
    expect(find.text('Runtime feature status'), findsOneWidget);
    expect(find.text('Local persistence'), findsOneWidget);
    expect(find.text('ELKA adapter'), findsOneWidget);
    expect(find.text('Unconfigured'), findsWidgets);
    expect(find.text('Cloud AI'), findsOneWidget);
    expect(find.text('Voice input'), findsOneWidget);
    expect(find.text('Disabled'), findsWidgets);
  });

  testWidgets(
      'product QA: Gemini privacy disclosure is visible when configured',
      (tester) async {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
        gemini: GeminiProviderConfig(apiKey: 'test-key'),
      ),
    );
    await pumpHydrion(tester, services: services);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Gemini provider configured'), findsOneWidget);
    expect(
      find.text(
        'Gemini is configured but disabled until provider privacy consent is enabled.',
      ),
      findsOneWidget,
    );
    expect(find.text('AI provider status'), findsNothing);
    expect(find.text('Endpoint host'), findsNothing);

    await openDebugDiagnostics(tester);

    expect(find.text('Gemini health'), findsOneWidget);
    expect(find.text('Gemini configured'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gemini diagnostics'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gemini diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Request attempted'), findsOneWidget);
    expect(
      find.textContaining('Hydrion may send typed hydration context to Gemini'),
      findsOneWidget,
    );
    expect(
      find.text(
          'Non-local AI requires explicit user consent before production use.'),
      findsOneWidget,
    );
  });

  testWidgets('product QA: provider fallback reason is visible safely',
      (tester) async {
    final services = HydrionServices.memory(
      aiRuntimeConfig: const HydrionAiRuntimeConfig(
        provider: HydrionAiProviderSelection.gemini,
      ),
    );

    await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'Should use Gemini?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );
    await pumpHydrion(tester, services: services);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('AI provider status'), findsNothing);
    expect(find.textContaining('no_api_key'), findsNothing);

    await openDebugDiagnostics(tester);

    expect(find.text('Using on-device guidance'), findsOneWidget);
    await tester.tap(find.text('Gemini diagnostics'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no_api_key'), findsWidgets);
    expect(find.text('Last diagnostic'), findsOneWidget);
    expect(find.text('Request attempted'), findsOneWidget);
    expect(find.text('No'), findsWidgets);
    expect(find.textContaining('Should use Gemini?'), findsNothing);
  });

  testWidgets('product QA: Gemini success state is visible safely',
      (tester) async {
    const fullKey = 'AIza-test-key-tail';
    final services = geminiSuccessServices();

    await pumpHydrion(tester, services: services);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('AI provider status'), findsNothing);
    expect(find.text('Selected provider'), findsNothing);
    expect(find.text('Active provider'), findsNothing);
    expect(find.text('Gemini provider configured'), findsOneWidget);
    expect(find.text('Endpoint host'), findsNothing);
    expect(find.text('API key fingerprint'), findsNothing);
    expect(find.text(fullKey), findsNothing);

    await openDebugDiagnostics(tester);

    expect(find.text('Selected provider'), findsOneWidget);
    expect(find.text('Active provider'), findsOneWidget);
    expect(find.text('Gemini configured'), findsOneWidget);
    expect(
      find.text('Gemini is healthy; last response passed validation'),
      findsOneWidget,
    );
    expect(find.text('success'), findsOneWidget);
    expect(find.text('On-device guidance is available'), findsOneWidget);

    await tester.tap(find.text('Gemini diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Endpoint host'), findsOneWidget);
    expect(find.text('generativelanguage.googleapis.com'), findsOneWidget);
    expect(find.text('API key fingerprint'), findsOneWidget);
    expect(find.text('fp:00000000'), findsOneWidget);
    expect(find.text('AIza'), findsNothing);
    expect(find.text('tail'), findsNothing);
    expect(find.text(fullKey), findsNothing);
  });

  testWidgets('product QA: Coach renders Gemini response cleanly',
      (tester) async {
    final services = geminiSuccessServices(
      response: 'You are on pace. Take 250 ml over the next hour.',
    );
    await services.hydrationRepository.addLog(
      volumeMl: 500,
      timestamp: DateTime.now(),
    );
    await pumpHydrion(tester, services: services);

    await openTab(tester, const Key('nav-coach'));

    expect(find.text('Provider coach'), findsOneWidget);
    expect(find.textContaining('Today: 500 / 2200 ml'), findsOneWidget);
    expect(find.textContaining('Active: Gemini'), findsOneWidget);
    expect(find.textContaining('Gemini is active'), findsOneWidget);
    expect(find.textContaining('Last diagnostic'), findsNothing);
    expect(find.textContaining('HydrationContext'), findsNothing);

    await tester.enterText(find.byType(TextField), 'How am I doing?');
    final sendButton = find.widgetWithIcon(FilledButton, Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Coach'), findsWidgets);
    expect(
      find.text('You are on pace. Take 250 ml over the next hour.'),
      findsOneWidget,
    );
    expect(find.textContaining('success'), findsNothing);
    expect(find.textContaining('request_attempted'), findsNothing);
  });

  testWidgets('product QA: English provider status strings render',
      (tester) async {
    await pumpHydrion(tester, services: geminiSuccessServices());
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Gemini provider configured'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Local-first privacy'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Local-first privacy'), findsOneWidget);
    expect(find.text('AI provider status'), findsNothing);
    expect(find.text('local_rules'), findsNothing);
  });

  testWidgets('product QA: Spanish provider status strings render',
      (tester) async {
    await pumpHydrion(
      tester,
      locale: const Locale('es'),
      services: geminiSuccessServices(),
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.textContaining('Proveedor Gemini'), findsWidgets);
    expect(
      find.text('local_rules'),
      findsNothing,
    );
  });

  testWidgets('product QA: French provider status strings render',
      (tester) async {
    await pumpHydrion(
      tester,
      locale: const Locale('fr'),
      services: geminiSuccessServices(),
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fournisseur Gemini'), findsWidgets);
    expect(find.text('local_rules'), findsNothing);
  });

  testWidgets('product QA: empty states are reachable and explicit',
      (tester) async {
    await pumpHydrion(tester);

    await openLogHistory(tester);
    expect(find.text('No hydration logs found'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab(tester, const Key('nav-progress'));
    expect(find.text('No analytics yet'), findsOneWidget);

    await openTab(tester, const Key('nav-profile'));
    await tester.scrollUntilVisible(
      find.text('No reminders yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No reminders yet'), findsOneWidget);
    expect(find.byKey(const Key('route-/ar')), findsNothing);

    await openTab(tester, const Key('nav-challenges'));
    await tester.scrollUntilVisible(
      find.text('No active challenge yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No active challenge yet'), findsOneWidget);
  });

  testWidgets('product QA: Coach fallback flow stays local', (tester) async {
    await pumpHydrion(tester);

    await openTab(tester, const Key('nav-coach'));

    expect(find.text('On-device coach'), findsOneWidget);
    expect(
      find.textContaining('On-device guidance is active'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'How am I doing?');
    final sendButton = find.widgetWithIcon(FilledButton, Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hydrion is using on-device guidance'),
      findsOneWidget,
    );
  });
}

HydrionServices _withOverrides(
  HydrionServices base, {
  required HydrationCoach hydrationCoach,
  CoachSuggestionService? coachSuggestionService,
  required ProviderHealthReporter providerHealthReporter,
}) {
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
    profilePhotoPicker: base.profilePhotoPicker,
    hydrationSummaryService: base.hydrationSummaryService,
    hydrationContextProvider: base.hydrationContextProvider,
    aiActionValidator: base.aiActionValidator,
    hydrationCoach: hydrationCoach,
    coachSuggestionService:
        coachSuggestionService ?? base.coachSuggestionService,
    aiActionExecutor: base.aiActionExecutor,
    challengeGenerator: base.challengeGenerator,
    commandParser: base.commandParser,
    capabilityReporter: base.capabilityReporter,
    providerHealthReporter: providerHealthReporter,
    elkaAdapter: base.elkaAdapter,
    voice: base.voice,
    voiceBridge: base.voiceBridge,
    wearables: base.wearables,
    ecoTracker: base.ecoTracker,
  );
}

ProviderHealthSnapshot _geminiSuccessHealth() {
  final now = DateTime(2026, 6, 1, 12);
  return ProviderHealthSnapshot(
    selectedProvider: HydrionAiProviderKind.gemini,
    activeProvider: HydrionAiProviderKind.gemini,
    localRulesAvailable: true,
    geminiConfigured: true,
    geminiAvailable: true,
    elkaAvailable: false,
    privacyDisclosureRequired: true,
    privacyConsentRecorded: true,
    diagnostic: ProviderDiagnosticSnapshot(
      selectedProvider: HydrionAiProviderKind.gemini,
      activeProvider: HydrionAiProviderKind.gemini,
      configured: true,
      modelId: 'gemini-2.5-flash',
      endpointHost: 'generativelanguage.googleapis.com',
      modelPath: 'models/gemini-2.5-flash',
      apiKeyPresent: true,
      apiKeyLength: 'AIza-test-key-tail'.length,
      apiKeyFingerprint: 'fp:00000000',
      apiKeyContainsWhitespace: false,
      apiKeyWasTrimmed: false,
      apiKeyStartsWithExpectedGooglePrefix: true,
      authHeaderPresent: true,
      authHeaderValueLength: 'AIza-test-key-tail'.length,
      requestAttempted: true,
      responseEnvelopePhase: ProviderDiagnosticCodes.success,
      lastSuccessAt: now,
    ),
  );
}

class _StaticProviderHealthReporter extends ProviderHealthReporter {
  final ProviderHealthSnapshot _health;

  _StaticProviderHealthReporter(this._health);

  @override
  ProviderHealthSnapshot get providerHealth => _health;
}

class _StaticCoach implements HydrationCoach {
  final String response;

  const _StaticCoach(this.response);

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    return response;
  }

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    return response;
  }
}

class _StaticCoachSuggestionService implements CoachSuggestionService {
  final String message;

  const _StaticCoachSuggestionService({
    required this.message,
  });

  @override
  Future<CoachTurn> ask({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    return CoachTurn(
      message: message,
      suggestions: const <CoachSuggestionCard>[],
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

int _tabIndex(Key key) {
  return switch (key) {
    const Key('nav-home') => 0,
    const Key('nav-challenges') => 1,
    const Key('nav-progress') => 2,
    const Key('nav-coach') => 3,
    const Key('nav-profile') => 4,
    _ => throw ArgumentError('Unknown tab key: $key'),
  };
}
