import 'hydration_contracts.dart';

class HydrionChallengeCatalog {
  static const safetyNote =
      'Hydration needs vary. Stop or adjust a challenge if you feel unwell, and do not force fluids for progress, streaks, rewards, or beyond professional health guidance.';

  static const challenges = <HydrationChallenge>[
    HydrationChallenge(
      id: 'around-the-world-infusion-week',
      name: 'Around the World Infusion Week',
      description:
          'Try a different no-sugar fruit, herb, or citrus infusion theme each day while keeping your normal goal.',
      targetMl: 2200,
      durationDays: 7,
      category: 'Flavor variety',
      dailyTask: 'Log your usual hydration and note the day’s infusion.',
    ),
    HydrationChallenge(
      id: 'temperature-roulette',
      name: 'Temperature Roulette',
      description:
          'Rotate cool, room-temperature, and warm drinks to learn what feels easiest to sustain.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Preference discovery',
      dailyTask: 'Choose the listed temperature style and log normally.',
    ),
    HydrationChallenge(
      id: 'eat-your-water-day',
      name: 'Eat Your Water Day',
      description:
          'Add water-rich foods to one meal while keeping fluid intake comfortable and normal.',
      targetMl: 2200,
      durationDays: 1,
      category: 'Food support',
      dailyTask: 'Include a water-rich food and log drinks as usual.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'pomodoro-sip',
      name: 'Pomodoro Sip',
      description:
          'Pair a small drink check-in with focus breaks to build a gentle routine.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Routine',
      dailyTask: 'Take a modest sip break after focus sessions.',
    ),
    HydrationChallenge(
      id: 'plant-twin-challenge',
      name: 'Plant Twin Challenge',
      description:
          'Water a plant or check a reusable bottle station as a cue for your own comfortable sip.',
      targetMl: 2200,
      durationDays: 7,
      category: 'Cue building',
      dailyTask: 'Use the plant cue once and log your normal intake.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'bottle-bingo',
      name: 'Bottle Bingo',
      description:
          'Complete a local bingo-style mix of safe hydration habit prompts across the week.',
      targetMl: 2200,
      durationDays: 7,
      category: 'Variety',
      dailyTask: 'Logged water before lunch.',
      objectiveType: ChallengeObjectiveType.loggedWaterBeforeLunch,
    ),
  ];

  static HydrationChallenge byId(String id) {
    return challenges.firstWhere(
      (challenge) => challenge.id == id,
      orElse: () => challenges.first,
    );
  }
}
