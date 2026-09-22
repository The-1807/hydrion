import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';
import 'package:hydrion/services/health_connect_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unresponsive Health Connect binding has a bounded deadline',
      (tester) async {
    const channel = MethodChannel('hydrion/health_connect');
    final pending = Completer<Map<String, Object?>>();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => pending.future);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final call =
        const MethodChannelHealthConnectBridge().invoke('authorizationState');
    final check = expectLater(call, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 15));
    await check;
    pending.complete({'state': 'granted'});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('unresponsive provider discovery has a bounded deadline',
      (tester) async {
    const channel = MethodChannel('hydrion/android_health_provider_discovery');
    final pending = Completer<Map<String, Object?>>();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => pending.future);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final call = const MethodChannelAndroidHealthDiscoveryBridge().discover();
    final check = expectLater(call, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 10));
    await check;
    pending.complete({});
    await tester.pump();
  });

  testWidgets('user permission sheet is not cancelled by the binding deadline',
      (tester) async {
    const channel = MethodChannel('hydrion/health_connect');
    final pending = Completer<Map<String, Object?>>();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => pending.future);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final call =
        const MethodChannelHealthConnectBridge().invoke('requestPermissions');
    var completed = false;
    final result = call.then((value) {
      completed = true;
      return value;
    });
    await tester.pump(const Duration(minutes: 2));
    expect(completed, isFalse);
    pending.complete({'state': 'granted'});
    await tester.pump();
    expect((await result)['state'], 'granted');
  });
}
