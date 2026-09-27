import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/ui/screens/body_metrics_screen.dart';

// DATA-007 desired invariants. Synthetic fixtures only; not native certification.
void main() {
  final now = DateTime(2026, 1, 1, 12);
  const initial = HydrionBodyMetrics(
    weightKg: 70,
    fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
    clinicianTargetMl: 1800,
  );

  Future<(MemoryHydrionStore, _ControlledSecureStore, BodyMetricsRepository)>
      fixture() async {
    final local = MemoryHydrionStore();
    final secure = _ControlledSecureStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(initial, femaleProfile: false, now: now);
    return (local, secure, repo);
  }

  test('pending revision survives repeated restarts then converges securely',
      () async {
    final (local, secure, repo) = await fixture();
    secure.failWrites = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false, now: now),
        isTrue);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.writeFailed);
    expect(repo.state.revision, 2);
    for (var i = 0; i < 3; i++) {
      final loaded =
          await BodyMetricsRepository.load(local, secureStore: secure);
      expect(loaded.metrics.weightKg, 71);
      expect(loaded.state.status, BodyMetricsStatus.pendingSecure);
      expect((await secure.read())!['weightKg'], 70);
      expect(
          (jsonDecode(local.snapshot[BodyMetricsRepository.storageKey]!)
              as Map)['weightKg'],
          71);
    }
    secure.failWrites = false;
    final recovered =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(recovered.state.status, BodyMetricsStatus.available);
    expect(recovered.state.revision, 2);
    expect((await secure.read())!['weightKg'], 71);
    expect(
        (jsonDecode(local.snapshot[BodyMetricsRepository.storageKey]!)
            as Map)['weightKg'],
        isNull);
    final snapshot = local.snapshot;
    await recovered.reload();
    expect(recovered.metrics.weightKg, 71);
    expect(local.snapshot, snapshot);
  });

  test(
      'calculation rechecks availability after paused recommendation persistence',
      () async {
    final (_, secure, repo) = await fixture();
    await repo.update(
        fluidSafetyMode: HydrionFluidSafetyMode.none,
        clearClinicianTarget: true,
        femaleProfile: false);
    final settings = UserSettingsRepository.memory(const Locale('en'));
    final local = _PausedRecommendationStore();
    final state = await PersonalizationStateRepository.load(local);
    final coordinator = DailyHydrationRecommendationCoordinator(
      settingsRepository: settings,
      bodyMetricsRepository: repo,
      dailyContextRepository: DailyHydrationContextRepository.memory(),
      stateRepository: state,
    );
    final goal = settings.settings.dailyGoalMl;
    final calculation = coordinator.calculateResult(now: now);
    await local.entered.future;
    expect(state.latestRecommendation!.mayAutoApply, isTrue);
    secure.readUnavailable = true;
    await repo.reload();
    local.resume.complete();
    final result = await calculation;
    expect(result.bodyStatus, BodyMetricsStatus.unavailable);
    expect(result.recommendation, isNull);
    expect(result.mayAutoApply, isFalse);
    expect(settings.settings.dailyGoalMl, goal);
  });

  for (final field in [
    'fluidSafetyMode',
    'allowAdjustmentsAboveClinicianTarget'
  ]) {
    test('invalid pending $field never becomes a trusted default', () async {
      final (local, secure, repo) = await fixture();
      secure.failWrites = true;
      await repo.update(weightKg: 71, femaleProfile: false);
      final record =
          jsonDecode(local.snapshot[BodyMetricsRepository.storageKey]!) as Map;
      record[field] = null;
      await local.writeString(
          BodyMetricsRepository.storageKey, jsonEncode(record));
      final before = Map.of(local.snapshot);
      final loaded =
          await BodyMetricsRepository.load(local, secureStore: secure);
      expect(loaded.state.status, BodyMetricsStatus.corrupt);
      expect(loaded.state.value, isNull);
      expect(
          await loaded.update(
              preferredWeightUnit: HydrionWeightUnit.pounds,
              femaleProfile: false),
          isFalse);
      expect(local.snapshot, before);
      expect((await secure.read())!['weightKg'], 70);
    });
  }

  test(
      'unknown state blocks old recommendation application and fingerprint writes',
      () async {
    final (_, secure, repo) = await fixture();
    final settings = UserSettingsRepository.memory(const Locale('en'));
    final state = PersonalizationStateRepository.memory();
    final coordinator = DailyHydrationRecommendationCoordinator(
      settingsRepository: settings,
      bodyMetricsRepository: repo,
      dailyContextRepository: DailyHydrationContextRepository.memory(),
      stateRepository: state,
    );
    final old = await coordinator.calculate(now: now);
    final fingerprint = state.lastInputFingerprint;
    final goal = settings.settings.dailyGoalMl;
    final source = settings.settings.baselineSource;
    secure.readUnavailable = true;
    await repo.reload();
    expect(
        (await coordinator.calculateResult(
                now: now.add(const Duration(days: 1))))
            .recommendation,
        isNull);
    expect(await coordinator.apply(old, now: now), isFalse);
    expect(await coordinator.applyPersonalizedBaseline(old, now: now), isFalse);
    expect(settings.settings.dailyGoalMl, goal);
    expect(settings.settings.baselineSource, source);
    expect(state.lastInputFingerprint, fingerprint);
  });

  test(
      'secure commit with failed local publication is reconciled without stale rollback',
      () async {
    final local = _FailingLocalStore();
    final secure = _ControlledSecureStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(initial, femaleProfile: false);
    local.failWrites = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false), isFalse);
    expect(repo.state.value, isNull);
    local.failWrites = false;
    await repo.reload();
    expect(repo.metrics.weightKg, 71);
    expect(repo.state.revision, 2);
  });

  test('secure-only unavailable state exposes no metrics and retry restores it',
      () async {
    final (local, secure, _) = await fixture();
    final before = local.snapshot;
    secure.readUnavailable = true;
    for (var i = 0; i < 3; i++) {
      final loaded =
          await BodyMetricsRepository.load(local, secureStore: secure);
      expect(loaded.state.status, BodyMetricsStatus.unavailable);
      expect(loaded.state.value, isNull);
      expect(() => loaded.metrics, throwsA(isA<BodyMetricsUnavailable>()));
      expect(await loaded.update(wakeMinuteOfDay: 450, femaleProfile: false),
          isFalse);
      expect(local.snapshot, before);
    }
    secure.readUnavailable = false;
    final loaded = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(loaded.metrics.clinicianTargetMl, 1800);
  });

  test('secure absence and unavailable infrastructure have different outcomes',
      () async {
    final secure = _ControlledSecureStore();
    final local = MemoryHydrionStore();
    final absent = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(absent.state.status, BodyMetricsStatus.absent);
    expect(absent.state.isKnown, isTrue);
    secure.readUnavailable = true;
    final unavailable =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(unavailable.state.status, BodyMetricsStatus.unavailable);
    expect(unavailable.state.isKnown, isFalse);
    expect(local.snapshot, isEmpty);
  });

  test(
      'invalid secure fields are corrupt and cannot be overwritten as defaults',
      () async {
    final (local, secure, _) = await fixture();
    final fields = (await secure.read())!;
    fields['weightKg'] = 'synthetic invalid';
    await secure.write(fields);
    final before = local.snapshot;
    final loaded = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(loaded.state.status, BodyMetricsStatus.corrupt);
    expect(loaded.state.value, isNull);
    expect(await loaded.save(initial, femaleProfile: false), isFalse);
    expect(await secure.read(), fields);
    expect(local.snapshot, before);
  });

  test('corrupt secure copy cannot erase a known newer pending fallback',
      () async {
    final (local, secure, repo) = await fixture();
    secure.failWrites = true;
    await repo.update(weightKg: 71, femaleProfile: false);
    secure.failWrites = false;
    await secure.write({'invalid': true});
    final before = local.snapshot;
    final loaded = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(loaded.metrics.weightKg, 71);
    expect(loaded.state.status, BodyMetricsStatus.pendingSecure);
    expect(local.snapshot, before);
  });

  test('valid unversioned secure-only installation remains readable', () async {
    final (_, secure, _) = await fixture();
    final legacy = (await secure.read())!..remove('_bodyRevision');
    await secure.write(legacy);
    final loaded = await BodyMetricsRepository.load(MemoryHydrionStore(),
        secureStore: secure);
    expect(loaded.metrics.weightKg, 70);
    expect(loaded.metrics.clinicianTargetMl, 1800);
    expect(loaded.state.revision, 0);
  });

  test('unequal unversioned copies remain ambiguous and preserve both records',
      () async {
    final (_, secure, _) = await fixture();
    final legacy = (await secure.read())!..remove('_bodyRevision');
    await secure.write(legacy);
    final local = MemoryHydrionStore({
      BodyMetricsRepository.storageKey:
          jsonEncode(initial.copyWith(weightKg: 71).toJson())
    });
    final before = local.snapshot;
    for (var i = 0; i < 3; i++) {
      final loaded =
          await BodyMetricsRepository.load(local, secureStore: secure);
      expect(loaded.state.status, BodyMetricsStatus.ambiguous);
      expect(loaded.state.value, isNull);
      expect(await loaded.update(weightKg: 72, femaleProfile: false), isFalse);
      expect(local.snapshot, before);
      expect(await secure.read(), legacy);
    }
  });

  test('legacy sentinel defaults cannot prove a clear rather than an old strip',
      () async {
    final (_, secure, _) = await fixture();
    final legacy = (await secure.read())!..remove('_bodyRevision');
    await secure.write(legacy);
    final local = MemoryHydrionStore({
      BodyMetricsRepository.storageKey:
          jsonEncode(const HydrionBodyMetrics().toJson()),
      'hydrion.body_metrics.secure_migration.v1': 'completed',
    });
    final before = local.snapshot;
    final loaded = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(loaded.state.status, BodyMetricsStatus.ambiguous);
    expect(local.snapshot, before);
  });

  test('verification failure retains pending revision even if write succeeded',
      () async {
    final (local, secure, repo) = await fixture();
    secure.readUnavailable = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false), isTrue);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.verificationFailed);
    final pending =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(pending.state.status, BodyMetricsStatus.pendingSecure);
    expect(pending.metrics.weightKg, 71);
    secure.readUnavailable = false;
    await pending.reload();
    expect(pending.metrics.weightKg, 71);
    expect(pending.state.status, BodyMetricsStatus.available);
  });

  test('serialized preference edits preserve sensitive values and each other',
      () async {
    final (local, secure, repo) = await fixture();
    final results = await Future.wait([
      repo.update(wakeMinuteOfDay: 420, femaleProfile: false),
      repo.update(
          preferredWeightUnit: HydrionWeightUnit.pounds, femaleProfile: false),
    ]);
    expect(results, [true, true]);
    final loaded = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(loaded.state.revision, 3);
    expect(loaded.metrics.weightKg, 70);
    expect(loaded.metrics.clinicianTargetMl, 1800);
    expect(loaded.metrics.wakeMinuteOfDay, 420);
    expect(loaded.metrics.preferredWeightUnit, HydrionWeightUnit.pounds);
  });

  test(
      'failed local publication requires reload without replacing prior record',
      () async {
    final local = _FailingLocalStore();
    final secure = _ControlledSecureStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(initial, femaleProfile: false);
    final before = local.snapshot;
    local.failWrites = true;
    secure.failWrites = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false), isFalse);
    expect(repo.state.isKnown, isFalse);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.localWriteFailed);
    expect(local.snapshot, before);
    local.failWrites = false;
    secure.failWrites = false;
    await repo.reload();
    expect(repo.metrics.weightKg, 70);
  });

  test('result and failure descriptions contain no body or clinical payload',
      () async {
    final (_, _, repo) = await fixture();
    expect(repo.state.toString(), 'BodyMetricsState(available)');
    expect(
        SensitiveBodyRead.found({'secret': 'synthetic private data'})
            .toString(),
        'SensitiveBodyRead(found)');
    expect(const BodyMetricsUnavailable(BodyMetricsStatus.corrupt).toString(),
        'BodyMetricsUnavailable(corrupt)');
  });

  testWidgets(
      'unavailable editor blocks edits and retry restores actual saved metrics',
      (tester) async {
    final (local, secure, _) = await fixture();
    secure.readUnavailable = true;
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider.value(
              value: UserSettingsRepository.memory(const Locale('en'))),
          ChangeNotifierProvider.value(
              value: DailyHydrationContextRepository.memory()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BodyMetricsScreen(),
        )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-metrics-unavailable')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    secure.readUnavailable = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-metrics-unavailable')), findsNothing);
    expect(repo.metrics.weightKg, 70);
    expect(repo.metrics.clinicianTargetMl, 1800);
    expect(tester.takeException(), isNull);
  });

  test('DATA-007 accepted B survives failed secure write and restart',
      () async {
    final store = MemoryHydrionStore();
    final secure = _ControlledSecureStore();
    final repository =
        await BodyMetricsRepository.load(store, secureStore: secure);
    expect(
        await repository.save(initial, femaleProfile: false, now: now), isTrue);
    secure.failWrites = true;
    expect(
        await repository.update(weightKg: 71, femaleProfile: false, now: now),
        isTrue);
    final restarted =
        await BodyMetricsRepository.load(store, secureStore: secure);
    expect(restarted.metrics.weightKg, 71,
        reason: 'An accepted newer save must not revert to secure A');
  });

  test('DATA-007 unavailable secure state cannot be saved as defaults',
      () async {
    final store = MemoryHydrionStore();
    final secure = _ControlledSecureStore();
    final repository =
        await BodyMetricsRepository.load(store, secureStore: secure);
    await repository.save(initial, femaleProfile: false, now: now);
    final originalSecure = await secure.read();
    secure.readUnavailable = true;
    final restarted =
        await BodyMetricsRepository.load(store, secureStore: secure);
    // A harmless preference edit must not replace unknown clinical fields.
    expect(
        await restarted.update(
            preferredWeightUnit: HydrionWeightUnit.pounds,
            femaleProfile: false,
            now: now),
        isFalse);
    secure.readUnavailable = false;
    expect(await secure.read(), originalSecure,
        reason: 'Unavailable is not absent and must not authorize overwrite');
  });

  test('DATA-007 unavailable clinical state cannot enable automatic targets',
      () async {
    final store = MemoryHydrionStore();
    final secure = _ControlledSecureStore();
    final repository =
        await BodyMetricsRepository.load(store, secureStore: secure);
    await repository.save(initial, femaleProfile: false, now: now);
    DailyHydrationRecommendationCoordinator coordinator(
            BodyMetricsRepository body) =>
        DailyHydrationRecommendationCoordinator(
          settingsRepository: UserSettingsRepository.memory(const Locale('en')),
          bodyMetricsRepository: body,
          dailyContextRepository: DailyHydrationContextRepository.memory(),
          stateRepository: PersonalizationStateRepository.memory(),
        );
    expect((await coordinator(repository).calculate(now: now)).mayAutoApply,
        isFalse);
    secure.readUnavailable = true;
    final restarted =
        await BodyMetricsRepository.load(store, secureStore: secure);
    final result = await coordinator(restarted).calculateResult(now: now);
    expect(result.recommendation, isNull);
    expect(result.bodyStatus, BodyMetricsStatus.unavailable);
    expect(result.mayAutoApply, isFalse,
        reason: 'Unknown clinical state must not become an unrestricted input');
  });
}

class _FailingLocalStore extends MemoryHydrionStore {
  bool failWrites = false;
  @override
  Future<void> writeString(String key, String value) async {
    if (failWrites) throw StateError('synthetic local write failure');
    await super.writeString(key, value);
  }
}

class _PausedRecommendationStore extends MemoryHydrionStore {
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<void> writeString(String key, String value) async {
    entered.complete();
    await resume.future;
    await super.writeString(key, value);
  }
}

class _ControlledSecureStore extends MemorySensitiveBodyMetricsStore {
  bool failWrites = false;
  bool readUnavailable = false;

  @override
  Future<SensitiveBodyRead> readResult() async {
    if (readUnavailable) return const SensitiveBodyRead.unavailable();
    return super.readResult();
  }

  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (failWrites) throw StateError('synthetic write failure');
    await super.write(fields);
  }
}
