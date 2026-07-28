enum HydrationBaselineSource { manual, personalized }

enum HydrationRecommendationConfidence {
  fallback,
  manual,
  profileInformed,
  dailyContextInformed,
  weatherInformed,
  calibrated,
  clinicianSet,
}

enum HydrationFactorCode {
  manualBaseline,
  personalizedBaseline,
  missingBodyMetrics,
  underTwenty,
  reproductivePregnant,
  reproductiveLactating,
  reproductiveIneligible,
  activity,
  highSweat,
  weather,
  weatherUnavailable,
  weatherPermissionDenied,
  indoorWeatherSkipped,
  userAdjustment,
  clinicianTarget,
  fluidRestriction,
  illnessGuidance,
  finalClamp,
}

class HydrationRecommendation {
  final int baselineGoalMl;
  final HydrationBaselineSource baselineSource;
  final double? calculationWeightKg;
  final int bodyMetricsAdjustmentMl;
  final int reproductiveAdjustmentMl;
  final int activityAdjustmentMl;
  final int weatherAdjustmentMl;
  final int userAdjustmentMl;
  final int? clinicianTargetMl;
  final int finalRecommendedGoalMl;
  final int roundedRecommendedGoalMl;
  final HydrationRecommendationConfidence confidenceLevel;
  final String localDateKey;
  final DateTime calculatedAt;
  final List<HydrationFactorCode> appliedFactors;
  final List<HydrationFactorCode> skippedFactors;
  final List<HydrationFactorCode> safetyNotices;
  final bool mayAutoApply;
  final bool userConfirmationRequired;
  final bool weatherUsed;
  final bool cachedWeatherUsed;
  final bool clinicianTargetOverrodeFactors;

  const HydrationRecommendation({
    required this.baselineGoalMl,
    required this.baselineSource,
    required this.calculationWeightKg,
    required this.bodyMetricsAdjustmentMl,
    required this.reproductiveAdjustmentMl,
    required this.activityAdjustmentMl,
    required this.weatherAdjustmentMl,
    required this.userAdjustmentMl,
    required this.clinicianTargetMl,
    required this.finalRecommendedGoalMl,
    required this.roundedRecommendedGoalMl,
    required this.confidenceLevel,
    required this.localDateKey,
    required this.calculatedAt,
    required this.appliedFactors,
    required this.skippedFactors,
    required this.safetyNotices,
    required this.mayAutoApply,
    required this.userConfirmationRequired,
    required this.weatherUsed,
    required this.cachedWeatherUsed,
    required this.clinicianTargetOverrodeFactors,
  });
}
