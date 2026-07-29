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
    HydrationChallenge(
      id: 'lunch-break-refill',
      name: 'Lunch Break Refill',
      description:
          'Use a lunch break as a private reminder to check and refill your bottle when needed.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Teen routine',
      dailyTask: 'Confirm one lunch-break bottle check.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'homework-hydration',
      name: 'Homework Hydration',
      description:
          'Pair a comfortable drink check with a study break without tracking a school or assignment.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Teen routine',
      dailyTask: 'Confirm one study-break hydration check.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'after-school-recharge',
      name: 'After-School Recharge',
      description:
          'Pause after your daytime routine to review hydration and choose a comfortable next step.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Teen routine',
      dailyTask: 'Complete one after-routine check-in.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'backpack-bottle-check',
      name: 'Backpack Bottle Check',
      description:
          'Use a private packing cue to check that a reusable bottle is ready for the next day.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Teen routine',
      dailyTask: 'Confirm the bottle-ready check.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'desk-day-reset',
      name: 'Desk-Day Reset',
      description:
          'Use an optional seated-work break to review hydration without changing your normal goal.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Adult routine',
      dailyTask: 'Confirm one seated-work hydration review.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'shift-hydration-check',
      name: 'Shift Hydration Check',
      description:
          'For days with a defined work period, add a private midpoint hydration check.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Adult routine',
      dailyTask: 'Confirm one work-period hydration check.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'commute-cup',
      name: 'Commute Cup',
      description:
          'When you travel, use departure or arrival as an optional cue to review your drink plan.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Adult routine',
      dailyTask: 'Confirm one travel-cue hydration review.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
    HydrationChallenge(
      id: 'evening-goal-review',
      name: 'Evening Goal Review',
      description:
          'Review your day without pressure and decide whether your existing plan still feels appropriate.',
      targetMl: 2200,
      durationDays: 5,
      category: 'Adult routine',
      dailyTask: 'Complete one evening goal review.',
      objectiveType: ChallengeObjectiveType.manualCheckIn,
    ),
  ];

  static HydrationChallenge byId(String id) {
    return challenges.firstWhere(
      (challenge) => challenge.id == id,
      orElse: () => challenges.first,
    );
  }
}
