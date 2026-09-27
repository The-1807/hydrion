import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/services/health_data_persistence_types.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';

import 'support/architecture_test_support.dart';

// Synthetic values only. These tests intentionally expose OPEN defects.
void main() {
  test(
    'DATA-007 regression: newer accepted fallback survives restart',
    () async {
      final store = MemoryHydrionStore();
      final secure = _ControlledSecureStore();
      final repository =
          await BodyMetricsRepository.load(store, secureStore: secure);
      await repository.save(const HydrionBodyMetrics(weightKg: 70),
          femaleProfile: false);
      secure.failWrites = true;
      expect(
          await repository.update(weightKg: 71, femaleProfile: false), isTrue);
      expect(repository.metrics.weightKg, 71);
      expect(
          (jsonDecode(store.snapshot[BodyMetricsRepository.storageKey]!)
              as Map)['weightKg'],
          71);
      final restarted =
          await BodyMetricsRepository.load(store, secureStore: secure);
      expect(restarted.metrics.weightKg, 71,
          reason: 'Newer accepted revision must outrank the old secure copy');
    },
  );

  characterizationTest(
    'HTD-DATA-008',
    'a silently unsuccessful secure delete lets data reappear',
    desiredInvariant: 'unverified deletion is pending, never successful',
    body: () async {
      final store = MemoryHydrionStore();
      final secure = _ControlledSecureStore();
      final repository =
          await BodyMetricsRepository.load(store, secureStore: secure);
      await repository.save(const HydrionBodyMetrics(weightKg: 70),
          femaleProfile: false);
      secure.ignoreDeletes = true;
      await repository.clear();
      expect(repository.metrics.weightKg, isNull);
      expect(store.snapshot[BodyMetricsRepository.storageKey], isNull);
      final restarted =
          await BodyMetricsRepository.load(store, secureStore: secure);
      expect(restarted.metrics.weightKg, 70);
    },
  );

  characterizationTest(
    'HTD-DATA-003',
    'fetch includes next midnight while daily total excludes it',
    desiredInvariant: 'all daily consumers use the same half-open interval',
    body: () async {
      final repository = HydrationRepository.memory();
      final day = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 2);
      await repository.addLog(volumeMl: 150, timestamp: end);
      expect(repository.fetch(day, end), hasLength(1));
      expect(repository.totalForDay(day), 0);
      expect(repository.totalForDay(end), 150);
    },
  );

  characterizationTest(
    'HTD-ORCH-001',
    'coordinator apply accepts a recommendation after clinician policy changes',
    desiredInvariant: 'application revalidates the current decision policy',
    body: () async {
      final settings = UserSettingsRepository.memory(const Locale('en'));
      final body = BodyMetricsRepository.memory();
      final coordinator = DailyHydrationRecommendationCoordinator(
        settingsRepository: settings,
        bodyMetricsRepository: body,
        dailyContextRepository: DailyHydrationContextRepository.memory(),
        stateRepository: PersonalizationStateRepository.memory(),
      );
      final now = DateTime(2026, 1, 1, 12);
      final old = await coordinator.calculate(now: now);
      await body.save(
        const HydrionBodyMetrics(
          fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
          clinicianTargetMl: 1800,
        ),
        femaleProfile: false,
      );
      final current = await coordinator.calculate(now: now);
      expect(current.mayAutoApply, isFalse);
      expect(current.roundedRecommendedGoalMl, 1800);
      expect(old.roundedRecommendedGoalMl, isNot(1800));
      expect(await coordinator.apply(old, now: now), isTrue);
      expect(settings.settings.dailyGoalMl, old.roundedRecommendedGoalMl);
    },
  );

  architectureInvariantTest<bool>(
    'an unsupported health persistence result is not ready',
    observe: () => const HealthPersistenceResult(
      HealthPersistenceStatus.unsupportedPlatform,
    ).isReady,
    invariant: isFalse,
    counterexample: true,
  );
}

/// Models supported-but-failing storage, unlike the existing unsupported fake.
class _ControlledSecureStore extends MemorySensitiveBodyMetricsStore {
  bool failWrites = false;
  bool ignoreDeletes = false;

  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (failWrites) throw StateError('synthetic write failure');
    await super.write(fields);
  }

  @override
  Future<void> delete() async {
    // Models the native wrapper's swallowed failure, not a successful delete.
    if (!ignoreDeletes) await super.delete();
  }
}
