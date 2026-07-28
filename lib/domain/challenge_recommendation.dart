enum ChallengeRecommendationReason {
  hotWeather,
  outdoorRoutine,
  indoorFocus,
  inconsistentLogging,
  variedHabits,
  balancedFoodInterest,
  visualConsistency,
  alreadyActive,
  activeLimitReached,
  dismissedToday,
  notEligible,
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
