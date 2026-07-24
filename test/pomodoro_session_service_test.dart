import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/pomodoro_session.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';
import 'package:hydrion/services/pomodoro_session_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  group('timestamp-authoritative Pomodoro timer', () {
    test('start creates one session and countdown agrees with meter', () async {
      final fixture = await PomodoroFixture.create();

      final starts = await Future.wait([
        fixture.sessions.start(),
        fixture.sessions.start(),
      ]);
      final started = starts.first;
      final duplicate = starts.last;

      expect(started, isNotNull);
      expect(duplicate!.sessionId, started!.sessionId);
      expect(fixture.reminders.reminders, hasLength(1));
      expect(started.reminderId, fixture.reminders.reminders.single.id);

      var snapshot = started.snapshot(fixture.clock.now);
      expect(snapshot.remainingDuration, const Duration(minutes: 25));
      expect(snapshot.elapsedDuration, Duration.zero);
      expect(snapshot.progress, 0);

      fixture.clock.advance(const Duration(minutes: 7, seconds: 30));
      snapshot = fixture.sessions.currentState()!.snapshot(fixture.clock.now);
      expect(
          snapshot.remainingDuration, const Duration(minutes: 17, seconds: 30));
      expect(snapshot.elapsedDuration, const Duration(minutes: 7, seconds: 30));
      expect(snapshot.progress, closeTo(0.3, 0.0001));
    });

    test('delayed callbacks and background time use timestamps', () async {
      final fixture = await PomodoroFixture.create();
      await fixture.sessions.start();

      fixture.clock.advance(const Duration(minutes: 24, seconds: 59));
      var snapshot =
          fixture.sessions.currentState()!.snapshot(fixture.clock.now);
      expect(snapshot.remainingDuration, const Duration(seconds: 1));
      expect(snapshot.progress, lessThan(1));

      fixture.clock.advance(const Duration(seconds: 8));
      final completed = await fixture.sessions.reconcile();
      snapshot = completed!.snapshot(fixture.clock.now);
      expect(snapshot.remainingDuration, Duration.zero);
      expect(snapshot.progress, 1);
      expect(completed.history, hasLength(1));
    });

    test('pause freezes both values and resume continues exactly', () async {
      final fixture = await PomodoroFixture.create();
      await fixture.sessions.start();
      fixture.clock.advance(const Duration(minutes: 4));

      final paused = await fixture.sessions.pause();
      final frozen = paused!.snapshot(fixture.clock.now);
      expect(frozen.remainingDuration, const Duration(minutes: 21));
      expect(frozen.progress, closeTo(0.16, 0.0001));
      expect(fixture.reminders.reminders, isEmpty);

      fixture.clock.advance(const Duration(hours: 3));
      final stillFrozen =
          fixture.sessions.currentState()!.snapshot(fixture.clock.now);
      expect(stillFrozen.remainingDuration, frozen.remainingDuration);
      expect(stillFrozen.progress, frozen.progress);

      final resumed = await fixture.sessions.resume();
      expect(resumed!.completionAt,
          fixture.clock.now.add(const Duration(minutes: 21)));
      expect(fixture.reminders.reminders, hasLength(1));
      fixture.clock.advance(const Duration(minutes: 1));
      expect(
        fixture.sessions
            .currentState()!
            .snapshot(fixture.clock.now)
            .remainingDuration,
        const Duration(minutes: 20),
      );
    });

    test('restart replaces identity and stop prevents restoration', () async {
      final fixture = await PomodoroFixture.create();
      final first = await fixture.sessions.start();
      fixture.clock.advance(const Duration(minutes: 5));

      final restarted = await fixture.sessions.restart();
      expect(restarted!.sessionId, isNot(first!.sessionId));
      expect(restarted.snapshot(fixture.clock.now).remainingDuration,
          const Duration(minutes: 25));
      expect(restarted.snapshot(fixture.clock.now).progress, 0);
      expect(fixture.reminders.reminders, hasLength(1));

      final stopped = await fixture.sessions.stop();
      expect(stopped!.lifecycle, PomodoroSessionLifecycle.stopped);
      expect(fixture.reminders.reminders, isEmpty);
      fixture.clock.advance(const Duration(hours: 1));
      expect((await fixture.sessions.reconcile())!.lifecycle,
          PomodoroSessionLifecycle.stopped);
      expect(stopped.history, isEmpty);
    });

    test('natural and early completion commit exactly once', () async {
      final fixture = await PomodoroFixture.create();
      await fixture.sessions.start();
      fixture.clock.advance(const Duration(minutes: 25));

      final first = await fixture.sessions.completeNaturally();
      final second = await fixture.sessions.completeNaturally();
      expect(first!.completionCommitted, isTrue);
      expect(second!.history, hasLength(1));
      expect(fixture.reminders.reminders, isEmpty);

      await fixture.sessions.restart();
      fixture.clock.advance(const Duration(minutes: 2));
      final early = await fixture.sessions.completeEarly();
      expect(early!.history, hasLength(2));
      expect(early.history.last.endedEarly, isTrue);
      expect(early.history.last.completedAt, fixture.clock.now);
    });

    test('changed configuration applies only to a fresh restart', () async {
      final fixture = await PomodoroFixture.create();
      final running = await fixture.sessions.start();
      expect(running!.totalDuration, const Duration(minutes: 25));
      final challenge = fixture.challenges.activeChallenge!;
      await fixture.challenges.updateParameters({
        ...challenge.parameters,
        'sessionMinutes': 40,
      }, challengeId: PomodoroSessionService.challengeId);

      expect(
        fixture.sessions.currentState()!.totalDuration,
        const Duration(minutes: 25),
      );
      final restarted = await fixture.sessions.restart();
      expect(restarted!.totalDuration, const Duration(minutes: 40));
      expect(
        restarted.snapshot(fixture.clock.now).remainingDuration,
        const Duration(minutes: 40),
      );
    });

    test('first session on a new local day resets the daily session number',
        () async {
      final fixture = await PomodoroFixture.create(sessionsPerDay: 2);
      await fixture.sessions.start();
      await fixture.sessions.completeEarly();
      await fixture.sessions.recordSip(
        hydrationRepository: fixture.hydration,
      );
      await fixture.sessions.start();
      await fixture.sessions.completeEarly();
      await fixture.sessions.recordSip(
        hydrationRepository: fixture.hydration,
      );
      expect(fixture.sessions.currentState()!.sessionNumber, 2);

      fixture.clock.advance(const Duration(days: 1));
      final nextDay = await fixture.sessions.restart();

      expect(nextDay!.sessionNumber, 1);
      expect(nextDay.snapshot(fixture.clock.now).progress, 0);
    });
  });

  group('Pomodoro sip persistence', () {
    test('completion alone never records hydration', () async {
      final fixture = await PomodoroFixture.create();
      await fixture.sessions.start();
      fixture.clock.advance(const Duration(minutes: 25));
      await fixture.sessions.reconcile();

      expect(fixture.hydration.logs, isEmpty);
      expect(fixture.challenges.activeChallenge!.completedActionIds, isEmpty);
    });

    test('confirmed sip records configured amount once at actual time',
        () async {
      final fixture = await PomodoroFixture.create(sessionsPerDay: 2);
      await fixture.sessions.start();
      fixture.clock.advance(const Duration(minutes: 25));
      await fixture.sessions.reconcile();
      final eventTime = fixture.clock.now;

      final first = await fixture.sessions
          .recordSip(hydrationRepository: fixture.hydration);
      final duplicate = await fixture.sessions
          .recordSip(hydrationRepository: fixture.hydration);

      expect(first, isNotNull);
      expect(first!.volumeMl, 150);
      expect(first.timestamp, eventTime);
      expect(first.timestamp.hour, isNot(0));
      expect(duplicate, isNull);
      expect(fixture.hydration.logs, hasLength(1));
      expect(
        fixture.challenges
            .progressFor(fixture.hydration, now: fixture.clock.now)
            .completedDays,
        0,
        reason: 'one drink must not count twice toward a two-session day',
      );
    });

    test('measured drinks use selected amounts and later sessions remain valid',
        () async {
      final fixture = await PomodoroFixture.create(sessionsPerDay: 2);
      await fixture.sessions.start();
      await fixture.sessions.completeEarly();
      final first = await fixture.sessions.recordMeasuredDrink(
        hydrationRepository: fixture.hydration,
        amountMl: 210,
      );
      await fixture.sessions.start();
      await fixture.sessions.completeEarly();
      fixture.clock.advance(const Duration(minutes: 3));
      final second = await fixture.sessions.recordMeasuredDrink(
        hydrationRepository: fixture.hydration,
        amountMl: 275,
      );

      expect(first!.volumeMl, 210);
      expect(second!.volumeMl, 275);
      expect(fixture.hydration.logs, hasLength(2));
      expect(
        fixture.challenges
            .progressFor(fixture.hydration, now: fixture.clock.now)
            .completedDays,
        1,
      );
    });

    test('failed hydration persistence does not advance session', () async {
      final fixture = await PomodoroFixture.create();
      await fixture.sessions.start();
      await fixture.sessions.completeEarly();
      final failingStore = FailingHydrionStore()..failWrites = true;
      final hydration = await HydrationRepository.load(failingStore);
      final firstAttemptAt = fixture.clock.now;

      await expectLater(
        fixture.sessions.recordSip(hydrationRepository: hydration),
        throwsStateError,
      );
      expect(hydration.logs, isEmpty);
      expect(fixture.sessions.currentState()!.lifecycle,
          PomodoroSessionLifecycle.completed);

      fixture.clock.advance(const Duration(days: 1));
      failingStore.failWrites = false;
      final retry =
          await fixture.sessions.recordSip(hydrationRepository: hydration);
      expect(retry, isNotNull);
      expect(hydration.logs, hasLength(1));
      expect(retry!.timestamp, firstAttemptAt);
    });
  });

  group('Pomodoro reminder and restoration', () {
    test('resume and restart replace reminders without duplicates', () async {
      final fixture = await PomodoroFixture.create();
      final first = await fixture.sessions.start();
      final firstReminder = first!.reminderId;
      await fixture.sessions.pause();
      expect(fixture.reminders.byId(firstReminder!), isNull);

      fixture.clock.advance(const Duration(minutes: 1));
      final resumed = await fixture.sessions.resume();
      final resumedReminder = resumed!.reminderId;
      expect(resumedReminder, isNot(firstReminder));
      expect(fixture.reminders.reminders, hasLength(1));

      final restarted = await fixture.sessions.restart();
      expect(restarted!.sessionId, isNot(resumed.sessionId));
      expect(restarted.reminderId, isNotNull);
      expect(fixture.reminders.reminders, hasLength(1));
    });

    test('approximate fallback is persisted and failure stores no active id',
        () async {
      final approximate = await PomodoroFixture.create(
        adapter: FakeHydrionNotificationAdapter(
          permission: HydrionNotificationPermissionState.granted,
          preciseScheduling: false,
        ),
      );
      final scheduled = await approximate.sessions.start();
      expect(scheduled!.reminderSchedulingMode,
          ReminderScheduleState.scheduledApproximately.name);
      expect(scheduled.reminderId, isNotNull);

      final failing = await PomodoroFixture.create(
        adapter: FakeHydrionNotificationAdapter(
          permission: HydrionNotificationPermissionState.granted,
          failScheduling: true,
        ),
      );
      final unscheduled = await failing.sessions.start();
      expect(unscheduled!.reminderId, isNull);
      expect(unscheduled.reminderSchedulingMode, isNull);
    });

    test('notification preference cancels and recreates the association',
        () async {
      final fixture = await PomodoroFixture.create();
      final started = await fixture.sessions.start();
      final challenge = fixture.challenges.activeChallenge!;
      await fixture.challenges.updateParameters({
        ...challenge.parameters,
        'notifications': 'disabled',
      }, challengeId: PomodoroSessionService.challengeId);

      final disabled = await fixture.sessions.syncReminderPreference();
      expect(disabled!.reminderId, isNull);
      expect(fixture.reminders.reminders, isEmpty);

      final latest = fixture.challenges.activeChallenge!;
      await fixture.challenges.updateParameters({
        ...latest.parameters,
        'notifications': 'enabled',
      }, challengeId: PomodoroSessionService.challengeId);
      final enabled = await fixture.sessions.syncReminderPreference();
      expect(enabled!.reminderId, isNotNull);
      expect(fixture.reminders.reminders, hasLength(1));
      expect(enabled.sessionId, started!.sessionId);
    });

    test('running process restoration commits elapsed session once', () async {
      final store = MemoryHydrionStore();
      final first = await PomodoroFixture.create(store: store);
      await first.sessions.start();
      first.clock.advance(const Duration(minutes: 30));

      final restored = await PomodoroFixture.restore(
        store: store,
        clock: first.clock,
      );
      final completed = await restored.sessions.reconcile();
      await restored.sessions.reconcile();

      expect(completed!.lifecycle, PomodoroSessionLifecycle.completed);
      expect(completed.history, hasLength(1));
      expect(restored.hydration.logs, isEmpty);
    });

    test('paused process restoration does not consume elapsed wall time',
        () async {
      final store = MemoryHydrionStore();
      final first = await PomodoroFixture.create(store: store);
      await first.sessions.start();
      first.clock.advance(const Duration(minutes: 6));
      await first.sessions.pause();
      first.clock.advance(const Duration(days: 1));

      final restored = await PomodoroFixture.restore(
        store: store,
        clock: first.clock,
      );
      final state = await restored.sessions.reconcile();
      expect(state!.lifecycle, PomodoroSessionLifecycle.paused);
      expect(state.snapshot(restored.clock.now).remainingDuration,
          const Duration(minutes: 19));
    });

    test('legacy date-only history stays explicitly date-only', () async {
      final fixture = await PomodoroFixture.create();
      final challenge = fixture.challenges.activeChallenge!;
      await fixture.challenges.updateParameters({
        ...challenge.parameters,
        'pomodoroSessionHistory': [
          {
            'sessionId': 'legacy-session',
            'sessionNumber': 1,
            'completedAt': '2026-07-18',
            'endedEarly': false,
          }
        ],
      }, challengeId: PomodoroSessionService.challengeId);

      final state = fixture.sessions.currentState()!;
      expect(state.history.single.hasAuthenticTime, isFalse);
      expect(state.history.single.completedAt, DateTime(2026, 7, 18));
    });

    test('corrupt nested state falls back to safe legacy migration', () async {
      final fixture = await PomodoroFixture.create();
      final challenge = fixture.challenges.activeChallenge!;
      await fixture.challenges.updateParameters({
        ...challenge.parameters,
        'timerStatus': 'paused',
        'timerPausedSeconds': 300,
        'pomodoroSession': {'unsupported': true},
      }, challengeId: PomodoroSessionService.challengeId);

      final state = await fixture.sessions.reconcile();
      expect(state!.lifecycle, PomodoroSessionLifecycle.paused);
      expect(state.pausedRemaining, const Duration(minutes: 5));
    });

    test('UTC serialization preserves the absolute completion instant', () {
      final updated = DateTime.utc(2030, 7, 23, 13, 17, 42);
      final state = PomodoroSessionState.initial(
        challengeInstanceId: 'pomodoro-instance',
        totalDuration: const Duration(minutes: 25),
        now: updated,
      ).copyWith(
        sessionId: 'session-1',
        lifecycle: PomodoroSessionLifecycle.running,
        startedAt: updated,
        completionAt: updated.add(const Duration(minutes: 25)),
      );

      final restored = PomodoroSessionState.fromJson(state.toJson())!;
      expect(restored.startedAt, updated);
      expect(
        restored.completionAt,
        updated.add(const Duration(minutes: 25)),
      );
      expect(
        restored
            .snapshot(updated.add(const Duration(minutes: 5)))
            .remainingDuration,
        const Duration(minutes: 20),
      );
    });

    test('challenge pause exposes nested reminder for safe cancellation',
        () async {
      final fixture = await PomodoroFixture.create();
      final running = await fixture.sessions.start();

      final change = await fixture.challenges.pauseChallenge(
        PomodoroSessionService.challengeId,
        pausedAt: fixture.clock.now,
      );

      expect(change.obsoleteReminderIds, contains(running!.reminderId));
      final paused = PomodoroSessionState.fromJson(
        change.challenge!.parameters['pomodoroSession'],
      )!;
      expect(paused.lifecycle, PomodoroSessionLifecycle.paused);
      expect(paused.reminderId, isNull);
    });
  });
}

class MutableClock {
  DateTime now;

  MutableClock(this.now);

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

class PomodoroFixture {
  final HydrionLocalStore store;
  final MutableClock clock;
  final ChallengeRepository challenges;
  final HydrationRepository hydration;
  final ReminderRepository reminders;
  final FakeHydrionNotificationAdapter adapter;
  final PomodoroSessionService sessions;

  PomodoroFixture._({
    required this.store,
    required this.clock,
    required this.challenges,
    required this.hydration,
    required this.reminders,
    required this.adapter,
    required this.sessions,
  });

  static Future<PomodoroFixture> create({
    HydrionLocalStore? store,
    int sessionsPerDay = 1,
    int sessionMinutes = 25,
    FakeHydrionNotificationAdapter? adapter,
  }) async {
    final actualStore = store ?? MemoryHydrionStore();
    final clock = MutableClock(DateTime(2030, 7, 23, 9, 17, 42));
    final challenges = await ChallengeRepository.load(actualStore);
    final hydration = await HydrationRepository.load(actualStore);
    final reminders = await ReminderRepository.load(actualStore);
    final actualAdapter = adapter ??
        FakeHydrionNotificationAdapter(
          permission: HydrionNotificationPermissionState.granted,
        );
    final notifications = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: reminders,
      adapter: actualAdapter,
      now: () => clock.now,
    );
    final sessions = PomodoroSessionService(
      challengeRepository: challenges,
      notificationService: notifications,
      now: () => clock.now,
    );
    await challenges.join(
      id: PomodoroSessionService.challengeId,
      name: 'Pomodoro Sip',
      description: 'Focus and hydrate deliberately.',
      targetMl: 2200,
      durationDays: 3,
      joinedAt: clock.now,
      parameters: {
        'sessionMinutes': sessionMinutes,
        'sessionsPerDay': sessionsPerDay,
        'amountMl': 150,
        'shortBreakMinutes': 5,
        'notifications': 'enabled',
        'autoStartNext': 'disabled',
        'challengeDurationDays': 3,
        'timerStatus': 'stopped',
      },
    );
    return PomodoroFixture._(
      store: actualStore,
      clock: clock,
      challenges: challenges,
      hydration: hydration,
      reminders: reminders,
      adapter: actualAdapter,
      sessions: sessions,
    );
  }

  static Future<PomodoroFixture> restore({
    required HydrionLocalStore store,
    required MutableClock clock,
  }) async {
    final challenges = await ChallengeRepository.load(store);
    final hydration = await HydrationRepository.load(store);
    final reminders = await ReminderRepository.load(store);
    final adapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.granted,
    );
    final notifications = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: reminders,
      adapter: adapter,
      now: () => clock.now,
    );
    return PomodoroFixture._(
      store: store,
      clock: clock,
      challenges: challenges,
      hydration: hydration,
      reminders: reminders,
      adapter: adapter,
      sessions: PomodoroSessionService(
        challengeRepository: challenges,
        notificationService: notifications,
        now: () => clock.now,
      ),
    );
  }
}

class FailingHydrionStore implements HydrionLocalStore {
  final MemoryHydrionStore _delegate = MemoryHydrionStore();
  bool failWrites = false;

  @override
  Future<String?> readString(String key) => _delegate.readString(key);

  @override
  Future<void> remove(String key) {
    if (failWrites) throw StateError('persist failed');
    return _delegate.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) {
    if (failWrites) throw StateError('persist failed');
    return _delegate.writeString(key, value);
  }
}
