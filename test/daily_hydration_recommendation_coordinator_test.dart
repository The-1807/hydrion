import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('keeping current goal records review for date and fingerprint',
      () async {
    final settings = UserSettingsRepository.memory(const Locale('en'));
    final body = BodyMetricsRepository.memory();
    final daily = DailyHydrationContextRepository.memory();
    final state = PersonalizationStateRepository.memory();
    final coordinator = DailyHydrationRecommendationCoordinator(
      settingsRepository: settings,
      bodyMetricsRepository: body,
      dailyContextRepository: daily,
      stateRepository: state,
    );
    final now = DateTime(2026, 7, 29, 12);
    await coordinator.calculate(now: now);
    final fingerprint = state.lastInputFingerprint!;
    expect(
      state.isRecommendationReviewed(
        localDateKey: '2026-07-29',
        inputFingerprint: fingerprint,
      ),
      isFalse,
    );
    await coordinator.keepCurrentGoal(now: now);
    expect(
      state.isRecommendationReviewed(
        localDateKey: '2026-07-29',
        inputFingerprint: fingerprint,
      ),
      isTrue,
    );
    expect(settings.settings.dailyGoalMl, 2200);
  });

  Future<_Fixture> fixture([HydrionLocalStore? store]) async {
    final localStore = store ?? MemoryHydrionStore();
    final settings = await UserSettingsRepository.load(localStore);
    await settings.setProfile(
      nickname: 'River',
      age: 30,
      sex: HydrionSex.female,
    );
    await settings.setDailyGoalMl(2200);
    await settings.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.personalized,
      weatherModifierEnabled: true,
    );
    final metrics = await BodyMetricsRepository.load(localStore);
    await metrics.save(
      const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 170,
      ),
      femaleProfile: true,
      now: DateTime(2026, 7, 28),
    );
    final contexts = await DailyHydrationContextRepository.load(localStore);
    final state = await PersonalizationStateRepository.load(localStore);
    return _Fixture(
      settings,
      metrics,
      contexts,
      state,
      DailyHydrationRecommendationCoordinator(
        settingsRepository: settings,
        bodyMetricsRepository: metrics,
        dailyContextRepository: contexts,
        stateRepository: state,
      ),
    );
  }

  test('calculation does not apply until explicit user action', () async {
    final value = await fixture();
    final result =
        await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    expect(result.baselineGoalMl, 2100);
    expect(value.settings.settings.dailyGoalMl, 2200);
    await value.coordinator.apply(result, now: DateTime(2026, 7, 28, 9));
    expect(value.settings.settings.dailyGoalMl, 2100);
    expect(value.settings.settings.baselineDailyGoalMl, 2200);
    await value.coordinator.restoreBaseline(now: DateTime(2026, 7, 28, 10));
    expect(value.settings.settings.dailyGoalMl, 2200);
  });

  test('manual override preserves the personalized calculated baseline',
      () async {
    final value = await fixture();

    final saved = await value.settings.setDailyGoalMl(
      2450,
      updateBaseline: false,
      now: DateTime(2026, 7, 28, 11),
    );

    expect(saved, isTrue);
    expect(value.settings.settings.dailyGoalMl, 2450);
    expect(value.settings.settings.baselineDailyGoalMl, 2200);
    expect(value.settings.settings.baselineSource,
        HydrionBaselineSource.personalized);
    expect(value.settings.settings.lastManualGoalEditAt,
        DateTime(2026, 7, 28, 11));
  });

  test('failed selected-goal persistence restores the prior state', () async {
    final store = _FailingWriteStore();
    final value = await fixture(store);
    store.failWrites = true;

    final saved = await value.settings.setDailyGoalMl(
      2450,
      updateBaseline: false,
    );

    expect(saved, isFalse);
    expect(value.settings.settings.dailyGoalMl, 2200);
    expect(value.settings.settings.baselineDailyGoalMl, 2200);
  });

  test('resetting tailored association preserves goal profile and metrics',
      () async {
    final value = await fixture();
    await value.settings.setDailyGoalMl(2450, updateBaseline: false);

    await value.settings.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.manual,
      weatherModifierEnabled: false,
    );

    expect(
        value.settings.settings.baselineSource, HydrionBaselineSource.manual);
    expect(value.settings.settings.dailyGoalMl, 2450);
    expect(value.settings.settings.nickname, 'River');
    expect(value.metrics.metrics.weightKg, 70);
    expect(value.metrics.metrics.heightCm, 170);
  });

  test('context, weather, permission, and local date change fingerprints',
      () async {
    final value = await fixture();
    final first =
        await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    final firstFingerprint = value.state.lastInputFingerprint;
    await value.contexts.save(
      DailyHydrationContext(
        localDateKey: '2026-07-28',
        activityIntensity: HydrionActivityIntensity.moderate,
        activityMinutes: 60,
        environment: HydrionEnvironmentExposure.mostlyOutdoors,
        updatedAt: DateTime(2026, 7, 28, 10),
      ),
    );
    final weather = WeatherSnapshot(
      temperatureC: 35,
      apparentTemperatureC: 37,
      uvIndex: 8,
      observedAt: DateTime(2026, 7, 28, 10),
    );
    final second = await value.coordinator.calculate(
      now: DateTime(2026, 7, 28, 10),
      weather: weather,
      locationPermissionGranted: true,
    );
    expect(value.state.lastInputFingerprint, isNot(firstFingerprint));
    expect(second.roundedRecommendedGoalMl,
        greaterThan(first.roundedRecommendedGoalMl));
    final weatherFingerprint = value.state.lastInputFingerprint;

    final revoked = await value.coordinator.calculate(
      now: DateTime(2026, 7, 28, 10),
      weather: weather,
      locationPermissionGranted: false,
    );
    expect(revoked.weatherAdjustmentMl, 0);
    expect(value.state.lastInputFingerprint, isNot(weatherFingerprint));

    final nextDay =
        await value.coordinator.calculate(now: DateTime(2026, 7, 29, 1));
    expect(nextDay.localDateKey, '2026-07-29');
    expect(nextDay.activityAdjustmentMl, 0);
  });

  test('reproductive and clinician edits recalculate safely', () async {
    final value = await fixture();
    await value.metrics.update(
      reproductiveState: HydrionReproductiveHydrationState.pregnant,
      femaleProfile: true,
    );
    final pregnant =
        await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    expect(pregnant.reproductiveAdjustmentMl, 300);

    await value.metrics.update(
      fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
      clinicianTargetMl: 1800,
      femaleProfile: true,
    );
    final clinician =
        await value.coordinator.calculate(now: DateTime(2026, 7, 28, 10));
    expect(clinician.roundedRecommendedGoalMl, 1800);
    expect(clinician.clinicianTargetOverrodeFactors, isTrue);
  });

  test('same fingerprint does not duplicate personalization writes', () async {
    final store = _CountingStore();
    final value = await fixture(store);
    await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    final writes = store.writeCounts[PersonalizationStateRepository.storageKey];
    await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    expect(
      store.writeCounts[PersonalizationStateRepository.storageKey],
      writes,
    );
  });

  test('recommendations never mutate historical hydration logs', () async {
    final value = await fixture();
    final hydration = HydrationRepository.memory();
    final log = await hydration.addLog(
      volumeMl: 500,
      timestamp: DateTime(2026, 7, 27, 8),
      source: 'manual',
    );
    await value.coordinator.calculate(now: DateTime(2026, 7, 28, 9));
    expect(hydration.logs, hasLength(1));
    expect(hydration.logs.single.id, log!.id);
    expect(hydration.logs.single.timestamp, DateTime(2026, 7, 27, 8));
  });
}

class _Fixture {
  final UserSettingsRepository settings;
  final BodyMetricsRepository metrics;
  final DailyHydrationContextRepository contexts;
  final PersonalizationStateRepository state;
  final DailyHydrationRecommendationCoordinator coordinator;

  const _Fixture(
    this.settings,
    this.metrics,
    this.contexts,
    this.state,
    this.coordinator,
  );
}

class _CountingStore implements HydrionLocalStore {
  final values = <String, String>{};
  final writeCounts = <String, int>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
    writeCounts[key] = (writeCounts[key] ?? 0) + 1;
  }
}

class _FailingWriteStore extends MemoryHydrionStore {
  bool failWrites = false;

  @override
  Future<void> writeString(String key, String value) async {
    if (failWrites) throw StateError('simulated persistence failure');
    await super.writeString(key, value);
  }
}
