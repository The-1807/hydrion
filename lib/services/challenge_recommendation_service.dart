import '../domain/body_metrics.dart';
import '../domain/challenge_catalog.dart';
import '../domain/challenge_recommendation.dart';
import '../domain/daily_hydration_context.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';
import 'weather_goal_service.dart';

class ChallengeRecommendationInputs {
  final DateTime now;
  final String localDateKey;
  final UserSettings settings;
  final HydrionBodyMetrics bodyMetrics;
  final DailyHydrationContext? dailyContext;
  final WeatherSnapshot? weather;
  final List<JoinedChallenge> activeChallenges;
  final int hydrationLogCountLastSevenDays;
  final Set<String> dismissedChallengeIds;
  final ChallengeRecommendationPreferences preferences;

  const ChallengeRecommendationInputs({
    required this.now,
    required this.localDateKey,
    required this.settings,
    required this.bodyMetrics,
    required this.dailyContext,
    required this.weather,
    required this.activeChallenges,
    required this.hydrationLogCountLastSevenDays,
    required this.dismissedChallengeIds,
    this.preferences = const ChallengeRecommendationPreferences(),
  });
}

class ChallengeRecommendationService {
  const ChallengeRecommendationService();

  List<ChallengeRecommendation> rank(ChallengeRecommendationInputs inputs) {
    final activeIds = inputs.activeChallenges.map((item) => item.id).toSet();
    final limitReached = inputs.activeChallenges.length >=
        ChallengeRepository.maxActiveChallenges;
    final effectiveTemperature =
        inputs.weather?.apparentTemperatureC ?? inputs.weather?.temperatureC;
    final results = <ChallengeRecommendation>[];

    for (final challenge in HydrionChallengeCatalog.challenges) {
      if (activeIds.contains(challenge.id)) {
        results.add(_skipped(
          challenge.id,
          inputs,
          ChallengeRecommendationReason.alreadyActive,
        ));
        continue;
      }
      if (limitReached) {
        results.add(_skipped(
          challenge.id,
          inputs,
          ChallengeRecommendationReason.activeLimitReached,
        ));
        continue;
      }
      if (inputs.dismissedChallengeIds.contains(challenge.id)) {
        results.add(_skipped(
          challenge.id,
          inputs,
          ChallengeRecommendationReason.dismissedToday,
        ));
        continue;
      }

      var score = 0;
      final reasons = <ChallengeRecommendationReason>[];
      switch (challenge.id) {
        case 'temperature-roulette':
          if (effectiveTemperature != null && effectiveTemperature >= 26) {
            score += 50;
            reasons.add(ChallengeRecommendationReason.hotWeather);
          }
          if (inputs.dailyContext?.environment ==
              HydrionEnvironmentExposure.mostlyOutdoors) {
            score += 30;
            reasons.add(ChallengeRecommendationReason.outdoorRoutine);
          }
        case 'pomodoro-sip':
          if (inputs.dailyContext?.environment ==
              HydrionEnvironmentExposure.mostlyIndoors) {
            score += 35;
            reasons.add(ChallengeRecommendationReason.indoorFocus);
          }
          if (inputs.preferences.prefersTimedRoutines) {
            score += 35;
            reasons.add(ChallengeRecommendationReason.indoorFocus);
          }
        case 'bottle-bingo':
          if (inputs.hydrationLogCountLastSevenDays < 7) {
            score += 45;
            reasons.add(ChallengeRecommendationReason.inconsistentLogging);
            score += 10;
            reasons.add(ChallengeRecommendationReason.variedHabits);
          }
        case 'eat-your-water-day':
          if (inputs.preferences.balancedHydrationInterest) {
            score += 35;
            reasons.add(ChallengeRecommendationReason.balancedFoodInterest);
            final bmi = inputs.bodyMetrics.adultBmi;
            if ((inputs.settings.age ?? -1) >= 20 &&
                inputs.bodyMetrics.personalizationEnabled &&
                bmi != null &&
                bmi.isFinite &&
                bmi >= 25) {
              score += 10;
              reasons.add(
                ChallengeRecommendationReason.adultBmiSecondarySignal,
              );
            }
          }
        case 'plant-twin-challenge':
          if (inputs.preferences.visualConsistencyInterest) {
            score += 35;
            reasons.add(ChallengeRecommendationReason.visualConsistency);
          }
        case 'around-the-world-infusion-week':
          if (inputs.preferences.infusionVarietyInterest) {
            score += 35;
            reasons.add(ChallengeRecommendationReason.infusionVariety);
          }
      }
      results.add(ChallengeRecommendation(
        challengeId: challenge.id,
        score: score,
        reasons: List.unmodifiable(reasons),
        explanationKey: 'challengeRecommendation.${challenge.id}',
        recommendedAt: inputs.now,
        localDateKey: inputs.localDateKey,
        eligible: score > 0,
        skippedReason:
            score > 0 ? null : ChallengeRecommendationReason.notEligible,
      ));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(results);
  }

  ChallengeRecommendation _skipped(
    String id,
    ChallengeRecommendationInputs inputs,
    ChallengeRecommendationReason reason,
  ) {
    return ChallengeRecommendation(
      challengeId: id,
      score: 0,
      reasons: const [],
      explanationKey: 'challengeRecommendation.$id',
      recommendedAt: inputs.now,
      localDateKey: inputs.localDateKey,
      eligible: false,
      skippedReason: reason,
    );
  }

  int recentHydrationLogCount(
    HydrationRepository repository, {
    required DateTime now,
  }) {
    return repository.fetch(now.subtract(const Duration(days: 7)), now).length;
  }
}
