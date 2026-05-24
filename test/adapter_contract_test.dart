import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/elka/elka_adapter.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
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
}
