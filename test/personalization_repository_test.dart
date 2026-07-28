import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
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
    expect(json['schemaVersion'], 1);
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
}
