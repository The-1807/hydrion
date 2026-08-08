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
        'Wait for the sip action to unlock.',
        'Confirm Took a sip or log the measured drink after drinking.'
      ],
      whatCounts:
          'One persisted drink with the configured amount after a completed focus session.',
      whatDoesNotCount:
          'Timer completion and reminders never add water automatically.',
      requiredParameters: [
        'sessionMinutes',
        'sessionsPerDay',
        'amountMl',
        'shortBreakMinutes',
        'notifications',
        'autoStartNext',
        'challengeDurationDays'
      ],
      actionKind: ChallengeActionKind.checkIn,
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
    ChallengeExperienceDefinition(
      id: 'lunch-break-refill',
      purpose: 'Build a private lunch-break bottle-check habit.',
      actions: ['Check the bottle.', 'Refill if useful.', 'Confirm the check.'],
      whatCounts: 'One explicit local bottle-check confirmation.',
      whatDoesNotCount: 'The check never logs water automatically.',
      requiredParameters: ['windowStartHour', 'reminderEnabled'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'homework-hydration',
      purpose: 'Pair one study break with a comfortable hydration review.',
      actions: [
        'Take a study break.',
        'Review hydration.',
        'Confirm the check.'
      ],
      whatCounts: 'One explicit local study-break confirmation.',
      whatDoesNotCount: 'No school, assignment, or drink amount is inferred.',
      requiredParameters: ['sessionMinutes', 'checkpointPattern'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'after-school-recharge',
      purpose: 'Review hydration after a daytime routine without pressure.',
      actions: [
        'Pause after the routine.',
        'Review the day.',
        'Confirm the check.'
      ],
      whatCounts: 'One explicit local after-routine confirmation.',
      whatDoesNotCount: 'The check never changes the daily goal.',
      requiredParameters: ['windowStartHour'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'backpack-bottle-check',
      purpose: 'Use a packing cue to prepare a reusable bottle.',
      actions: [
        'Check the bottle.',
        'Prepare it if useful.',
        'Confirm readiness.'
      ],
      whatCounts: 'One explicit local bottle-ready confirmation.',
      whatDoesNotCount: 'No location or school information is collected.',
      requiredParameters: ['preparationHour'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'desk-day-reset',
      purpose: 'Add a hydration review to an optional seated-work break.',
      actions: ['Take a break.', 'Review hydration.', 'Confirm the reset.'],
      whatCounts: 'One explicit local reset confirmation.',
      whatDoesNotCount: 'No drink is logged automatically.',
      requiredParameters: ['blockMinutes', 'resetFrequencyMinutes'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'shift-hydration-check',
      purpose: 'Add an optional midpoint check to a defined work period.',
      actions: [
        'Reach the midpoint.',
        'Review hydration.',
        'Confirm the check.'
      ],
      whatCounts: 'One explicit local work-period confirmation.',
      whatDoesNotCount: 'Hydrion does not infer employment or a schedule.',
      requiredParameters: ['shiftStartMinutes', 'shiftDurationMinutes'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'commute-cup',
      purpose: 'Use optional travel as a cue to review hydration.',
      actions: [
        'Choose departure or arrival.',
        'Review hydration.',
        'Confirm the cue.'
      ],
      whatCounts: 'One explicit local travel-cue confirmation.',
      whatDoesNotCount: 'No trip or location is tracked.',
      requiredParameters: ['preparationHour', 'travelStartHour'],
      actionKind: ChallengeActionKind.checkIn,
    ),
    ChallengeExperienceDefinition(
      id: 'evening-goal-review',
      purpose: 'End the day with a pressure-free review of the existing plan.',
      actions: [
        'Review the day.',
        'Keep or adjust the plan separately.',
        'Confirm review.'
      ],
      whatCounts: 'One explicit local evening review.',
      whatDoesNotCount: 'The review never changes the goal automatically.',
      requiredParameters: ['reviewHour'],
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
