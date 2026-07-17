enum ChallengeActionKind { hydration, checkIn, automaticQualification }

class ChallengeExperienceDefinition {
  final String id;
  final String purpose;
  final List<String> actions;
  final String whatCounts;
  final String whatDoesNotCount;
  final List<String> requiredParameters;
  final List<String> schedule;
  final ChallengeActionKind actionKind;
  final bool weatherAware;

  const ChallengeExperienceDefinition({
    required this.id,
    required this.purpose,
    required this.actions,
    required this.whatCounts,
    required this.whatDoesNotCount,
    required this.requiredParameters,
    required this.actionKind,
    this.schedule = const [],
    this.weatherAware = false,
  });
}

class HydrionChallengeExperiences {
  static const definitions = <ChallengeExperienceDefinition>[
    ChallengeExperienceDefinition(
      id: 'around-the-world-infusion-week',
      purpose:
          'Try seven no-added-sugar infusion themes while maintaining your normal hydration goal.',
      actions: [
        'Review today’s infusion theme.',
        'Confirm no added sugar.',
        'Log the amount of infused water actually consumed.'
      ],
      whatCounts:
          'A canonical hydration log created for today’s assigned infusion theme.',
      whatDoesNotCount:
          'Plain water supports the daily goal but does not complete the infusion task.',
      requiredParameters: ['amountMl', 'noAddedSugar'],
      actionKind: ChallengeActionKind.hydration,
      schedule: [
        'Citrus',
        'Berry',
        'Tropical fruit',
        'Herb',
        'Fruit and herb',
        'Cucumber or fresh produce',
        'Your no-sugar infusion'
      ],
    ),
    ChallengeExperienceDefinition(
      id: 'temperature-roulette',
      purpose:
          'Compare comfortable water temperatures as a preference experiment.',
      actions: [
        'Review today’s assigned temperature style.',
        'Use the configured amount.',
        'Log the water after drinking it.'
      ],
      whatCounts:
          'A canonical hydration log tagged with today’s assigned temperature style.',
      whatDoesNotCount:
          'Water at another style still counts toward daily hydration but not this task.',
      requiredParameters: ['amountMl', 'weatherOrdering'],
      actionKind: ChallengeActionKind.hydration,
      weatherAware: true,
      schedule: [
        'Cool',
        'Room temperature',
        'Comfortably warm',
        'Cool',
        'Room temperature'
      ],
    ),
    ChallengeExperienceDefinition(
      id: 'eat-your-water-day',
      purpose:
          'Include one selected water-rich food in a meal without inventing hydration volume.',
      actions: [
        'Choose a meal.',
        'Choose or enter a water-rich food.',
        'Confirm the food task after the meal.'
      ],
      whatCounts: 'One local food-task check-in on the selected day.',
      whatDoesNotCount: 'The food check-in never creates a hydration record.',
      requiredParameters: ['meal', 'food'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'pomodoro-sip',
      purpose:
          'Pair modest hydration check-ins with manually confirmed focus-session breaks.',
      actions: [
        'Complete a configured focus session.',
        'Confirm the session ended.',
        'Log the configured sip amount.'
      ],
      whatCounts:
          'A persisted sip hydration action after a confirmed focus session.',
      whatDoesNotCount:
          'The timer never adds water until the planned sip is confirmed.',
      requiredParameters: [
        'sessionMinutes',
        'sessionsPerDay',
        'amountMl',
        'shortBreakMinutes',
        'notifications',
        'autoStartNext',
        'challengeDurationDays'
      ],
      actionKind: ChallengeActionKind.hydration,
    ),
    ChallengeExperienceDefinition(
      id: 'bottle-bingo',
      purpose:
          'Complete a weekly mix of explicit hydration actions and non-hydration check-ins.',
      actions: [
        'Open a tile to review its rule.',
        'Complete the stated action.',
        'Hydration tiles log once; check-ins add no water.'
      ],
      whatCounts:
          'Tile-specific canonical hydration evidence or an explicit local check-in.',
      whatDoesNotCount:
          'Unknown amounts and non-hydration tasks never create water.',
      requiredParameters: [
        'cutoffHour',
        'difficulty',
        'reminderPreference',
        'amountMl'
      ],
      actionKind: ChallengeActionKind.automaticQualification,
    ),
    ChallengeExperienceDefinition(
      id: 'plant-twin-challenge',
      purpose:
          'Use one plant-care cue as a reminder to review your hydration routine.',
      actions: [
        'Complete the plant-care cue.',
        'Confirm the cue locally.',
        'Log any water you actually drink separately.'
      ],
      whatCounts: 'One explicit local plant-cue check-in.',
      whatDoesNotCount: 'Plant care does not create a hydration record.',
      requiredParameters: ['cue'],
      actionKind: ChallengeActionKind.checkIn,
    ),
  ];

  static ChallengeExperienceDefinition? findById(String id) {
    for (final definition in definitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  static ChallengeExperienceDefinition byId(String id) => findById(id)!;
}
