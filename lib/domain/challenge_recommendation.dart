enum ChallengeRecommendationReason {
  hotWeather,
  outdoorRoutine,
  indoorFocus,
  inconsistentLogging,
  variedHabits,
  balancedFoodInterest,
  adultBmiSecondarySignal,
  visualConsistency,
  infusionVariety,
  alreadyActive,
  activeLimitReached,
  dismissedToday,
  notEligible,
}

class ChallengeRecommendationPreferences {
  final bool prefersTimedRoutines;
  final bool balancedHydrationInterest;
  final bool visualConsistencyInterest;
  final bool infusionVarietyInterest;
  final DateTime? updatedAt;

  const ChallengeRecommendationPreferences({
    this.prefersTimedRoutines = false,
    this.balancedHydrationInterest = false,
    this.visualConsistencyInterest = false,
    this.infusionVarietyInterest = false,
    this.updatedAt,
  });

  factory ChallengeRecommendationPreferences.fromJson(Object? value) {
    if (value is! Map) return const ChallengeRecommendationPreferences();
    bool flag(String key) => value[key] is bool ? value[key] as bool : false;
    return ChallengeRecommendationPreferences(
      prefersTimedRoutines: flag('prefersTimedRoutines'),
      balancedHydrationInterest: flag('balancedHydrationInterest'),
      visualConsistencyInterest: flag('visualConsistencyInterest'),
      infusionVarietyInterest: flag('infusionVarietyInterest'),
      updatedAt: DateTime.tryParse((value['updatedAt'] ?? '').toString()),
    );
  }

  Map<String, Object?> toJson() => {
        'prefersTimedRoutines': prefersTimedRoutines,
        'balancedHydrationInterest': balancedHydrationInterest,
        'visualConsistencyInterest': visualConsistencyInterest,
        'infusionVarietyInterest': infusionVarietyInterest,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  ChallengeRecommendationPreferences copyWith({
    bool? prefersTimedRoutines,
    bool? balancedHydrationInterest,
    bool? visualConsistencyInterest,
    bool? infusionVarietyInterest,
    DateTime? updatedAt,
  }) =>
      ChallengeRecommendationPreferences(
        prefersTimedRoutines: prefersTimedRoutines ?? this.prefersTimedRoutines,
        balancedHydrationInterest:
            balancedHydrationInterest ?? this.balancedHydrationInterest,
        visualConsistencyInterest:
            visualConsistencyInterest ?? this.visualConsistencyInterest,
        infusionVarietyInterest:
            infusionVarietyInterest ?? this.infusionVarietyInterest,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ChallengeRecommendation {
  final String challengeId;
  final int score;
  final List<ChallengeRecommendationReason> reasons;
  final String explanationKey;
  final DateTime recommendedAt;
  final String localDateKey;
  final bool eligible;
  final ChallengeRecommendationReason? skippedReason;

  const ChallengeRecommendation({
    required this.challengeId,
    required this.score,
    required this.reasons,
    required this.explanationKey,
    required this.recommendedAt,
    required this.localDateKey,
    required this.eligible,
    this.skippedReason,
  });
}
