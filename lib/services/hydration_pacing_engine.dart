import '../domain/hydration_pacing.dart';

class HydrationPacingPolicy {
  static const minutesPerDay = 1440;
  static const aheadToleranceFraction = 0.10;
  static const onPaceToleranceFraction = 0.10;
  static const slightlyBehindToleranceFraction = 0.25;

  const HydrationPacingPolicy._();
}

/// Computes how logged hydration compares to the expected pace across a
/// user's configured waking window.
///
/// This engine is intentionally narrow: it never reads or writes
/// [dailyGoalMl]'s upstream inputs (baseline, weather, activity, clinician
/// target, fluid restriction). It receives the goal as an already-finalized
/// number and only ever produces an advisory state — it cannot change the
/// goal, log hydration, or schedule anything.
class HydrationPacingEngine {
  const HydrationPacingEngine();

  HydrationPacingStatus calculate({
    required int? wakeMinuteOfDay,
    required int? sleepMinuteOfDay,
    required int todayLoggedMl,
    required int dailyGoalMl,
    required DateTime now,
  }) {
    final progressFraction =
        dailyGoalMl > 0 ? todayLoggedMl / dailyGoalMl : 0.0;

    if (wakeMinuteOfDay == null ||
        sleepMinuteOfDay == null ||
        wakeMinuteOfDay == sleepMinuteOfDay ||
        wakeMinuteOfDay < 0 ||
        wakeMinuteOfDay >= HydrationPacingPolicy.minutesPerDay ||
        sleepMinuteOfDay < 0 ||
        sleepMinuteOfDay >= HydrationPacingPolicy.minutesPerDay) {
      return HydrationPacingStatus(
        state: HydrationPacingState.unavailable,
        windowElapsedFraction: null,
        progressFraction: progressFraction,
        minutesRemainingInWindow: null,
      );
    }

    final nowMinute = now.hour * 60 + now.minute;

    // Circular-day arithmetic: represent "minutes since wake" on a 1440-
    // minute ring so schedules that cross midnight (e.g. wake 14:00, sleep
    // 06:00 for a shift worker) need no special-case branching versus a
    // conventional same-day schedule (e.g. wake 07:00, sleep 23:00).
    final windowMinutes = (sleepMinuteOfDay -
            wakeMinuteOfDay +
            HydrationPacingPolicy.minutesPerDay) %
        HydrationPacingPolicy.minutesPerDay;
    final elapsedSinceWake =
        (nowMinute - wakeMinuteOfDay + HydrationPacingPolicy.minutesPerDay) %
            HydrationPacingPolicy.minutesPerDay;

    if (elapsedSinceWake >= windowMinutes) {
      return HydrationPacingStatus(
        state: HydrationPacingState.outsideWakingWindow,
        windowElapsedFraction: null,
        progressFraction: progressFraction,
        minutesRemainingInWindow: null,
      );
    }

    final windowElapsedFraction = (elapsedSinceWake / windowMinutes).clamp(
      0.0,
      1.0,
    );
    final minutesRemaining = windowMinutes - elapsedSinceWake;

    if (dailyGoalMl > 0 && todayLoggedMl >= dailyGoalMl) {
      return HydrationPacingStatus(
        state: HydrationPacingState.goalReached,
        windowElapsedFraction: windowElapsedFraction,
        progressFraction: progressFraction,
        minutesRemainingInWindow: minutesRemaining,
      );
    }

    final paceDelta = progressFraction - windowElapsedFraction;
    final state = switch (paceDelta) {
      final d when d >= HydrationPacingPolicy.aheadToleranceFraction =>
        HydrationPacingState.aheadOfPace,
      final d when d >= -HydrationPacingPolicy.onPaceToleranceFraction =>
        HydrationPacingState.onPace,
      final d
          when d >= -HydrationPacingPolicy.slightlyBehindToleranceFraction =>
        HydrationPacingState.slightlyBehindPace,
      _ => HydrationPacingState.meaningfullyBehindPace,
    };

    return HydrationPacingStatus(
      state: state,
      windowElapsedFraction: windowElapsedFraction,
      progressFraction: progressFraction,
      minutesRemainingInWindow: minutesRemaining,
    );
  }
}
