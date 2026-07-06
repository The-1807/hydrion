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
  final String title;
  final String message;
  final String environment;

  const HydrionCompanionState({
    required this.mood,
    required this.title,
    required this.message,
    required this.environment,
  });
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
        title: 'Goal reached',
        message: 'Goal reached. Great work listening to your routine.',
        environment: 'celebration current',
      );
    }
    if (settings.weatherAdjustedGoalActive) {
      return HydrionCompanionState(
        mood: HydrionCompanionMood.hotWeather,
        title: 'Weather-aware day',
        message: settings.lastWeatherGoalExplanation ??
            'Warm conditions nudged today\'s goal. Keep it comfortable.',
        environment: 'sunlit tide',
      );
    }
    if (hasActiveChallenge && percent >= 50) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.challenge,
        title: 'Challenge current',
        message: 'Nice. That moved today and your challenge forward.',
        environment: 'badge reef',
      );
    }
    if (reminderDue) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.reminder,
        title: 'Gentle nudge',
        message: 'A small check-in now keeps the day from bunching up later.',
        environment: 'soft ripple',
      );
    }
    if (entryCount == 0 && now.hour >= 15) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.recovery,
        title: 'Fresh start',
        message: 'Good to see you. We can start fresh with one easy log.',
        environment: 'calm harbor',
      );
    }
    if (percent >= 80) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.nearlyComplete,
        title: 'Almost there',
        message: 'Nearly complete. Keep the finish gentle.',
        environment: 'bright current',
      );
    }
    if (percent >= 45) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.onTrack,
        title: 'On track',
        message: 'Halfway energy. Your routine has shape now.',
        environment: 'steady current',
      );
    }
    if (percent > 0) {
      return const HydrionCompanionState(
        mood: HydrionCompanionMood.behindPace,
        title: 'Building momentum',
        message: 'Nice start. A small top-up keeps the morning moving.',
        environment: 'quiet tide',
      );
    }
    return const HydrionCompanionState(
      mood: HydrionCompanionMood.morning,
      title: 'Morning check-in',
      message: 'Let\'s make the first sip easy.',
      environment: 'morning lagoon',
    );
  }
}
