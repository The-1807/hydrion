import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/domain/pomodoro_session.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/hydration_ai_action_executor.dart';
import 'package:hydrion/services/hydration_context_builder.dart';
import 'package:hydrion/services/local_profile_reset_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/policy_service.dart';
import 'package:hydrion/services/pomodoro_session_service.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/ui/components/reminder_storage_notice.dart';
import 'package:hydrion/ui/components/reminder_tile.dart';
import 'package:hydrion/ui/screens/hydrion_shell.dart';
import 'package:hydrion/ui/screens/profile_screen.dart';
import 'package:hydrion/ui/screens/reminders_screen.dart';
import 'package:provider/provider.dart';

import 'support/memory_protected_app_store.dart';
import 'support/protected_challenge_fixture.dart';

class Harness {
  final MemoryProtectedAppStore protected;
  final ReminderRepository reminders;
  final FakeHydrionNotificationAdapter adapter;
  final NotificationService service;
  Harness(this.protected, this.reminders, this.adapter, this.service);

  static Future<Harness> create({DateTime Function()? now}) async {
    final protected = MemoryProtectedAppStore();
    final reminders = await ReminderRepository.load(MemoryHydrionStore(),
        protectedStore: protected);
    final adapter = FakeHydrionNotificationAdapter();
    return Harness(
        protected,
        reminders,
        adapter,
        NotificationService(
            reminderPolicy: ReminderPolicy(),
            reminderRepository: reminders,
            adapter: adapter,
            now: now));
  }

  Future<void> outage() async {
    protected.reminderReadFailure = ProtectedReadStatus.unavailable;
    await reminders.refreshFromStore();
    expect(reminders.isKnown, isFalse);
  }

  Future<void> recover() async {
    protected.reminderReadFailure = null;
    await reminders.refreshFromStore();
    expect(reminders.isKnown, isTrue);
  }
}

class CountingNotifications extends FakeHydrionNotificationAdapter {
  int reconciliations = 0;
  @override
  Future<Set<int>?> pendingNotificationIds() async {
    reconciliations++;
    return super.pendingNotificationIds();
  }
}

DateTime soon() => DateTime.now().add(const Duration(hours: 2));

void main() {
  group('NotificationService', () {
    test('unknown storage creates nothing and schedules nothing', () async {
      final h = await Harness.create();
      await h.outage();
      final writes = h.protected.reminderWrites;
      final result = await h.service
          .createReminder(triggerTime: soon(), message: 'Water', priority: 1);
      expect(result.storageUnavailable, isTrue);
      expect(result.scheduled, isFalse);
      expect(h.adapter.scheduledIds, isEmpty);
      expect(h.protected.reminderWrites, writes);
    });

    test('rejected definition write precedes and prevents any OS schedule',
        () async {
      final h = await Harness.create();
      h.protected.reminderWriteFailure = ProtectedWriteStatus.failed;
      final result = await h.service
          .createReminder(triggerTime: soon(), message: 'Water', priority: 1);
      expect(result.storageUnavailable, isTrue);
      expect(h.adapter.scheduledIds, isEmpty);
    });

    test('reconcile skips unknown storage instead of treating it as empty',
        () async {
      final h = await Harness.create();
      final created = await h.service
          .createReminder(triggerTime: soon(), message: 'Water', priority: 1);
      await h.reminders.recordOrphanNotificationIds([991]);
      h.adapter.scheduledIds.add(991);
      await h.outage();
      await h.service.reconcileSchedules();
      await h.service.retryOrphanCleanup();
      expect(h.adapter.scheduledIds,
          {created.reminder!.platformNotificationId, 991},
          reason: 'no OS cancellation or rescheduling from unknown state');
      await h.recover();
      await h.service.reconcileSchedules();
      expect(
          h.adapter.scheduledIds, {created.reminder!.platformNotificationId});
      expect(h.reminders.orphanNotificationIds, isEmpty);
    });

    test('delete reports unknown storage and leaves the OS schedule', () async {
      final h = await Harness.create();
      final created = await h.service
          .createReminder(triggerTime: soon(), message: 'Water', priority: 1);
      await h.outage();
      await expectLater(h.service.deleteReminder(created.reminder!.id),
          throwsA(isA<ReminderStorageUnavailable>()));
      expect(await h.service.deleteRemindersIfKnown([created.reminder!.id]),
          isFalse);
      expect(h.adapter.scheduledIds,
          contains(created.reminder!.platformNotificationId));
      await h.recover();
      expect(h.reminders.byId(created.reminder!.id), isNotNull);
    });

    test('failed cancel-all during outage stays pending without throwing',
        () async {
      final h = await Harness.create();
      await h.outage();
      h.adapter.failCancelAll = true;
      expect(await h.service.cancelAllReminders(), isFalse);
    });

    test('policy suggestion reports unknown storage instead of "not needed"',
        () async {
      final h = await Harness.create();
      await h.outage();
      await expectLater(
          h.service.scheduleReminder(
              shortfallMl: 800,
              lastDrinkHoursAgo: 3,
              hydrationPercent: 0.2,
              isActiveTime: true),
          throwsA(isA<ReminderStorageUnavailable>()));
    });
  });

  group('Pomodoro', () {
    Future<(PomodoroSessionService, Harness, void Function(Duration))>
        fixture() async {
      var clock = DateTime(2030, 7, 23, 9, 17, 42);
      final h = await Harness.create(now: () => clock);
      final challenges =
          await loadTestChallengeRepository(MemoryHydrionStore());
      final sessions = PomodoroSessionService(
        challengeRepository: challenges,
        notificationService: h.service,
        timedSessionNotificationService: TimedSessionNotificationService(
          localeRepository: AppLocaleRepository.memory(),
          adapter: FakeTimedSessionNotificationAdapter(),
        ),
        now: () => clock,
      );
      await challenges.join(
        id: PomodoroSessionService.challengeId,
        name: 'Pomodoro Sip',
        description: 'Focus and hydrate deliberately.',
        targetMl: 2200,
        durationDays: 3,
        joinedAt: clock,
        parameters: {
          'sessionMinutes': 25,
          'sessionsPerDay': 1,
          'amountMl': 150,
          'shortBreakMinutes': 5,
          'notifications': 'enabled',
          'autoStartNext': 'disabled',
          'challengeDurationDays': 3,
          'timerStatus': 'stopped',
        },
      );
      return (sessions, h, (Duration d) => clock = clock.add(d));
    }

    test('unknown reminder storage never recreates or drops the association',
        () async {
      final (sessions, h, _) = await fixture();
      final started = (await sessions.start())!;
      final reminderId = started.reminderId;
      expect(reminderId, isNotNull);
      await h.outage();
      // Negative control: the former check read unknown storage as "reminder
      // missing", cleared the association and scheduled a replacement.
      final synced = (await sessions.syncReminderPreference())!;
      expect(synced.reminderId, reminderId);
      expect(sessions.currentState()!.reminderId, reminderId);
      await h.recover();
      expect(h.reminders.reminders, hasLength(1));
    });

    test('user pause during outage fails typed and leaves the timer intact',
        () async {
      final (sessions, h, _) = await fixture();
      final started = (await sessions.start())!;
      await h.outage();
      await expectLater(
          sessions.pause(), throwsA(isA<ReminderStorageUnavailable>()));
      final current = sessions.currentState()!;
      expect(current.lifecycle, PomodoroSessionLifecycle.running);
      expect(current.reminderId, started.reminderId);
    });

    test('natural completion is not blocked by reminder storage', () async {
      final (sessions, h, advance) = await fixture();
      await sessions.start();
      await h.outage();
      advance(const Duration(minutes: 26));
      final completed = await sessions.reconcile();
      expect(completed!.lifecycle, isNot(PomodoroSessionLifecycle.running));
      expect(completed.history, hasLength(1));
    });
  });

  test('AI reminder suggestion is rejected, not applied, during outage',
      () async {
    final h = await Harness.create();
    await h.outage();
    final writes = h.protected.reminderWrites;
    final executor = LocalHydrationAiActionExecutor(
      hydrationRepository: HydrationRepository.memory(),
      reminderRepository: h.reminders,
      challengeRepository: ChallengeRepository.memory(),
      capabilityReporter: LocalAppCapabilityReporter(),
    );
    final result = await executor.execute(
      const SuggestReminderAction(
          message: 'Take a sip in 20 minutes.',
          delay: Duration(minutes: 20),
          priority: 2),
      userConfirmed: true,
      now: DateTime(2030, 7, 1, 10),
    );
    expect(result.status, HydrationAiActionExecutionStatus.rejected);
    expect(h.protected.reminderWrites, writes);
  });

  test('coaching context reports unknown reminders as null, not zero',
      () async {
    final h = await Harness.create();
    LocalHydrationContextProvider provider() => LocalHydrationContextProvider(
          hydrationRepository: HydrationRepository.memory(),
          reminderRepository: h.reminders,
          challengeRepository: ChallengeRepository.memory(),
          capabilityReporter: LocalAppCapabilityReporter(),
          settingsRepository: UserSettingsRepository.memory(),
        );
    expect((await provider().getHydrationContext()).reminder.savedReminderCount,
        0);
    await h.outage();
    final context = (await provider().getHydrationContext()).reminder;
    expect(context.savedReminderCount, isNull);
    expect(context.nextReminderAt, isNull);
  });

  test('startup, reconciliation and reset survive a reminder outage', () async {
    final protected = MemoryProtectedAppStore()
      ..reminderReadFailure = ProtectedReadStatus.unavailable;
    final services = await HydrionServices.fromStore(MemoryHydrionStore(),
        protectedAppStore: protected,
        notificationAdapter: FakeHydrionNotificationAdapter());
    expect(services.reminderRepository.isKnown, isFalse);
    expect(services.challengeRepository.isKnown, isTrue);
    await services.notificationService.initialize();
    await services.notificationService.reconcileSchedules();
    await services.pomodoroSessionService.reconcile();
    final reset = await services.localProfileResetService.resetLocalProfile();
    expect(reset.reminderDeletion, LocalProfileSubsystemStatus.failed);
    expect(reset.status, LocalProfileResetStatus.failed);
    expect(reset.challengeDeletion, LocalProfileSubsystemStatus.completed);
    expect(services.reminderRepository.storageStatus,
        ReminderStorageStatus.deletionPending);
  });

  group('reminder UI', () {
    Future<Harness> pump(WidgetTester tester, Widget home,
        {String language = 'en'}) async {
      final h = (await tester.runAsync(Harness.create))!;
      await tester.runAsync(h.outage);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ReminderRepository>.value(value: h.reminders),
          Provider<AppCapabilityReporter>(
              create: (_) => LocalAppCapabilityReporter()),
          Provider<NotificationService>.value(value: h.service),
          ChangeNotifierProvider(
              create: (_) => UserSettingsRepository.memory()),
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ));
      await tester.pumpAndSettle();
      return h;
    }

    for (final language in ['en', 'fr', 'es']) {
      testWidgets('$language Reminders screen never shows unknown as empty',
          (tester) async {
        await pump(tester, const RemindersScreen(), language: language);
        final l10n = lookupAppLocalizations(Locale(language));
        expect(find.byType(ReminderStorageNotice), findsOneWidget);
        expect(find.text(l10n.reminderStorageUnavailable), findsOneWidget);
        expect(find.text(l10n.noLocalRemindersSaved), findsNothing);
        expect(find.byKey(const Key('add-reminder-button')), findsNothing);
      });
    }

    testWidgets('retry restores the Reminders screen', (tester) async {
      final h = await pump(tester, const RemindersScreen());
      h.protected.reminderReadFailure = null;
      await tester.tap(find.byKey(const Key('reminder-storage-retry')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(h.reminders.isKnown, isTrue);
      expect(find.byType(ReminderStorageNotice), findsNothing);
      expect(find.text('No local reminders saved'), findsOneWidget);
      expect(find.byKey(const Key('add-reminder-button')), findsOneWidget);
    });

    testWidgets('reminder tile reports unavailable, not "no saved"',
        (tester) async {
      await pump(
          tester,
          const Scaffold(
              body: ReminderTile(
                  shortfallMl: 500,
                  lastDrinkHoursAgo: 2,
                  hydrationPercent: 0.4,
                  isActiveTime: true)));
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.reminderStorageUnavailable), findsOneWidget);
    });

    testWidgets('profile summary reports unavailable, not "no reminders"',
        (tester) async {
      await pump(tester, const ProfileScreen());
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.noRemindersYet), findsNothing);
      expect(find.text(l10n.unavailable), findsWidgets);
    });
  });

  group('shell lifecycle', () {
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

    for (final rollover in [false, true]) {
      testWidgets(
          'reminder outage is contained and later lifecycle retries '
          'rollover=$rollover', (tester) async {
        final store = MemoryProtectedAppStore();
        final adapter = CountingNotifications();
        final services = await HydrionServices.fromStore(MemoryHydrionStore(),
            protectedAppStore: store,
            notificationAdapter: adapter,
            locationService: FakeHydrionLocationService(),
            timedSessionNotificationAdapter:
                FakeTimedSessionNotificationAdapter());
        await services.guidedTourRepository.skipCoreTour();
        await tester
            .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
        await tester.pumpAndSettle();
        store.reminderReadFailure = ProtectedReadStatus.unavailable;
        await services.reminderRepository.refreshFromStore();
        final count = adapter.reconciliations;
        if (rollover) {
          await tester.pump(const Duration(days: 1));
        } else {
          (tester.state(find.byType(HydrionShell)) as WidgetsBindingObserver)
              .didChangeAppLifecycleState(AppLifecycleState.resumed);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(adapter.reconciliations, count,
            reason: 'unknown reminder storage is not reconciled as empty');
        expect(services.reminderRepository.isKnown, isFalse);
        store.reminderReadFailure = null;
        (tester.state(find.byType(HydrionShell)) as WidgetsBindingObserver)
            .didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(services.reminderRepository.isKnown, isTrue);
        expect(adapter.reconciliations, greaterThan(count));
        await tester.pumpWidget(const SizedBox.shrink());
        await services.dispose();
      });
    }
  });
}
