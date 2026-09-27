import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  late Map<String, Object> native;
  late bool reject;
  late bool failReload;
  late bool throwWrite;
  String? cachedDuringRejection;
  late SharedPreferences preferences;
  setUp(() async {
    native = {};
    reject = false;
    failReload = false;
    throwWrite = false;
    cachedDuringRejection = null;
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        if (failReload) throw PlatformException(code: 'synthetic_read_failure');
        return Map<String, Object>.of(native);
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
      throw StateError('Unexpected preference operation');
    });
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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

  test('adapter rejects native false and invalidates the optimistic cache',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    reject = true;
    await expectLater(adapter.writeString('sample', 'B'),
        throwsA(isA<LocalStoreWriteFailure>()));
    expect(cachedDuringRejection, 'B');
    expect(await adapter.readString('sample'), 'A');
  });

  test(
      'new adapters cannot bypass rejected-cache invalidation or failed reload',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    reject = true;
    await expectLater(adapter.writeString('sample', 'B'),
        throwsA(isA<LocalStoreWriteFailure>()));
    final other = SharedPreferencesHydrionStore(preferences);
    failReload = true;
    await expectLater(
        other.readString('sample'), throwsA(isA<PlatformException>()));
    failReload = false;
    expect(await other.readString('sample'), 'A');
    expect(await adapter.readString('sample'), 'A');
  });

  test('native exception has the same payload-free failed-write contract',
      () async {
    final adapter = SharedPreferencesHydrionStore(preferences);
    await adapter.writeString('sample', 'A');
    throwWrite = true;
    await expectLater(
        adapter.writeString('sample', 'B'),
        throwsA(isA<LocalStoreWriteFailure>().having(
            (e) => e.toString(), 'description', 'LocalStoreWriteFailure')));
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
    expect(jsonDecode(cachedDuringRejection!)['weightKg'], 71);
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
