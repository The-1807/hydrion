import '../domain/daily_hydration_context.dart';
import '../domain/hydration_recommendation.dart';
import '../repositories/body_metrics_repository.dart';
import '../repositories/daily_hydration_context_repository.dart';
import '../repositories/personalization_state_repository.dart';
import '../repositories/settings_repository.dart';
import 'personalized_hydration_engine.dart';
import 'weather_goal_service.dart';

class DailyHydrationRecommendationCoordinator {
  final UserSettingsRepository settingsRepository;
  final BodyMetricsRepository bodyMetricsRepository;
  final DailyHydrationContextRepository dailyContextRepository;
  final PersonalizationStateRepository stateRepository;
  final PersonalizedHydrationEngine engine;

  const DailyHydrationRecommendationCoordinator({
    required this.settingsRepository,
    required this.bodyMetricsRepository,
    required this.dailyContextRepository,
    required this.stateRepository,
    this.engine = const PersonalizedHydrationEngine(),
  });

  Future<HydrationRecommendation> calculate({
    required DateTime now,
    WeatherSnapshot? weather,
    bool locationPermissionGranted = false,
    bool cachedWeatherUsed = false,
  }) async {
    final settings = settingsRepository.settings;
    final dateKey = hydrionLocalDateKey(now);
    final metrics = bodyMetricsRepository.metrics.sanitized(
      femaleProfile: settings.sex == HydrionSex.female,
    );
    final context = dailyContextRepository.forDate(dateKey);
    final fingerprint = [
      dateKey,
      settings.baselineDailyGoalMl,
      settings.baselineSource.name,
      settings.weatherModifierEnabled,
      settings.age,
      settings.sex?.name,
      metrics.toJson(),
      context?.toJson(),
      weather?.toJson(),
      locationPermissionGranted,
      cachedWeatherUsed,
    ].join('|');
    final recommendation = engine.calculate(
      PersonalizedHydrationInputs(
        existingBaselineGoalMl: settings.baselineDailyGoalMl,
        requestedBaselineSource:
            settings.baselineSource == HydrionBaselineSource.personalized
                ? HydrationBaselineSource.personalized
                : HydrationBaselineSource.manual,
        age: settings.age,
        sex: settings.sex,
        bodyMetrics: metrics,
        dailyContext: context,
        weather: weather,
        weatherEnabled: settings.weatherModifierEnabled,
        locationPermissionGranted: locationPermissionGranted,
        cachedWeatherUsed: cachedWeatherUsed,
        localDateKey: dateKey,
        calculatedAt: now,
      ),
    );
    await stateRepository.recordRecommendation(
      inputFingerprint: fingerprint,
      recommendation: recommendation,
    );
    return recommendation;
  }

  Future<bool> apply(
    HydrationRecommendation recommendation, {
    required DateTime now,
  }) {
    return settingsRepository.setDailyGoalMl(
      recommendation.roundedRecommendedGoalMl,
      updateBaseline: false,
      markManualEdit: false,
      now: now,
    );
  }

  Future<bool> applyPersonalizedBaseline(
    HydrationRecommendation recommendation, {
    required DateTime now,
  }) async {
    await settingsRepository.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.personalized,
      weatherModifierEnabled:
          settingsRepository.settings.weatherModifierEnabled,
    );
    return settingsRepository.setDailyGoalMl(
      recommendation.baselineGoalMl,
      updateBaseline: true,
      markManualEdit: false,
      now: now,
    );
  }

  Future<void> keepCurrentGoal({required DateTime now}) async {
    await stateRepository.markRecommendationReviewed(
      localDateKey: hydrionLocalDateKey(now),
    );
  }

  Future<bool> restoreBaseline({required DateTime now}) {
    return settingsRepository.setDailyGoalMl(
      settingsRepository.settings.baselineDailyGoalMl,
      updateBaseline: false,
      markManualEdit: false,
      now: now,
    );
  }
}
