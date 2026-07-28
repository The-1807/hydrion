import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/domain/challenge_recommendation.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/challenge_recommendation_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';

void main() {
  const service = ChallengeRecommendationService();
  final now = DateTime(2026, 7, 28, 12);

  ChallengeRecommendationInputs inputs({
    List<JoinedChallenge> active = const [],
    DailyHydrationContext? context,
    WeatherSnapshot? weather,
    int logs = 14,
    Set<String> dismissed = const {},
    bool timed = false,
    bool balanced = false,
    bool visual = false,
    bool infusion = false,
    int age = 30,
    HydrionBodyMetrics metrics = const HydrionBodyMetrics(),
  }) =>
      ChallengeRecommendationInputs(
        now: now,
        localDateKey: '2026-07-28',
        settings: UserSettings(
          locale: UserSettings.fallbackLocale,
          age: age,
          sex: HydrionSex.female,
        ),
        bodyMetrics: metrics,
        dailyContext: context,
        weather: weather,
        activeChallenges: active,
        hydrationLogCountLastSevenDays: logs,
        dismissedChallengeIds: dismissed,
        preferences: ChallengeRecommendationPreferences(
          prefersTimedRoutines: timed,
          balancedHydrationInterest: balanced,
          visualConsistencyInterest: visual,
          infusionVarietyInterest: infusion,
        ),
      );

  test('hot outdoor weather ranks Temperature Roulette', () {
    final ranked = service.rank(inputs(
      context: DailyHydrationContext(
        localDateKey: '2026-07-28',
        environment: HydrionEnvironmentExposure.mostlyOutdoors,
        updatedAt: now,
      ),
      weather: WeatherSnapshot(
        temperatureC: 30,
        apparentTemperatureC: 35,
        uvIndex: 8,
        observedAt: now,
      ),
    ));
    expect(ranked.first.challengeId, 'temperature-roulette');
    expect(ranked.first.eligible, isTrue);
  });

  test('indoor focus ranks Pomodoro and inconsistent logs rank Bingo', () {
    final indoor = service.rank(inputs(
      timed: true,
      context: DailyHydrationContext(
        localDateKey: '2026-07-28',
        environment: HydrionEnvironmentExposure.mostlyIndoors,
        updatedAt: now,
      ),
    ));
    expect(indoor.first.challengeId, 'pomodoro-sip');

    final inconsistent = service.rank(inputs(logs: 2));
    expect(inconsistent.first.challengeId, 'bottle-bingo');
  });

  test('recommendation is read-only and never activates a challenge', () {
    final repository = ChallengeRepository.memory();
    service.rank(inputs(logs: 0));
    expect(repository.activeChallenges, isEmpty);
    expect(repository.challengeHistory, isEmpty);
  });

  test('active limit, existing challenge, and dismissal are respected',
      () async {
    final repository = ChallengeRepository.memory();
    await repository.join(
      id: 'temperature-roulette',
      name: 'Temperature Roulette',
      description: 'Description',
      targetMl: 2200,
      durationDays: 5,
      joinedAt: now,
    );
    await repository.join(
      id: 'pomodoro-sip',
      name: 'Pomodoro Sip',
      description: 'Description',
      targetMl: 2200,
      durationDays: 5,
      joinedAt: now.add(const Duration(seconds: 1)),
    );
    final ranked = service.rank(inputs(active: repository.activeChallenges));
    expect(ranked.every((item) => !item.eligible), isTrue);

    final dismissed =
        service.rank(inputs(dismissed: const {'bottle-bingo'}, logs: 0));
    expect(
      dismissed
          .firstWhere((item) => item.challengeId == 'bottle-bingo')
          .eligible,
      isFalse,
    );
  });

  test('BMI is a weak adult secondary signal and never sole eligibility', () {
    final adult = service.rank(inputs(
      age: 30,
      metrics: const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 120,
        heightCm: 160,
      ),
    ));
    final food =
        adult.firstWhere((item) => item.challengeId == 'eat-your-water-day');
    expect(food.eligible, isFalse);

    final underTwenty = service.rank(inputs(
      age: 19,
      balanced: true,
      metrics: const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 160,
      ),
    ));
    final underTwentyFood = underTwenty
        .firstWhere((item) => item.challengeId == 'eat-your-water-day');
    expect(underTwentyFood.eligible, isTrue);
    expect(
      underTwentyFood.reasons,
      isNot(contains(ChallengeRecommendationReason.adultBmiSecondarySignal)),
    );

    final adultInterested = service.rank(inputs(
      age: 30,
      balanced: true,
      metrics: const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 65,
        heightCm: 160,
      ),
    ));
    final adultFood = adultInterested
        .firstWhere((item) => item.challengeId == 'eat-your-water-day');
    expect(adultFood.score, 45);
    expect(
      adultFood.reasons,
      contains(ChallengeRecommendationReason.adultBmiSecondarySignal),
    );
  });

  test('meaningful signals are required for every recommendation', () {
    final noSignals = service.rank(inputs(logs: 14));
    expect(noSignals.where((item) => item.eligible), isEmpty);
    expect(
      service
          .rank(inputs(infusion: true))
          .firstWhere(
              (item) => item.challengeId == 'around-the-world-infusion-week')
          .eligible,
      isTrue,
    );
    expect(
      service
          .rank(inputs(visual: true))
          .firstWhere((item) => item.challengeId == 'plant-twin-challenge')
          .eligible,
      isTrue,
    );
  });
}
