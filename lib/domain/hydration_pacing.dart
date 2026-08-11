/// Hydration pacing describes how a user's logged intake compares to where
/// they should reasonably be at this point in their own waking day.
///
/// Pacing is purely observational. It never changes [dailyGoalMl] or any
/// baseline/clinician/fluid-restriction value computed elsewhere — it only
/// reads the already-finalized goal and today's logged total.
library;

enum HydrationPacingState {
  /// No valid wake/sleep schedule is configured.
  unavailable,

  /// The current time falls outside the configured waking window (either
  /// still asleep or already gone to sleep). Deliberately not split into
  /// separate "before wake" and "after sleep" states: on a circular clock
  /// there is no reliable anchor for "start of day" that works for both
  /// conventional and overnight/shift schedules, so both are represented
  /// identically as "not currently in your waking window".
  outsideWakingWindow,

  /// Today's goal has already been reached.
  goalReached,

  /// Logged intake is meaningfully ahead of the expected pace.
  aheadOfPace,

  /// Logged intake is close to the expected pace.
  onPace,

  /// Logged intake is somewhat behind the expected pace.
  slightlyBehindPace,

  /// Logged intake is well behind the expected pace.
  meaningfullyBehindPace,
}

class HydrationPacingStatus {
  final HydrationPacingState state;

  /// Fraction (0.0-1.0) of the waking window elapsed. Null when [state] is
  /// [HydrationPacingState.unavailable] or
  /// [HydrationPacingState.outsideWakingWindow].
  final double? windowElapsedFraction;

  /// Fraction (0.0-1.0+) of the daily goal logged so far.
  final double progressFraction;

  /// Minutes remaining in the current waking window. Null when [state] is
  /// [HydrationPacingState.unavailable] or
  /// [HydrationPacingState.outsideWakingWindow].
  final int? minutesRemainingInWindow;

  const HydrationPacingStatus({
    required this.state,
    required this.windowElapsedFraction,
    required this.progressFraction,
    required this.minutesRemainingInWindow,
  });

  bool get isActionable =>
      state != HydrationPacingState.unavailable &&
      state != HydrationPacingState.outsideWakingWindow;
}
