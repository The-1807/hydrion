import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  late Map<String, Object> native;
  late bool reject;
  late bool failReload;
  late bool throwWrite;
  late bool dropRemoval;
  String? cachedDuringRejection;
  late SharedPreferences preferences;
  Completer<void>? reloadEntered;
  Completer<void>? releaseReload;
  var reads = 0;
  setUp(() async {
    native = {};
    reject = false;
    failReload = false;
    throwWrite = false;
    dropRemoval = false;
    cachedDuringRejection = null;
    reloadEntered = null;
    releaseReload = null;
    reads = 0;
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        reads++;
        if (failReload) throw PlatformException(code: 'synthetic_read_failure');
        final captured = Map<String, Object>.of(native);
        final entered = reloadEntered;
        if (entered != null && !entered.isCompleted) {
          entered.complete();
          await releaseReload!.future;
        }
        return captured;
      }
      if (call.method == 'setString') {
        final args = call.arguments as Map;
        if (throwWrite) {
          throw PlatformException(
              code: 'synthetic_write_failure', message: 'private payload');
        }
        if (reject) {
          cachedDuringRejection = preferences
              .getString((args['key'] as String).substring('flutter.'.length));
          return false;
        }
        native[args['key'] as String] = args['value'] as String;
        return true;
      }
      if (call.method == 'remove') {
        if (reject) return false;
        if (!dropRemoval) native.remove((call.arguments as Map)['key']);
        return true;
      }
      throw StateError('Unexpected preference operation');
    });
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pilot cleanup rejects native false and reloads the lost cache value',
      () async {
    final store = SharedPreferencesHydrionStore(preferences);
    expect(await store.writeString('pilot_synthetic', 'synthetic'), isTrue);
    reject = true;
    expect(await store.removeAcknowledged('pilot_synthetic'), isFalse);
    expect(native['flutter.pilot_synthetic'], 'synthetic');
    expect(await store.readString('pilot_synthetic'), 'synthetic');
    reject = false;
    expect(await store.removeAcknowledged('pilot_synthetic'), isTrue);
    expect(await store.readString('pilot_synthetic'), isNull);
    expect(native.containsKey('flutter.pilot_synthetic'), isFalse);
  });

  test('pilot cleanup verifies native absence even after true acknowledgement',
      () async {
    final store = SharedPreferencesHydrionStore(preferences);
    await store.writeString('pilot_synthetic', 'synthetic');
    dropRemoval = true;
    expect(await store.removeAcknowledged('pilot_synthetic'), isFalse);
    expect(await store.readString('pilot_synthetic'), 'synthetic');
    dropRemoval = false;
    expect(await store.removeAcknowledged('pilot_synthetic'), isTrue);
    expect(await store.readString('pilot_synthetic'), isNull);
  });

  test('native rejection cannot publish cached body B over secure A', () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    final secure = MemorySensitiveBodyMetricsStore();
    final repo = await BodyMetricsRepository.load(adapter, secureStore: secure);
    expect(
        await repo.save(const HydrionBodyMetrics(weightKg: 70),
            femaleProfile: false),
        isTrue);
    final oldNative = Map.of(native);
    reject = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false), isFalse);
    expect(jsonDecode(cachedDuringRejection!)['_bodyAuthority']['revision'], 2);
    expect(native, oldNative);
    expect(repo.state.isKnown, isFalse);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.localWriteFailed);
    // Secure B is recoverable even though local publication was rejected.
    expect((await secure.read())!['weightKg'], 71);
    await repo.reload();
    expect(repo.state.isKnown, isFalse);
    reject = false;
    SharedPreferences.resetStatic();
    final restarted = await BodyMetricsRepository.load(
        await SharedPreferencesHydrionStore.create(),
        secureStore: secure);
    expect(restarted.metrics.weightKg, 71);
    expect(restarted.state.revision, 2);
    final recovered = Map.of(native);
    await restarted.reload();
    expect(native, recovered);
    expect(restarted.metrics.weightKg, 71);
  });

  for (final twoAdapters in [false, true]) {
    test('paused old reload cannot overwrite newer write: two=$twoAdapters',
        () async {
      final first = SharedPreferencesHydrionStore(preferences);
      final second =
          twoAdapters ? SharedPreferencesHydrionStore(preferences) : first;
      await first.writeString('sample', 'A');
      reject = true;
      expect(await first.writeString('sample', 'rejected'), isFalse);
      reject = false;
      reloadEntered = Completer<void>();
      releaseReload = Completer<void>();
      final oldRead = first.readString('sample');
      await reloadEntered!.future;
      var writeCompleted = false;
      final write = second.writeString('sample', 'B').then((ack) {
        writeCompleted = true;
        return ack;
      });
      final laterRead = second.readString('sample');
      await pumpEventQueue();
      expect(writeCompleted, isFalse,
          reason: 'Write must wait for the old reload');
      releaseReload!.complete();
      await oldRead;
      expect(await write, isTrue);
      await laterRead;
      expect(native['flutter.sample'], 'B');
      expect(await first.readString('sample'), 'B');
      expect(await second.readString('sample'), 'B');
    });
  }

  test('native false does not interrupt reminder update notification',
      () async {
    final repo = await ReminderRepository.load(
        SharedPreferencesHydrionStore(preferences));
    final saved = await repo.save(
        triggerTime: DateTime(2026, 9, 28, 12), message: 'Before', priority: 1);
    var notifications = 0;
    repo.addListener(() => notifications++);
    final before = Map.of(native);
    reject = true;
    final updated = await repo.update(id: saved.id, message: 'After');
    expect(updated!.message, 'After');
    expect(notifications, 1);
    expect(native, before,
        reason: 'Legacy control flow, not persistence integrity');
  });

  test('native false does not freeze locale notification', () async {
    final repo = await AppLocaleRepository.load(
        SharedPreferencesHydrionStore(preferences),
        deviceLocale: const Locale('en'));
    var notifications = 0;
    repo.addListener(() => notifications++);
    reject = true;
    await repo.selectLocale(const Locale('fr'));
    expect(repo.locale, const Locale('fr'));
    expect(repo.selectionCompleted, isTrue);
    expect(notifications, 1);
    expect(native, isEmpty,
        reason: 'Legacy control flow, not persistence integrity');
  });

  test(
      'native false preserves reminder cancellation then replacement scheduling',
      () async {
    final repo = await ReminderRepository.load(
        SharedPreferencesHydrionStore(preferences));
    final notifications = FakeHydrionNotificationAdapter();
    final service = NotificationService(
        reminderPolicy: ReminderPolicy(),
        reminderRepository: repo,
        adapter: notifications);
    final initial = await service.createReminder(
        triggerTime: DateTime.now().add(const Duration(hours: 1)),
        message: 'Before',
        priority: 1,
        requestPermissionIfNeeded: true);
    final id = initial.reminder!.id;
    final nativeBefore = Map.of(native);
    reject = true;
    final replacement = await service.updateReminder(id: id, message: 'After');
    expect(replacement.state, ReminderScheduleState.scheduledExactly);
    expect(replacement.reminder!.message, 'After');
    expect(notifications.scheduledIds,
        contains(initial.reminder!.platformNotificationId));
    expect(native, nativeBefore,
        reason: 'Existing integrity debt is not repaired here');
  });

  test('clean acknowledged writes and reads do not force reloads', () async {
    final first = SharedPreferencesHydrionStore(preferences);
    final second = SharedPreferencesHydrionStore(preferences);
    final initialReads = reads;
    expect(await first.writeString('sample', 'A'), isTrue);
    expect(await second.readString('sample'), 'A');
    expect(await second.writeString('sample', 'B'), isTrue);
    expect(await first.readString('sample'), 'B');
    expect(reads, initialReads);
  });

  test('adapter rejects native false and invalidates the optimistic cache',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    reject = true;
    expect(await adapter.writeString('sample', 'B'), isFalse);
    expect(cachedDuringRejection, 'B');
    expect(await adapter.readString('sample'), 'A');
  });

  test(
      'new adapters cannot bypass rejected-cache invalidation or failed reload',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    reject = true;
    expect(await adapter.writeString('sample', 'B'), isFalse);
    final other = SharedPreferencesHydrionStore(preferences);
    failReload = true;
    await expectLater(
        other.readString('sample'), throwsA(isA<PlatformException>()));
    failReload = false;
    expect(await other.readString('sample'), 'A');
    expect(await adapter.readString('sample'), 'A');
  });

  test('native exception still propagates and invalidates cache trust',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    throwWrite = true;
    await expectLater(
        adapter.writeString('sample', 'B'), throwsA(isA<PlatformException>()));
    expect(await adapter.readString('sample'), 'A');
  });

  test(
      'failure of both stores rejects B instead of claiming a recoverable save',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    final secure = _RejectSecure();
    final repo = await BodyMetricsRepository.load(adapter, secureStore: secure);
    await repo.save(const HydrionBodyMetrics(weightKg: 70),
        femaleProfile: false);
    secure.reject = true;
    reject = true;
    expect(await repo.update(weightKg: 71, femaleProfile: false), isFalse);
    expect(cachedDuringRejection, isNull,
        reason: 'Secure failure must not even attempt a plaintext fallback');
    expect(repo.state.isKnown, isFalse);
    SharedPreferences.resetStatic();
    reject = false;
    final loaded = await BodyMetricsRepository.load(
        await SharedPreferencesHydrionStore.create(),
        secureStore: secure);
    // B was explicitly rejected, not acknowledged and then silently reverted.
    expect(loaded.metrics.weightKg, 70);
    expect(loaded.state.revision, 1);
  });
}

class _RejectSecure extends MemorySensitiveBodyMetricsStore {
  bool reject = false;
  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (reject) throw StateError('synthetic secure rejection');
    await super.write(fields);
  }
}
