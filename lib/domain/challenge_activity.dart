enum ChallengeActivitySessionMode { none, timed, checkpointRoutine }

class ChallengeActivityCheckpoint {
  final String id;
  final String title;
  final String description;

  const ChallengeActivityCheckpoint({
    required this.id,
    required this.title,
    required this.description,
  });
}

class ChallengeActivityDefinition {
  final String challengeId;
  final List<String> requiredParameters;
  final List<ChallengeActivityCheckpoint> checkpoints;
  final ChallengeActivitySessionMode sessionMode;
  final String setupSummary;
  final String safetyMessage;

  const ChallengeActivityDefinition({
    required this.challengeId,
    required this.requiredParameters,
    required this.checkpoints,
    required this.setupSummary,
    this.sessionMode = ChallengeActivitySessionMode.none,
    this.safetyMessage = '',
  });
}

class HydrionChallengeActivities {
  static const definitions = <String, ChallengeActivityDefinition>{
    'lunch-break-refill': ChallengeActivityDefinition(
      challengeId: 'lunch-break-refill',
      requiredParameters: ['windowStartHour', 'reminderEnabled'],
      setupSummary: 'A flexible lunch-window bottle check.',
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'bottle-check',
          title: 'Check your bottle',
          description:
              'Confirm that you checked it. Refill only when that is useful.',
        ),
      ],
    ),
    'homework-hydration': ChallengeActivityDefinition(
      challengeId: 'homework-hydration',
      requiredParameters: ['sessionMinutes', 'checkpointPattern'],
      setupSummary: 'A private study session with deliberate checkpoints.',
      sessionMode: ChallengeActivitySessionMode.timed,
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'hydration-check',
          title: 'Hydration check',
          description:
              'Review your hydration when the checkpoint is available.',
        ),
        ChallengeActivityCheckpoint(
          id: 'session-finished',
          title: 'Finish the session',
          description:
              'Deliberately finish after reviewing the session checkpoint.',
        ),
      ],
    ),
    'after-school-recharge': ChallengeActivityDefinition(
      challengeId: 'after-school-recharge',
      requiredParameters: ['windowStartHour'],
      setupSummary: 'A neutral afternoon recharge window.',
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'progress-reviewed',
          title: 'Review current progress',
          description: 'Look at today’s hydration progress without pressure.',
        ),
        ChallengeActivityCheckpoint(
          id: 'water-prepared',
          title: 'Prepare water',
          description: 'Prepare water if it is useful for the rest of the day.',
        ),
        ChallengeActivityCheckpoint(
          id: 'routine-finished',
          title: 'Finish recharge routine',
          description: 'Confirm the short routine is complete.',
        ),
      ],
    ),
    'backpack-bottle-check': ChallengeActivityDefinition(
      challengeId: 'backpack-bottle-check',
      requiredParameters: ['preparationHour'],
      setupSummary: 'A private reusable-bottle preparation cue.',
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'bottle-status',
          title: 'Record bottle status',
          description: 'Choose ready, packed, or needs attention.',
        ),
      ],
    ),
    'desk-day-reset': ChallengeActivityDefinition(
      challengeId: 'desk-day-reset',
      requiredParameters: ['blockMinutes', 'resetFrequencyMinutes'],
      setupSummary: 'A flexible seated-work reset routine.',
      sessionMode: ChallengeActivitySessionMode.checkpointRoutine,
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'movement-reset',
          title: 'Movement or posture reset',
          description: 'Complete one comfortable reset away from the screen.',
        ),
        ChallengeActivityCheckpoint(
          id: 'bottle-check',
          title: 'Bottle check',
          description:
              'Review your bottle without automatically logging water.',
        ),
      ],
    ),
    'shift-hydration-check': ChallengeActivityDefinition(
      challengeId: 'shift-hydration-check',
      requiredParameters: ['shiftStartMinutes', 'shiftDurationMinutes'],
      setupSummary: 'Start, midpoint, and end checks for a flexible shift.',
      sessionMode: ChallengeActivitySessionMode.checkpointRoutine,
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'shift-start',
          title: 'Start check',
          description: 'Review the plan at the beginning of the shift.',
        ),
        ChallengeActivityCheckpoint(
          id: 'shift-midpoint',
          title: 'Midpoint check',
          description: 'Review progress once the midpoint is reached.',
        ),
        ChallengeActivityCheckpoint(
          id: 'shift-end',
          title: 'End-of-shift review',
          description: 'Finish with a calm review of the completed shift.',
        ),
      ],
    ),
    'commute-cup': ChallengeActivityDefinition(
      challengeId: 'commute-cup',
      requiredParameters: ['preparationHour', 'travelStartHour'],
      setupSummary: 'A preparation check that happens before travel.',
      safetyMessage:
          'Prepare before you go. Do not read, tap, or log while driving.',
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'prepared-before-travel',
          title: 'Cup or bottle prepared',
          description: 'Confirm preparation before the travel period begins.',
        ),
      ],
    ),
    'evening-goal-review': ChallengeActivityDefinition(
      challengeId: 'evening-goal-review',
      requiredParameters: ['reviewHour'],
      setupSummary: 'A calm evening review of today’s applied goal.',
      safetyMessage:
          'Review without pressure. Do not rapidly catch up late at night.',
      checkpoints: [
        ChallengeActivityCheckpoint(
          id: 'progress-reviewed',
          title: 'Review today',
          description: 'Review current progress and the applied daily goal.',
        ),
        ChallengeActivityCheckpoint(
          id: 'review-finished',
          title: 'Finish review',
          description: 'Confirm the review without adding a hydration log.',
        ),
      ],
    ),
  };

  static ChallengeActivityDefinition? forId(String challengeId) =>
      definitions[challengeId];

  static bool get isEmpty => definitions.isEmpty;
}
