import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/ui/screens/hydrion_shell.dart';
import 'support/memory_protected_app_store.dart';

class CountingNotifications extends FakeHydrionNotificationAdapter {
  int reconciliations = 0;
  bool failUnexpectedly = false;
  @override
  Future<Set<int>?> pendingNotificationIds() async {
    reconciliations++;
    if (failUnexpectedly) {
      throw StateError('synthetic private notification detail');
    }
    return super.pendingNotificationIds();
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('hydrion/app_locale'), (_) async => null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('hydrion/app_locale'), null));
  Future<HydrionServices> fixture(
      MemoryProtectedAppStore store, CountingNotifications adapter) async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore(),
        protectedAppStore: store,
        notificationAdapter: adapter,
        locationService: FakeHydrionLocationService(),
        timedSessionNotificationAdapter: FakeTimedSessionNotificationAdapter());
    await services.guidedTourRepository.skipCoreTour();
    await services.challengeRepository.join(
        id: 'plant-twin-challenge',
        name: 'Plant',
        description: '',
        targetMl: 2000,
        durationDays: 7,
        parameters: const {'cue': 'test'});
    return services;
  }

  testWidgets('Home and coaching preserve unknown challenge and recover',
      (tester) async {
    final store = MemoryProtectedAppStore();
    final services = await fixture(store, CountingNotifications());
    final original = services.challengeRepository.activeChallenge!.instanceId;
    await tester
        .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
    await tester.pumpAndSettle();
    store.challengeReadFailure = ProtectedReadStatus.unavailable;
    await services.challengeRepository.refreshFromStore();
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(Scaffold).first));
    await tester.scrollUntilVisible(
        find.text(l10n.challengeStorageUnavailable), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text(l10n.challengePick), findsNothing);
    expect(find.text(l10n.challengeStorageUnavailable), findsOneWidget);
    final unknown =
        await services.hydrationContextProvider.getHydrationContext();
    expect(unknown.challenge.hasActiveChallenge, isNull);
    expect(unknown.challenge.activeChallengeId, isNull);
    store.challengeReadFailure = null;
    await services.challengeRepository.refreshFromStore();
    await tester.pumpAndSettle();
    expect(services.challengeRepository.activeChallenge!.instanceId, original);
    expect(find.text(l10n.challengeStorageUnavailable), findsNothing);
    expect(find.text(l10n.activeChallenge), findsWidgets);
    expect(
        (await services.hydrationContextProvider.getHydrationContext())
            .challenge
            .hasActiveChallenge,
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await services.dispose();
  });

  test('coaching distinguishes unavailable from true absence without payload',
      () async {
    final store = MemoryProtectedAppStore();
    final services = await fixture(store, CountingNotifications());
    final active =
        await services.hydrationContextProvider.getHydrationContext();
    expect(active.challenge.hasActiveChallenge, isTrue);
    store.challengeReadFailure = ProtectedReadStatus.unavailable;
    await services.challengeRepository.refreshFromStore();
    final unknown =
        (await services.hydrationContextProvider.getHydrationContext())
            .challenge;
    expect(unknown.hasActiveChallenge, isNull);
    expect(unknown.activeChallengeId, isNull);
    expect(unknown.activeChallengeName, isNull);
    expect(unknown.todayMl, isNull);
    expect(unknown.progressPercent, isNull);
    store.challengeReadFailure = null;
    await services.challengeRepository.refreshFromStore();
    expect(
        (await services.hydrationContextProvider.getHydrationContext())
            .challenge
            .activeChallengeId,
        active.challenge.activeChallengeId);
    await services.challengeRepository.clear();
    expect(
        (await services.hydrationContextProvider.getHydrationContext())
            .challenge
            .hasActiveChallenge,
        isFalse);
    await services.dispose();
  });

  testWidgets('unexpected lifecycle error is reported without private payload',
      (tester) async {
    final adapter = CountingNotifications();
    final services = await fixture(MemoryProtectedAppStore(), adapter);
    await tester
        .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
    await tester.pumpAndSettle();
    adapter.failUnexpectedly = true;
    (tester.state(find.byType(HydrionShell)) as WidgetsBindingObserver)
        .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('lifecycle reconciliation failed'));
    expect(error.toString(), isNot(contains('synthetic private')));
    await tester.pumpWidget(const SizedBox.shrink());
    await services.dispose();
  });

  for (final rollover in [false, true]) {
    testWidgets(
        'shell continues independent reconciliation outage rollover=$rollover',
        (tester) async {
      final store = MemoryProtectedAppStore();
      final adapter = CountingNotifications();
      final services = await fixture(store, adapter);
      await tester
          .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
      await tester.pumpAndSettle();
      store.challengeReadFailure = ProtectedReadStatus.unavailable;
      await services.challengeRepository.refreshFromStore();
      final count = adapter.reconciliations;
      if (rollover) {
        await tester.pump(const Duration(days: 1));
      } else {
        (tester.state(find.byType(HydrionShell)) as WidgetsBindingObserver)
            .didChangeAppLifecycleState(AppLifecycleState.resumed);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(adapter.reconciliations, greaterThan(count));
      expect(services.challengeRepository.isKnown, isFalse);
      store.challengeReadFailure = null;
      (tester.state(find.byType(HydrionShell)) as WidgetsBindingObserver)
          .didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(services.challengeRepository.isKnown, isTrue);
      expect(services.challengeRepository.activeChallenge, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await services.dispose();
    });
  }
}
