import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/services/local_profile_reset_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryHydrionStore local;
  late _NativeStorage native;
  late PlatformSensitiveBodyMetricsStore secure;
  late BodyMetricsRepository body;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
    local = MemoryHydrionStore();
    native = _NativeStorage();
    secure = PlatformSensitiveBodyMetricsStore(storage: native);
    body = await BodyMetricsRepository.load(local, secureStore: secure);
    await body.save(const HydrionBodyMetrics(weightKg: 70),
        femaleProfile: false);
    native.rejectDelete = true;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('failed native deletion cannot report repository clear complete',
      () async {
    await expectLater(body.clear(), throwsA(isA<Exception>()));
  });

  test('failed native deletion cannot resurrect active metrics after restart',
      () async {
    try {
      await body.clear();
    } catch (_) {}
    final restarted =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(restarted.state.value, isNull);
    expect((await secure.readResult()).status, SensitiveBodyReadStatus.found);
  });

  test('profile reset reports body failure and success after retry', () async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore(),
        notificationAdapter: FakeHydrionNotificationAdapter());
    final reset = LocalProfileResetService(
      settingsRepository: services.settingsRepository,
      hydrationRepository: services.hydrationRepository,
      challengeRepository: services.challengeRepository,
      reminderRepository: services.reminderRepository,
      notificationService: services.notificationService,
      weatherForecastService: services.weatherForecastService,
      bodyMetricsRepository: body,
    );
    final failed = await reset.resetLocalProfile();
    expect(failed.bodyMetricsDeletion, LocalProfileSubsystemStatus.failed);
    expect(failed.isCompleted, isFalse);
    native.rejectDelete = false;
    final retried = await reset.resetLocalProfile();
    expect(retried.bodyMetricsDeletion, LocalProfileSubsystemStatus.completed);
    expect(retried.isCompleted, isTrue);
  });

  test('pending intent strips payload, survives restart, retries idempotently',
      () async {
    await expectLater(
        body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    final raw = local.snapshot[BodyMetricsRepository.storageKey]!;
    expect(jsonDecode(raw), {
      '_bodyDeletion': {'version': 1, 'pending': true}
    });
    final restarted =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(restarted.state.status, BodyMetricsStatus.deletionPending);
    expect(await restarted.update(weightKg: 80, femaleProfile: false), isFalse);
    await expectLater(
        restarted.reload(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expect(local.snapshot[BodyMetricsRepository.storageKey], raw);
    native.rejectDelete = false;
    await restarted.reload();
    expect(restarted.state.status, BodyMetricsStatus.absent);
    expect((await secure.readResult()).status, SensitiveBodyReadStatus.absent);
    expect(local.snapshot[BodyMetricsRepository.storageKey], '{}');
    await restarted.clear();
    final empty = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(empty.metrics.weightKg, isNull);
    expect(empty.state.revision, 0);
    expect(await empty.update(weightKg: 75, femaleProfile: false), isTrue);
    expect(
        (await BodyMetricsRepository.load(local, secureStore: secure))
            .metrics
            .weightKg,
        75);
  });

  test('silent native no-op is verificationFailed and remains quarantined',
      () async {
    native.rejectDelete = false;
    native.ignoreDelete = true;
    await expectLater(
        body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.verificationFailed);
    expect(
        (await BodyMetricsRepository.load(local, secureStore: secure))
            .state
            .value,
        isNull);
  });

  test('unavailable verification never certifies deletion', () async {
    native.rejectDelete = false;
    native.failRead = true;
    await expectLater(
        body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.unavailable);
    expect(local.snapshot[BodyMetricsRepository.storageKey],
        contains('_bodyDeletion'));
    native.failRead = false;
    await body.clear();
    expect(body.state.status, BodyMetricsStatus.absent);
  });

  test('unsupported platform is not deletion success', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await expectLater(
        body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.unsupported);
    expect(
        (await BodyMetricsRepository.load(local, secureStore: secure))
            .state
            .value,
        isNull);
  });

  for (final ignore in [true, false]) {
    test('corrupt payload requires verified deletion: ignore=$ignore',
        () async {
      FlutterSecureStorage.setMockInitialValues(
          {'hydrion.body_metrics.sensitive.v1': '{bad'});
      native.rejectDelete = false;
      native.ignoreDelete = ignore;
      if (ignore) {
        await expectLater(
            body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
        expect(body.lastDeleteStatus,
            SensitiveBodyDeleteStatus.verificationFailed);
      } else {
        await body.clear();
        expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.verifiedAbsent);
      }
    });
  }

  test('already absent secure payload is verified and safe', () async {
    FlutterSecureStorage.setMockInitialValues({});
    native.rejectDelete = false;
    await body.clear();
    expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.verifiedAbsent);
    expect(body.metrics.weightKg, isNull);
  });

  test('diagnostics expose status only, not native payload or metrics',
      () async {
    Object? failure;
    try {
      await body.clear();
    } catch (e) {
      failure = e;
    }
    expect(failure.toString(), 'BodyMetricsDeletionIncomplete');
    expect(body.state.toString(), 'BodyMetricsState(deletionPending)');
    expect(body.lastDeleteStatus, SensitiveBodyDeleteStatus.failed);
    expect(local.snapshot[BodyMetricsRepository.storageKey],
        isNot(contains('weightKg')));
  });

  test('pending newer plaintext write is removed before failed secure delete',
      () async {
    native.failWrite = true;
    expect(await body.update(weightKg: 71, femaleProfile: false), isTrue);
    expect(body.state.status, BodyMetricsStatus.pendingSecure);
    await expectLater(
        body.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expect(local.snapshot[BodyMetricsRepository.storageKey],
        isNot(contains('71')));
    expect(
        (await BodyMetricsRepository.load(local, secureStore: secure))
            .state
            .value,
        isNull);
  });

  for (final blockedWrite in [1, 2, 3]) {
    test(
        'local write rejection at deletion phase $blockedWrite stays incomplete',
        () async {
      final failing = _RejectingLocal(local.snapshot, blockedWrite);
      // Load before enabling faults: existing authority reconciliation writes.
      final repo =
          await BodyMetricsRepository.load(failing, secureStore: secure);
      failing.armed = true;
      native.rejectDelete = false;
      await expectLater(
          repo.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
      expect(repo.state.value, isNull);
      if (blockedWrite == 1) {
        // No acknowledged intent: cannot claim restart protection or touch secure data.
        expect(
            (await secure.readResult()).status, SensitiveBodyReadStatus.found);
        expect(native.deleteCalls, 0);
      } else {
        expect(failing.snapshot[BodyMetricsRepository.storageKey],
            contains('_bodyDeletion'));
        expect(
            (await BodyMetricsRepository.load(failing, secureStore: secure))
                .state
                .value,
            isNull);
      }
      failing.armed = false;
      await repo.clear();
      expect(repo.state.status, BodyMetricsStatus.absent);
    });
  }

  test('clear queues behind an in-flight save and outranks its secure revision',
      () async {
    native.rejectDelete = false;
    native.writeEntered = Completer<void>();
    native.releaseWrite = Completer<void>();
    final save = body.update(weightKg: 72, femaleProfile: false);
    await native.writeEntered!.future;
    final clear = body.clear();
    native.releaseWrite!.complete();
    expect(await save, isTrue);
    await clear;
    expect((await secure.readResult()).status, SensitiveBodyReadStatus.absent);
    expect(
        (await BodyMetricsRepository.load(local, secureStore: secure))
            .metrics
            .weightKg,
        isNull);
  });
}

class _NativeStorage extends FlutterSecureStorage {
  bool rejectDelete = false;
  bool ignoreDelete = false;
  bool failRead = false;
  bool failWrite = false;
  int deleteCalls = 0;
  Completer<void>? writeEntered;
  Completer<void>? releaseWrite;
  @override
  Future<String?> read(
      {required String key,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    if (failRead) throw StateError('synthetic private payload');
    return super.read(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions);
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
    if (failWrite) throw StateError('synthetic private payload');
    if (writeEntered != null && !writeEntered!.isCompleted) {
      writeEntered!.complete();
      await releaseWrite!.future;
    }
    await super.write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions);
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
    deleteCalls++;
    if (rejectDelete) throw StateError('synthetic private payload');
    if (ignoreDelete) return;
    await super.delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions);
  }
}

class _RejectingLocal extends MemoryHydrionStore {
  final int blockedWrite;
  bool armed = false;
  int writes = 0;
  _RejectingLocal(super.initialValues, this.blockedWrite);
  @override
  Future<bool> writeString(String key, String value) async {
    if (armed && ++writes == blockedWrite) return false;
    return super.writeString(key, value);
  }
}
