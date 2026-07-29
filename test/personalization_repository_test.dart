import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/domain/challenge_recommendation.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('body metrics persist canonical units and schema', () async {
    final store = MemoryHydrionStore();
    final repository = await BodyMetricsRepository.load(store);
    final saved = await repository.save(
      const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 175,
        preferredWeightUnit: HydrionWeightUnit.pounds,
        preferredHeightUnit: HydrionHeightUnit.feetAndInches,
      ),
      femaleProfile: false,
      now: DateTime(2026, 7, 28),
    );
    expect(saved, isTrue);
    final json =
        jsonDecode(store.snapshot[BodyMetricsRepository.storageKey]!) as Map;
    expect(json['schemaVersion'], 2);
    expect(json['weightKg'], 70);
    expect(json['heightCm'], 175);

    final reloaded = await BodyMetricsRepository.load(store);
    expect(reloaded.metrics.weightKg, 70);
    expect(reloaded.metrics.preferredWeightUnit, HydrionWeightUnit.pounds);
  });

  test('invalid input is rejected without replacing valid state', () async {
    final repository = BodyMetricsRepository.memory(
      const HydrionBodyMetrics(weightKg: 70, heightCm: 175),
    );
    expect(
      await repository.update(
        weightKg: 301,
        femaleProfile: false,
      ),
      isFalse,
    );
    expect(repository.metrics.weightKg, 70);
    expect(
      await repository.update(
        reproductiveState: HydrionReproductiveHydrationState.pregnant,
        pregnancyGestationalDays: 295,
        femaleProfile: true,
      ),
      isFalse,
    );
  });

  test('pregnancy duration migrates, persists, and clears canonically',
      () async {
    final legacy = MemoryHydrionStore({
      BodyMetricsRepository.storageKey: jsonEncode({
        'schemaVersion': 1,
        'personalizationEnabled': true,
        'weightKg': 68,
        'heightCm': 171,
        'reproductiveState': 'pregnant',
      }),
    });
    var repository = await BodyMetricsRepository.load(legacy);
    expect(repository.metrics.weightKg, 68);
    expect(repository.metrics.pregnancyGestationalDays, isNull);
    expect(repository.recoveryEvents, isEmpty);

    expect(
      await repository.update(
        pregnancyGestationalDays: 168,
        preferredPregnancyDurationUnit: HydrionPregnancyDurationUnit.months,
        femaleProfile: true,
      ),
      isTrue,
    );
    repository = await BodyMetricsRepository.load(legacy);
    expect(repository.metrics.pregnancyGestationalDays, 168);
    expect(
      repository.metrics.preferredPregnancyDurationUnit,
      HydrionPregnancyDurationUnit.months,
    );
    expect(
      jsonDecode(
          legacy.snapshot[BodyMetricsRepository.storageKey]!)['schemaVersion'],
      2,
    );

    await repository.update(
      reproductiveState: HydrionReproductiveHydrationState.lactating,
      clearPregnancyDuration: true,
      femaleProfile: true,
    );
    expect(repository.metrics.pregnancyGestationalDays, isNull);
  });

  test('pregnancy duration domain boundaries and compatibility are safe', () {
    expect(HydrionBodyMetricsPolicy.validPregnancyDays(1), isTrue);
    expect(HydrionBodyMetricsPolicy.validPregnancyDays(294), isTrue);
    expect(HydrionBodyMetricsPolicy.validPregnancyDays(0), isFalse);
    expect(HydrionBodyMetricsPolicy.validPregnancyDays(295), isFalse);
    expect(HydrionBodyMetricsPolicy.pregnancyWeeksToDays(12), 84);
    expect(HydrionBodyMetricsPolicy.pregnancyMonthsToDays(1), 30);

    final legacyWeeks = HydrionBodyMetrics.fromJson({
      'schemaVersion': 1,
      'reproductiveState': 'pregnant',
      'pregnancyGestationalWeeks': 24,
    });
    expect(legacyWeeks.pregnancyGestationalDays, 168);

    final malformed = HydrionBodyMetrics.fromJson({
      'schemaVersion': 2,
      'reproductiveState': 'pregnant',
      'pregnancyGestationalDays': 12.5,
    });
    expect(malformed.pregnancyGestationalDays, isNull);

    const pregnant = HydrionBodyMetrics(
      reproductiveState: HydrionReproductiveHydrationState.pregnant,
      pregnancyGestationalDays: 84,
    );
    expect(
      pregnant.copyWith(clearPregnancyDuration: true).pregnancyGestationalDays,
      isNull,
    );
    expect(
      pregnant
          .copyWith(
            reproductiveState: HydrionReproductiveHydrationState.none,
          )
          .sanitized(femaleProfile: true)
          .pregnancyGestationalDays,
      isNull,
    );
  });

  test('malformed and invalid storage recover without invented values',
      () async {
    final malformed = MemoryHydrionStore({
      BodyMetricsRepository.storageKey: '{bad',
    });
    final malformedRepository = await BodyMetricsRepository.load(malformed);
    expect(malformedRepository.metrics.weightKg, isNull);
    expect(malformedRepository.recoveryEvents, isNotEmpty);

    final invalid = MemoryHydrionStore({
      BodyMetricsRepository.storageKey:
          '{"schemaVersion":1,"personalizationEnabled":true,'
              '"weightKg":"NaN","heightCm":20}',
    });
    final invalidRepository = await BodyMetricsRepository.load(invalid);
    expect(invalidRepository.metrics.weightKg, isNull);
    expect(invalidRepository.metrics.heightCm, isNull);
  });

  test('non-female profile sanitation removes reproductive state', () async {
    final repository = BodyMetricsRepository.memory();
    await repository.save(
      const HydrionBodyMetrics(
        reproductiveState: HydrionReproductiveHydrationState.pregnant,
      ),
      femaleProfile: false,
    );
    expect(
      repository.metrics.reproductiveState,
      HydrionReproductiveHydrationState.none,
    );
  });

  test('daily contexts are bounded and clearing removes dedicated key',
      () async {
    final store = MemoryHydrionStore();
    final repository = await DailyHydrationContextRepository.load(store);
    for (var i = 1; i <= 20; i++) {
      final date = DateTime(2026, 7, i);
      await repository.save(
        DailyHydrationContext(
          localDateKey: hydrionLocalDateKey(date),
          updatedAt: date,
        ),
      );
    }
    final json = jsonDecode(
      store.snapshot[DailyHydrationContextRepository.storageKey]!,
    ) as Map;
    expect((json['contexts'] as List), hasLength(14));
    await repository.clear();
    expect(
      store.snapshot.containsKey(DailyHydrationContextRepository.storageKey),
      isFalse,
    );
  });

  test('legacy goal mode migrates into independent baseline and weather flags',
      () {
    final manual = UserSettings.fromJson({
      'languageCode': 'en',
      'goalMode': 'manual',
      'dailyGoalMl': 2400,
      'baselineDailyGoalMl': 2400,
    });
    expect(manual.baselineSource, HydrionBaselineSource.manual);
    expect(manual.weatherModifierEnabled, isFalse);

    final weather = UserSettings.fromJson({
      'languageCode': 'en',
      'goalMode': 'weatherInformed',
      'dailyGoalMl': 2500,
      'baselineDailyGoalMl': 2200,
    });
    expect(weather.baselineSource, HydrionBaselineSource.manual);
    expect(weather.weatherModifierEnabled, isTrue);
    expect(weather.baselineDailyGoalMl, 2200);
  });

  test('challenge preferences default, persist, and migrate safely', () async {
    final store = MemoryHydrionStore({
      PersonalizationStateRepository.storageKey: jsonEncode({
        'schemaVersion': 1,
        'lastInputFingerprint': 'legacy',
        'dismissedChallengesByDate': {
          '2026-07-28': ['bottle-bingo'],
        },
      }),
    });
    var repository = await PersonalizationStateRepository.load(store);
    expect(repository.challengePreferences.prefersTimedRoutines, isFalse);
    expect(repository.dismissedForDate('2026-07-28'), contains('bottle-bingo'));
    await repository.setChallengePreferences(
      const ChallengeRecommendationPreferences(
        prefersTimedRoutines: true,
        infusionVarietyInterest: true,
      ),
      now: DateTime(2026, 7, 28),
    );
    repository = await PersonalizationStateRepository.load(store);
    expect(repository.challengePreferences.prefersTimedRoutines, isTrue);
    expect(repository.challengePreferences.infusionVarietyInterest, isTrue);
    final stored = jsonDecode(
      store.snapshot[PersonalizationStateRepository.storageKey]!,
    ) as Map;
    expect(stored['schemaVersion'], 2);

    final malformed = await PersonalizationStateRepository.load(
      MemoryHydrionStore({
        PersonalizationStateRepository.storageKey: jsonEncode({
          'schemaVersion': 2,
          'challengePreferences': {
            'prefersTimedRoutines': 'yes',
            'balancedHydrationInterest': 1,
          },
        }),
      }),
    );
    expect(malformed.challengePreferences.prefersTimedRoutines, isFalse);
    expect(malformed.challengePreferences.balancedHydrationInterest, isFalse);
  });

  test('profile deletion enumerates and clears every personalization key',
      () async {
    final store = MemoryHydrionStore();
    final services = await HydrionServices.fromStore(
      store,
      locationService: FakeHydrionLocationService(),
      notificationAdapter: FakeHydrionNotificationAdapter(
        permission: HydrionNotificationPermissionState.granted,
      ),
    );
    await services.bodyMetricsRepository.save(
      const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 175,
      ),
      femaleProfile: false,
    );
    final now = DateTime(2026, 7, 28);
    await services.dailyHydrationContextRepository.save(
      DailyHydrationContext(
        localDateKey: hydrionLocalDateKey(now),
        updatedAt: now,
      ),
    );
    await services.personalizationStateRepository.dismissChallenge(
      localDateKey: hydrionLocalDateKey(now),
      challengeId: 'bottle-bingo',
    );
    expect(
      store.snapshot.keys,
      containsAll([
        BodyMetricsRepository.storageKey,
        DailyHydrationContextRepository.storageKey,
        PersonalizationStateRepository.storageKey,
      ]),
    );

    final result = await services.localProfileResetService.resetLocalProfile();
    expect(result.isCompleted, isTrue);
    for (final key in [
      BodyMetricsRepository.storageKey,
      DailyHydrationContextRepository.storageKey,
      PersonalizationStateRepository.storageKey,
    ]) {
      expect(store.snapshot.containsKey(key), isFalse, reason: key);
    }
  });
}
