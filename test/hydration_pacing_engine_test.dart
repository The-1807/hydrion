import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_pacing.dart';
import 'package:hydrion/services/hydration_pacing_engine.dart';

void main() {
  const engine = HydrationPacingEngine();

  group('missing or invalid schedule', () {
    test(
      'both null reports unavailable and does not block progress fraction',
      () {
        final status = engine.calculate(
          wakeMinuteOfDay: null,
          sleepMinuteOfDay: null,
          todayLoggedMl: 500,
          dailyGoalMl: 2000,
          now: DateTime(2026, 1, 1, 10),
        );
        expect(status.state, HydrationPacingState.unavailable);
        expect(status.windowElapsedFraction, isNull);
        expect(status.minutesRemainingInWindow, isNull);
        expect(status.progressFraction, closeTo(0.25, 1e-9));
      },
    );

    test('equal wake and sleep minute is treated as unavailable', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 420,
        sleepMinuteOfDay: 420,
        todayLoggedMl: 0,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(status.state, HydrationPacingState.unavailable);
    });

    test('one side missing is treated as unavailable', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 420,
        sleepMinuteOfDay: null,
        todayLoggedMl: 0,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(status.state, HydrationPacingState.unavailable);
    });

    test(
      'does not prevent hydration tracking: progress fraction is always computed',
      () {
        final unavailable = engine.calculate(
          wakeMinuteOfDay: null,
          sleepMinuteOfDay: null,
          todayLoggedMl: 1000,
          dailyGoalMl: 2000,
          now: DateTime(2026, 1, 1, 10),
        );
        expect(unavailable.progressFraction, closeTo(0.5, 1e-9));
      },
    );
  });

  group('ordinary daytime schedule (wake 07:00, sleep 23:00)', () {
    test('start of waking period is 0% elapsed', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 0,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 7, 0),
      );
      expect(status.windowElapsedFraction, closeTo(0.0, 1e-9));
      expect(status.state, HydrationPacingState.onPace);
    });

    test('midpoint on pace', () {
      // 07:00 -> 23:00 is a 16h window; midpoint is 15:00.
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 1000,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 15, 0),
      );
      expect(status.windowElapsedFraction, closeTo(0.5, 1e-9));
      expect(status.progressFraction, closeTo(0.5, 1e-9));
      expect(status.state, HydrationPacingState.onPace);
    });

    test('near sleep, well behind pace', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 200,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 22, 30),
      );
      expect(status.state, HydrationPacingState.meaningfullyBehindPace);
    });

    test('ahead of pace early in the day', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 900,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 8, 0),
      );
      expect(status.state, HydrationPacingState.aheadOfPace);
    });

    test('slightly behind pace', () {
      // 25% through the window, ~10% of goal logged -> ~15pt behind.
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 200,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 11, 0),
      );
      expect(status.state, HydrationPacingState.slightlyBehindPace);
    });

    test('sleeping period reports outsideWakingWindow', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 500,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 2, 0),
      );
      expect(status.state, HydrationPacingState.outsideWakingWindow);
      expect(status.windowElapsedFraction, isNull);
    });

    test(
      'goal already reached reports goalReached even early in the window',
      () {
        final status = engine.calculate(
          wakeMinuteOfDay: 7 * 60,
          sleepMinuteOfDay: 23 * 60,
          todayLoggedMl: 2200,
          dailyGoalMl: 2000,
          now: DateTime(2026, 1, 1, 9, 0),
        );
        expect(status.state, HydrationPacingState.goalReached);
      },
    );
  });

  group('overnight / shift-work schedule (wake 14:00, sleep 06:00)', () {
    test('does not assume wake < sleep: window length is 16 hours', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 14 * 60,
        sleepMinuteOfDay: 6 * 60,
        todayLoggedMl: 0,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 14, 0),
      );
      expect(status.windowElapsedFraction, closeTo(0.0, 1e-9));
    });

    test('mid-shift (20:00) is within the waking window at 37.5%', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 14 * 60,
        sleepMinuteOfDay: 6 * 60,
        todayLoggedMl: 750,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 20, 0),
      );
      expect(status.windowElapsedFraction, closeTo(0.375, 1e-9));
      expect(status.state, HydrationPacingState.onPace);
    });

    test('after midnight (02:00) is still within the waking window', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 14 * 60,
        sleepMinuteOfDay: 6 * 60,
        todayLoggedMl: 1000,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 2, 2, 0),
      );
      // 12h elapsed of a 16h window.
      expect(status.windowElapsedFraction, closeTo(0.75, 1e-9));
    });

    test(
      'mid-morning (10:00) after an overnight shift is outsideWakingWindow',
      () {
        final status = engine.calculate(
          wakeMinuteOfDay: 14 * 60,
          sleepMinuteOfDay: 6 * 60,
          todayLoggedMl: 500,
          dailyGoalMl: 2000,
          now: DateTime(2026, 1, 2, 10, 0),
        );
        expect(status.state, HydrationPacingState.outsideWakingWindow);
      },
    );
  });

  group('safety invariants', () {
    test(
      'pacing never influences dailyGoalMl: engine has no goal-mutation surface',
      () {
        // The engine signature only returns a HydrationPacingStatus, which has
        // no goal/baseline field at all — this is a structural guarantee, not
        // just a behavioral one. Exercise a wide sweep of schedules/logs and
        // confirm the goal passed in is never echoed back as anything other
        // than the fraction it was used to compute.
        for (final wake in [0, 300, 700, 1200, 1439]) {
          for (final sleep in [0, 400, 800, 1300, 1439]) {
            if (wake == sleep) continue;
            final status = engine.calculate(
              wakeMinuteOfDay: wake,
              sleepMinuteOfDay: sleep,
              todayLoggedMl: 1500,
              dailyGoalMl: 3000,
              now: DateTime(2026, 1, 1, 12),
            );
            expect(status.progressFraction, closeTo(0.5, 1e-9));
          }
        }
      },
    );

    test(
      'respects a clinician-directed goal passed in as dailyGoalMl (goal '
      'itself is computed upstream by PersonalizedHydrationEngine, not here)',
      () {
        // A clinician target of 1200ml with 1100ml logged should read as
        // nearly-on-pace/ahead depending on time of day, never as "behind" due
        // to some independent higher baseline being substituted.
        final status = engine.calculate(
          wakeMinuteOfDay: 7 * 60,
          sleepMinuteOfDay: 23 * 60,
          todayLoggedMl: 1100,
          dailyGoalMl: 1200,
          now: DateTime(2026, 1, 1, 12, 0),
        );
        expect(status.progressFraction, closeTo(1100 / 1200, 1e-9));
      },
    );

    test('never reports negative expected/actual progress', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 0,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 7, 0),
      );
      expect(status.windowElapsedFraction! >= 0, isTrue);
      expect(status.progressFraction >= 0, isTrue);
    });

    test('does not report expected intake above 100% of the window', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 500,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 22, 59),
      );
      expect(status.windowElapsedFraction! <= 1.0, isTrue);
    });

    test(
        'the waking window is a half-open interval: the sleep minute itself '
        'is outside the window, not 100% elapsed', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 500,
        dailyGoalMl: 2000,
        now: DateTime(2026, 1, 1, 23, 0),
      );
      expect(status.state, HydrationPacingState.outsideWakingWindow);
    });

    test('zero or negative goal does not throw and reports zero progress', () {
      final status = engine.calculate(
        wakeMinuteOfDay: 7 * 60,
        sleepMinuteOfDay: 23 * 60,
        todayLoggedMl: 500,
        dailyGoalMl: 0,
        now: DateTime(2026, 1, 1, 12, 0),
      );
      expect(status.progressFraction, 0.0);
    });
  });
}
