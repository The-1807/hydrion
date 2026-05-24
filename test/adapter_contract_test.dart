import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/elka/elka_adapter.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/services/core_bridge.dart';

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
    );

    final summary = await summaryService.getHydrationSummary();

    expect(summary.consumedMl, 750);
    expect(summary.entryCount, 1);
    expect(summary.targetMl, 2200);
    expect(summary.hydrationPercent, closeTo(34.09, 0.1));
  });

  test('local coach adapter uses persisted hydration digest', () async {
    final repository = HydrationRepository.memory();
    await repository.addLog(
      volumeMl: 600,
      timestamp: DateTime.now(),
      source: 'test',
    );
    final coach = LocalHydrationCoach(
      coreBridge: CoreBridge(hydrationRepository: repository),
    );

    final response = await coach.getCoachingAdvice(
      userQuery: 'How am I doing?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, contains('local deterministic mode'));
    expect(response, contains('Today: 600 ml'));
    expect(response, contains('across 1 saved log'));
  });

  test('local challenge adapter produces deterministic challenge contracts',
      () async {
    const generator = LocalChallengeGenerator();

    final challenge = await generator.createChallenge(
      userLevel: 'intermediate',
    );

    expect(challenge.id, 'steady-sip-7-day-intermediate');
    expect(challenge.targetMl, 2300);
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
    const reporter = LocalAppCapabilityReporter();
    final capabilities = reporter.capabilities;

    expect(capabilities.localPersistence, isTrue);
    expect(capabilities.elkaConfigured, isFalse);
    expect(capabilities.cloudAi, isFalse);
    expect(capabilities.voiceInput, isFalse);
    expect(capabilities.bleSync, isFalse);
    expect(capabilities.healthSync, isFalse);
    expect(capabilities.osNotifications, isFalse);
    expect(capabilities.arVisualization, isFalse);
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
      hydrationSummaryService: const _FakeSummaryService(),
      hydrationCoach: const _FakeCoach(),
      challengeGenerator: const _FakeChallengeGenerator(),
      commandParser: const _FakeCommandParser(),
      capabilityReporter: const _FakeCapabilityReporter(),
      elkaAdapter: base.elkaAdapter,
      voice: base.voice,
      voiceBridge: base.voiceBridge,
      wearables: base.wearables,
      ecoTracker: base.ecoTracker,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1234 / 3000 ml'), findsOneWidget);
    expect(find.text('Fake coach adapter response'), findsOneWidget);
  });
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

class _FakeCoach implements HydrationCoach {
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
}
