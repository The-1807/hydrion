import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/achievement_service.dart';
import 'package:hydrion/services/ble_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('hydration logs persist across repository reloads', () async {
    final firstStore = await SharedPreferencesHydrionStore.create();
    final firstRepository = await HydrationRepository.load(firstStore);
    final timestamp = DateTime(2026, 5, 23, 10, 30);

    await firstRepository.addLog(
      volumeMl: 350,
      timestamp: timestamp,
      source: 'test',
    );

    final secondStore = await SharedPreferencesHydrionStore.create();
    final secondRepository = await HydrationRepository.load(secondStore);

    expect(secondRepository.logs, hasLength(1));
    expect(secondRepository.logs.single.volumeMl, 350);
    expect(secondRepository.logs.single.timestamp, timestamp);
    expect(secondRepository.totalForDay(timestamp), 350);
  });

  test('daily totals reset at local day boundaries', () async {
    final repository = HydrationRepository.memory();
    final today = DateTime(2026, 5, 23, 10, 30);
    final yesterday = today.subtract(const Duration(days: 1));

    await repository.addLog(
      volumeMl: 500,
      timestamp: yesterday,
      source: 'test',
    );
    await repository.addLog(
      volumeMl: 350,
      timestamp: today,
      source: 'test',
    );

    expect(repository.totalForDay(yesterday), 500);
    expect(repository.totalForDay(today), 350);
  });

  test('hydration logs can be edited and deleted', () async {
    final store = await SharedPreferencesHydrionStore.create();
    final repository = await HydrationRepository.load(store);
    final timestamp = DateTime(2026, 5, 23, 10, 30);

    final log = await repository.addLog(
      volumeMl: 350,
      timestamp: timestamp,
      source: 'test',
    );

    expect(log, isNotNull);
    expect(
      await repository.updateLog(id: log!.id, volumeMl: 500),
      isTrue,
    );

    var reloaded = await HydrationRepository.load(
      await SharedPreferencesHydrionStore.create(),
    );
    final updatedLog = reloaded.logs.single;
    expect(updatedLog.volumeMl, 500);

    expect(await reloaded.deleteLog(log.id), isTrue);
    reloaded = await HydrationRepository.load(
      await SharedPreferencesHydrionStore.create(),
    );
    expect(reloaded.logs, isEmpty);

    expect(await reloaded.restoreLog(updatedLog), isTrue);
    reloaded = await HydrationRepository.load(
      await SharedPreferencesHydrionStore.create(),
    );
    expect(reloaded.logs.single.id, log.id);
    expect(reloaded.logs.single.volumeMl, 500);
    expect(reloaded.logs.single.timestamp, timestamp);
  });

  test('user locale persists across repository reloads', () async {
    final firstStore = await SharedPreferencesHydrionStore.create();
    final firstRepository = await UserSettingsRepository.load(firstStore);

    await firstRepository.setLocale(const Locale('fr', 'FR'));

    final secondStore = await SharedPreferencesHydrionStore.create();
    final secondRepository = await UserSettingsRepository.load(secondStore);

    expect(secondRepository.settings.locale, const Locale('fr', 'FR'));
  });

  test('user hydration preferences persist across repository reloads',
      () async {
    final firstStore = await SharedPreferencesHydrionStore.create();
    final firstRepository = await UserSettingsRepository.load(firstStore);

    expect(await firstRepository.setDailyGoalMl(1850), isTrue);
    await firstRepository.setReusableContainerEnabled(true);

    final secondStore = await SharedPreferencesHydrionStore.create();
    final secondRepository = await UserSettingsRepository.load(secondStore);

    expect(secondRepository.settings.dailyGoalMl, 1850);
    expect(secondRepository.settings.reusableContainerEnabled, isTrue);
  });

  test('reminder definitions persist as app data', () async {
    final firstStore = await SharedPreferencesHydrionStore.create();
    final firstRepository = await ReminderRepository.load(firstStore);
    final triggerTime = DateTime(2026, 5, 23, 14, 45);

    await firstRepository.save(
      triggerTime: triggerTime,
      message: 'Drink water',
      priority: 2,
    );

    final secondStore = await SharedPreferencesHydrionStore.create();
    final secondRepository = await ReminderRepository.load(secondStore);

    expect(secondRepository.reminders, hasLength(1));
    expect(secondRepository.reminders.single.triggerTime, triggerTime);
    expect(secondRepository.reminders.single.message, 'Drink water');
    expect(secondRepository.reminders.single.priority, 2);
  });

  test('challenge join state persists as app data', () async {
    final firstStore = await SharedPreferencesHydrionStore.create();
    final firstRepository = await ChallengeRepository.load(firstStore);

    await firstRepository.join(
      id: 'steady-sip-test',
      name: 'Steady Sip',
      description: 'Complete the local challenge.',
      targetMl: 2000,
      durationDays: 7,
      joinedAt: DateTime(2026, 5, 23),
    );

    final secondStore = await SharedPreferencesHydrionStore.create();
    final secondRepository = await ChallengeRepository.load(secondStore);

    expect(secondRepository.activeChallenge?.id, 'steady-sip-test');
    expect(secondRepository.activeChallenge?.targetMl, 2000);
  });

  test('services share one hydration source of truth', () async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore());
    final timestamp = DateTime.now();

    expect(await services.settingsRepository.setDailyGoalMl(1800), isTrue);
    await services.wearables.syncHydration(500, timestamp);

    final logs = await services.wearables.fetchHydrationData(
      timestamp.subtract(const Duration(hours: 1)),
      timestamp.add(const Duration(hours: 1)),
    );
    final summary =
        await services.hydrationSummaryService.getHydrationSummary();
    final plasticSavedKg = await services.ecoTracker.getTotalPlasticSavedKg();
    final context = await services.hydrationContextProvider
        .getHydrationContext(now: timestamp);

    expect(logs.single.volumeMl, 500);
    expect(summary.consumedMl, 500);
    expect(summary.targetMl, 1800);
    expect(summary.entryCount, 1);
    expect(plasticSavedKg, 0);
    expect(context.dailySummary.consumedMl, 500);
    expect(context.dailySummary.targetMl, 1800);
    expect(context.eventCount, 1);

    await services.settingsRepository.setReusableContainerEnabled(true);
    expect(
      await services.ecoTracker.getTotalPlasticSavedKg(),
      closeTo(0.01, 0.0001),
    );
  });

  test('hydration context refreshes after new hydration logs', () async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore());
    final timestamp = DateTime(2026, 5, 23, 10, 30);

    final before = await services.hydrationContextProvider
        .getHydrationContext(now: timestamp);

    await services.hydrationRepository.addLog(
      volumeMl: 400,
      timestamp: timestamp,
      source: 'test',
    );

    final after = await services.hydrationContextProvider
        .getHydrationContext(now: timestamp);

    expect(before.dailySummary.consumedMl, 0);
    expect(after.dailySummary.consumedMl, 400);
    expect(after.dailySummary.entryCount, 1);
  });

  test('achievements recalculate from current saved logs', () async {
    final repository = HydrationRepository.memory();
    const achievementService = AchievementService();
    final now = DateTime(2026, 5, 23, 12);

    final first = (await repository.addLog(
      volumeMl: 600,
      timestamp: now.subtract(const Duration(hours: 2)),
      source: 'test',
    ))!;
    final second = (await repository.addLog(
      volumeMl: 700,
      timestamp: now.subtract(const Duration(hours: 1)),
      source: 'test',
    ))!;
    final third = (await repository.addLog(
      volumeMl: 900,
      timestamp: now,
      source: 'test',
    ))!;

    var achievements = achievementService.evaluate(
      hydrationRepository: repository,
      now: now,
      activeGoalMl: 2200,
    );
    expect(achievements.dailyGoal.unlocked, isTrue);
    expect(achievements.threeLogsToday.unlocked, isTrue);

    expect(await repository.deleteLog(third.id), isTrue);
    achievements = achievementService.evaluate(
      hydrationRepository: repository,
      now: now,
      activeGoalMl: 2200,
    );
    expect(achievements.dailyGoal.unlocked, isFalse);
    expect(achievements.threeLogsToday.unlocked, isFalse);

    expect(await repository.restoreLog(third), isTrue);
    achievements = achievementService.evaluate(
      hydrationRepository: repository,
      now: now,
      activeGoalMl: 2200,
    );
    expect(repository.logs.map((log) => log.id), contains(first.id));
    expect(repository.logs.map((log) => log.id), contains(second.id));
    expect(achievements.dailyGoal.unlocked, isTrue);
    expect(achievements.threeLogsToday.unlocked, isTrue);
  });

  test('coach and platform services report honest local fallback status',
      () async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore());
    final timestamp = DateTime.now();

    await services.hydrationRepository.addLog(
      volumeMl: 750,
      timestamp: timestamp,
      source: 'test',
    );

    final response = await services.hydrationCoach.getCoachingAdvice(
      userQuery: 'How am I doing?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(response, contains('on-device guidance'));
    expect(response, contains('Today: 750 ml'));
    expect(response, contains('across 1 saved log'));
    expect(services.notificationService.supportsOsNotifications, isTrue);
    expect(services.voice.isAvailable, isFalse);
    expect(await services.voice.initialize(), isFalse);
    expect(services.wearables.supportsBleSync, isFalse);
    expect(services.wearables.supportsHealthSync, isFalse);
    expect(services.capabilityReporter.capabilities.elkaConfigured, isFalse);
    expect(services.elkaAdapter.isConfigured, isFalse);
    expect(BLEService().isAvailable, isFalse);
  });
}
