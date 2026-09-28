import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/domain/hydration_recommendation.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/personalized_hydration_engine.dart';
import 'package:hydrion/services/recommendation_input_token.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

const _date = '2026-09-28';
const _sensitiveBody = HydrionBodyMetrics(
  personalizationEnabled: true,
  weightKg: 73.25,
  heightCm: 171.5,
  reproductiveState: HydrionReproductiveHydrationState.pregnant,
  pregnancyGestationalDays: 168,
  fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
  clinicianTargetMl: 1850,
);

PersonalizedHydrationInputs _input({
  HydrionBodyMetrics body = _sensitiveBody,
  DailyHydrationContext? context,
  DateTime? at,
  String date = _date,
  int baseline = 2200,
  int age = 30,
  WeatherSnapshot? weather,
}) =>
    PersonalizedHydrationInputs(
      existingBaselineGoalMl: baseline,
      requestedBaselineSource: HydrationBaselineSource.personalized,
      age: age,
      sex: HydrionSex.female,
      bodyMetrics: body,
      dailyContext: context,
      weather: weather,
      weatherEnabled: true,
      locationPermissionGranted: true,
      cachedWeatherUsed: false,
      localDateKey: date,
      calculatedAt: at ?? DateTime(2026, 9, 28, 12),
    );

Future<void> _record(PersonalizationStateRepository repository,
    [PersonalizedHydrationInputs? input]) {
  final source = input ?? _input();
  return repository.recordRecommendation(
    canonicalInput: canonicalRecommendationInput(source),
    recommendation: const PersonalizedHydrationEngine().calculate(source),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('SEC-003 HMAC binds the versioned domain with a dedicated 256-bit key',
      () async {
    final secure = _SecureStore();
    final tokens = RecommendationInputTokens(storage: secure);
    final canonical = canonicalRecommendationInput(_input());
    final token = await tokens.create(canonical);
    final key =
        base64Url.decode(secure.values[RecommendationInputTokens.storageKey]!);
    expect(key, hasLength(32));
    expect(secure.values.keys, [RecommendationInputTokens.storageKey]);
    expect(token,
        'recommendation-input-token-v1:${Hmac(sha256, key).convert(utf8.encode('hydrion/recommendation-input-token/v1\u0000$canonical'))}');
    expect(token,
        isNot(contains(sha256.convert(utf8.encode(canonical)).toString())));
    expect(await tokens.create(canonical), token);
    expect(await RecommendationInputTokens(storage: secure).create(canonical),
        token);
    expect(
        await RecommendationInputTokens(storage: _SecureStore())
            .create(canonical),
        isNot(token));
    expect(secure.android?.toMap()['storageNamespace'],
        'hydrion_recommendation_equality');
  });

  test('SEC-003 iOS uses a non-synchronizing device-local keychain namespace',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final secure = _SecureStore();
    expect(
        await RecommendationInputTokens(storage: secure).canPersist(), isTrue);
    expect(secure.ios?.toMap()['accountName'],
        'com.the1807.hydrion.recommendation-equality');
    expect(secure.ios?.toMap()['synchronizable'], 'false');
    expect(secure.ios?.toMap()['accessibility'], 'first_unlock_this_device');
  });

  test(
      'SEC-003 construction order and presentation/timestamp fields are irrelevant',
      () {
    final map = _sensitiveBody.toJson();
    final reversed = {
      for (final key in map.keys.toList().reversed) key: map[key]
    };
    final equivalent = HydrionBodyMetrics.fromJson(reversed).copyWith(
      preferredWeightUnit: HydrionWeightUnit.pounds,
      preferredHeightUnit: HydrionHeightUnit.feetAndInches,
      pregnancyGestationalDays: 169,
      updatedAt: DateTime(2030),
    );
    expect(
        canonicalRecommendationInput(
            _input(body: equivalent, age: 40, at: DateTime(2030))),
        canonicalRecommendationInput(_input()));
    final canonical = canonicalRecommendationInput(_input());
    for (final omitted in [
      'weightKg',
      'pregnancyGestationalDays',
      'updatedAt',
      'kilograms',
      'weeks'
    ]) {
      expect(canonical, isNot(contains(omitted)));
    }
  });

  test(
      'SEC-003 material body, safety, baseline and review-date changes bind tokens',
      () async {
    final tokens = RecommendationInputTokens(storage: _SecureStore());
    final original =
        await tokens.create(canonicalRecommendationInput(_input()));
    final inputs = [
      _input(body: _sensitiveBody.copyWith(weightKg: 75)),
      _input(body: _sensitiveBody.copyWith(heightCm: 173)),
      _input(
          body: _sensitiveBody.copyWith(
              reproductiveState: HydrionReproductiveHydrationState.lactating)),
      _input(body: _sensitiveBody.copyWith(clinicianTargetMl: 1950)),
      _input(
          body: _sensitiveBody.copyWith(
              fluidSafetyMode: HydrionFluidSafetyMode.unsure)),
      _input(
          body: _sensitiveBody.copyWith(
              allowAdjustmentsAboveClinicianTarget: true)),
      _input(body: _sensitiveBody.copyWith(personalizationEnabled: false)),
      _input(age: 19),
      _input(baseline: 2300),
      _input(date: '2026-09-29'),
    ];
    for (final input in inputs) {
      expect(await tokens.create(canonicalRecommendationInput(input)),
          isNot(original));
    }
  });

  test(
      'SEC-003 activity, safety and weather values bind; their timestamps do not',
      () async {
    final tokens = RecommendationInputTokens(storage: _SecureStore());
    DailyHydrationContext context(
            {int minutes = 60,
            DateTime? at,
            HydrionTemporaryCondition condition =
                HydrionTemporaryCondition.none}) =>
        DailyHydrationContext(
            localDateKey: _date,
            activityIntensity: HydrionActivityIntensity.moderate,
            activityMinutes: minutes,
            environment: HydrionEnvironmentExposure.mostlyOutdoors,
            temporaryCondition: condition,
            updatedAt: at ?? DateTime(2026));
    WeatherSnapshot weather(double temperature, DateTime at) =>
        WeatherSnapshot(temperatureC: temperature, uvIndex: 8, observedAt: at);
    Future<String> token(DailyHydrationContext c, WeatherSnapshot w) => tokens
        .create(canonicalRecommendationInput(_input(context: c, weather: w)));
    final first = await token(context(), weather(30, DateTime(2026)));
    expect(
        await token(context(at: DateTime(2030)), weather(30, DateTime(2030))),
        first);
    expect(await token(context(minutes: 30), weather(30, DateTime(2026))),
        isNot(first));
    expect(
        await token(context(condition: HydrionTemporaryCondition.fever),
            weather(30, DateTime(2026))),
        isNot(first));
    expect(await token(context(), weather(35, DateTime(2026))), isNot(first));
  });

  test(
      'SEC-003 persistent state contains only opaque tokens; review survives restart',
      () async {
    final store = _Store();
    final secure = _SecureStore();
    Future<PersonalizationStateRepository> load() =>
        PersonalizationStateRepository.load(store,
            tokens: RecommendationInputTokens(storage: secure));
    var repository = await load();
    await _record(repository);
    final first = repository.lastInputFingerprint!;
    await repository.markRecommendationReviewed(localDateKey: _date);
    final raw = store.snapshot[PersonalizationStateRepository.storageKey]!;
    final decoded = jsonDecode(raw) as Map;
    expect(
        RecommendationInputTokens.isPersistable(
            decoded['lastInputFingerprint']),
        isTrue);
    expect(decoded['reviewedRecommendationsByDate'], {_date: first});
    for (final sensitive in [
      'pregnant',
      'clinicianTarget',
      '73.25',
      '171.5',
      'weightKg',
      'heightCm',
      canonicalRecommendationInput(_input()),
      secure.values[RecommendationInputTokens.storageKey]!
    ]) {
      expect(raw, isNot(contains(sensitive)));
    }
    repository = await load();
    await _record(repository);
    expect(repository.lastInputFingerprint, first);
    expect(
        repository.isRecommendationReviewed(
            localDateKey: _date, inputFingerprint: first),
        isTrue);
    final count = store.writes;
    await _record(repository);
    expect(store.writes, count);
    await _record(repository, _input(date: '2026-09-29'));
    expect(
        repository.isRecommendationReviewed(
            localDateKey: '2026-09-29',
            inputFingerprint: repository.lastInputFingerprint!),
        isFalse);
  });

  for (final failure in [
    'read',
    'write',
    'mismatch',
    'malformed',
    'unsupported'
  ]) {
    test(
        'SEC-003 $failure key means memory-only matching, never persisted source/digest',
        () async {
      final secure = _SecureStore()..failure = failure;
      if (failure == 'malformed') {
        secure.values[RecommendationInputTokens.storageKey] = 'bad-key';
      }
      if (failure == 'unsupported') {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      }
      final store = _Store();
      final repository = await PersonalizationStateRepository.load(store,
          tokens: RecommendationInputTokens(storage: secure));
      await _record(repository);
      final token = repository.lastInputFingerprint!;
      await repository.markRecommendationReviewed(localDateKey: _date);
      expect(repository.tokenStatus, RecommendationTokenStatus.memoryOnly);
      expect(
          repository.isRecommendationReviewed(
              localDateKey: _date, inputFingerprint: token),
          isTrue);
      await _record(repository);
      expect(repository.lastInputFingerprint, token);
      final raw = store.snapshot[PersonalizationStateRepository.storageKey]!;
      final decoded = jsonDecode(raw) as Map;
      expect(decoded['lastInputFingerprint'], isNull);
      expect(decoded['reviewedRecommendationsByDate'], isEmpty);
      expect(raw, isNot(contains('pregnant')));
      expect(raw, isNot(contains(token)));
      final restarted = await PersonalizationStateRepository.load(store,
          tokens: RecommendationInputTokens(storage: secure));
      expect(restarted.lastInputFingerprint, isNull);
      if (failure == 'unsupported') expect(secure.calls, 0);
    });
  }

  test(
      'SEC-003 temporary key loss drops persisted review lineage then can recover',
      () async {
    final secure = _SecureStore();
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: secure));
    await _record(repository);
    final original = repository.lastInputFingerprint!;
    await repository.markRecommendationReviewed(localDateKey: _date);
    secure.failure = 'read';
    await _record(repository);
    expect(
        (jsonDecode(store.snapshot[PersonalizationStateRepository.storageKey]!)
            as Map)['reviewedRecommendationsByDate'],
        isEmpty);
    secure.failure = null;
    await _record(repository);
    expect(repository.lastInputFingerprint, original);
    expect(
        repository.isRecommendationReviewed(
            localDateKey: _date, inputFingerprint: original),
        isFalse);
  });

  for (final version in [1, 2, 3]) {
    test(
        'SEC-003 removes legacy/invalid token copies in schema $version idempotently',
        () async {
      final store = _Store({
        PersonalizationStateRepository.storageKey: jsonEncode({
          'schemaVersion': version,
          'lastInputFingerprint':
              'weightKg: 73.25|pregnant|clinicianTargetMl: 1850',
          'reviewedRecommendationsByDate': {_date: 'pregnant|1850'},
          'latestRecommendation': {'clinicianTargetMl': 1850},
          'dismissedChallengesByDate': {
            _date: ['bottle-bingo']
          },
          'challengePreferences': {'prefersTimedRoutines': true},
        })
      });
      final secure = _SecureStore();
      Future<PersonalizationStateRepository> load() =>
          PersonalizationStateRepository.load(store,
              tokens: RecommendationInputTokens(storage: secure));
      final repository = await load();
      expect(repository.lastInputFingerprint, isNull);
      expect(repository.challengePreferences.prefersTimedRoutines, isTrue);
      expect(repository.dismissedForDate(_date), {'bottle-bingo'});
      final raw = store.snapshot[PersonalizationStateRepository.storageKey]!;
      expect(raw, isNot(contains('pregnant')));
      expect(raw, isNot(contains('1850')));
      expect(raw, isNot(contains('latestRecommendation')));
      final count = store.writes;
      await load();
      expect(store.writes, count);
      expect(store.snapshot[PersonalizationStateRepository.storageKey], raw);
    });
  }

  for (final failure in ['false', 'mismatch', 'throw']) {
    test(
        'SEC-003 $failure migration fails truthfully without payload in exception',
        () async {
      final store = _Store({
        PersonalizationStateRepository.storageKey:
            '{"lastInputFingerprint":"pregnant|1850"}'
      })
        ..failure = failure;
      await expectLater(
          PersonalizationStateRepository.load(store),
          throwsA(isA<PersonalizationPersistenceIncomplete>().having(
              (e) => e.toString(),
              'payload-free message',
              'PersonalizationPersistenceIncomplete')));
      store.failure = null;
      final repository = await PersonalizationStateRepository.load(store);
      expect(repository.lastInputFingerprint, isNull);
      expect(store.snapshot[PersonalizationStateRepository.storageKey],
          isNot(contains('pregnant')));
    });
  }

  test('SEC-003 rejected token/review writes do not claim successful dedup',
      () async {
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: _SecureStore()));
    store.failure = 'false';
    await expectLater(_record(repository),
        throwsA(isA<PersonalizationPersistenceIncomplete>()));
    expect(repository.lastInputFingerprint, isNull);
    store.failure = null;
    await _record(repository);
    final token = repository.lastInputFingerprint!;
    store.failure = 'throw';
    await expectLater(
        repository.markRecommendationReviewed(localDateKey: _date),
        throwsA(isA<PersonalizationPersistenceIncomplete>()));
    expect(
        repository.isRecommendationReviewed(
            localDateKey: _date, inputFingerprint: token),
        isFalse);
  });

  test(
      'SEC-003 clear removes tokens, review history and dedicated key; new key breaks lineage',
      () async {
    final secure = _SecureStore();
    secure.values['unrelated-key'] = 'preserve';
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: secure));
    await _record(repository);
    final first = repository.lastInputFingerprint;
    await repository.markRecommendationReviewed(localDateKey: _date);
    await repository.clear();
    expect(repository.lastInputFingerprint, isNull);
    expect(
        store.snapshot.containsKey(PersonalizationStateRepository.storageKey),
        isFalse);
    expect(secure.values, {'unrelated-key': 'preserve'});
    await _record(repository);
    expect(repository.lastInputFingerprint, isNot(first));
  });

  test('SEC-003 secure delete failure is retryable and blocks token recreation',
      () async {
    final secure = _SecureStore();
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: secure));
    await _record(repository);
    secure.failure = 'delete';
    await expectLater(repository.clear(),
        throwsA(isA<PersonalizationPersistenceIncomplete>()));
    expect(repository.lastInputFingerprint, isNull);
    expect(
        (jsonDecode(store.snapshot[PersonalizationStateRepository.storageKey]!)
            as Map)['lastInputFingerprint'],
        isNull);
    await expectLater(_record(repository),
        throwsA(isA<PersonalizationPersistenceIncomplete>()));
    secure.failure = null;
    await repository.clear();
    expect(secure.values, isEmpty);
  });

  test('SEC-003 rejected clear overwrite cannot report deletion or delete key',
      () async {
    final secure = _SecureStore();
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: secure));
    await _record(repository);
    store.failure = 'false';
    await expectLater(repository.clear(),
        throwsA(isA<PersonalizationPersistenceIncomplete>()));
    expect(secure.values, isNotEmpty);
    expect(repository.lastInputFingerprint, isNull);
    store.failure = null;
    await repository.clear();
    expect(secure.values, isEmpty);
  });

  test(
      'SEC-003 clear invalidates an in-flight key read without republishing state',
      () async {
    final secure = _SecureStore();
    final store = _Store();
    final repository = await PersonalizationStateRepository.load(store,
        tokens: RecommendationInputTokens(storage: secure));
    secure.readStarted = Completer<void>();
    secure.releaseRead = Completer<void>();
    final recording = _record(repository);
    final rejected = expectLater(
        recording, throwsA(isA<PersonalizationPersistenceIncomplete>()));
    await secure.readStarted!.future;
    final clear = repository.clear();
    secure.releaseRead!.complete();
    await rejected;
    await clear;
    expect(repository.lastInputFingerprint, isNull);
    expect(repository.latestRecommendation, isNull);
    expect(
        store.snapshot.containsKey(PersonalizationStateRepository.storageKey),
        isFalse);
    expect(secure.values, isEmpty);
  });

  test('SEC-003 concurrent secure creation uses one key across token services',
      () async {
    final secure = _SecureStore();
    final values = await Future.wait(List.generate(5,
        (_) => RecommendationInputTokens(storage: secure).create('synthetic')));
    expect(values.toSet(), hasLength(1));
    expect(secure.writes, 1);
  });
}

class _Store extends MemoryHydrionStore {
  _Store([super.initialValues]);
  String? failure;
  int writes = 0;
  @override
  Future<bool> writeString(String key, String value) async {
    writes++;
    if (failure == 'false') return false;
    if (failure == 'mismatch') return true;
    if (failure == 'throw') {
      throw StateError('synthetic source must not escape');
    }
    return super.writeString(key, value);
  }
}

class _SecureStore extends FlutterSecureStorage {
  final values = <String, String>{};
  String? failure;
  int calls = 0;
  int writes = 0;
  AndroidOptions? android;
  AppleOptions? ios;
  Completer<void>? readStarted;
  Completer<void>? releaseRead;

  @override
  Future<String?> read(
      {required String key,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    calls++;
    android = aOptions;
    ios = iOptions;
    if (readStarted != null && !readStarted!.isCompleted) {
      readStarted!.complete();
      await releaseRead!.future;
    }
    if (failure == 'read') throw StateError('synthetic secret must not escape');
    return values[key];
  }

  @override
  Future<void> write(
      {required String key,
      required String? value,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    calls++;
    writes++;
    if (failure == 'write') {
      throw StateError('synthetic secret must not escape');
    }
    if (failure != 'mismatch' && value != null) values[key] = value;
  }

  @override
  Future<void> delete(
      {required String key,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    calls++;
    if (failure != 'delete') values.remove(key);
  }
}
