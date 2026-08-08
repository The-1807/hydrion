import '../repositories/settings_repository.dart';

enum HydrionCompanionMood {
  morning,
  behindPace,
  onTrack,
  nearlyComplete,
  goalComplete,
  streak,
  recovery,
  hotWeather,
  reminder,
  challenge,
}

class HydrionCompanionState {
  final HydrionCompanionMood mood;

  const HydrionCompanionState({required this.mood});
}

class HydrionCompanionDirector {
  const HydrionCompanionDirector();

  HydrionCompanionState select({
    required double hydrationPercent,
    required int entryCount,
    required UserSettings settings,
    required DateTime now,
    bool hasActiveChallenge = false,
    bool reminderDue = false,
  }) {
    final percent = hydrationPercent.clamp(0.0, 100.0);
    if (percent >= 100) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.goalComplete,
      );
    }
    if (settings.weatherAdjustedGoalActive) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.hotWeather,
      );
    }
    if (hasActiveChallenge && percent >= 50) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.challenge,
      );
    }
    if (reminderDue) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.reminder,
      );
    }
    if (entryCount == 0 && now.hour >= 15) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.recovery,
      );
    }
    if (percent >= 80) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.nearlyComplete,
      );
    }
    if (percent >= 45) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.onTrack,
      );
    }
    if (percent > 0) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.behindPace,
      );
    }
    return const HydrionCompanionState(
      mood: HydrionCompanionMood.morning,
    );
  }
}
