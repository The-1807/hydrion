import '../repositories/settings_repository.dart';

abstract class WeatherProvider {
  Future<WeatherSnapshot> currentForecast();
}

class WeatherSnapshot {
  final double temperatureC;
  final double humidityPercent;
  final double uvIndex;
  final DateTime observedAt;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.humidityPercent,
    required this.uvIndex,
    required this.observedAt,
  });
}

class WeatherGoalInputs {
  final int baselineGoalMl;
  final int? age;
  final HydrionSex? sex;
  final WeatherSnapshot weather;
  final int userAdjustmentMl;
  final bool locationPermissionGranted;
  final bool notificationPermissionGranted;

  const WeatherGoalInputs({
    required this.baselineGoalMl,
    required this.age,
    required this.sex,
    required this.weather,
    this.userAdjustmentMl = 0,
    this.locationPermissionGranted = false,
    this.notificationPermissionGranted = false,
  });
}

class WeatherGoalDecision {
  final int baselineGoalMl;
  final int weatherAdjustmentMl;
  final int userAdjustmentMl;
  final int recommendedGoalMl;
  final String explanation;
  final bool eligible;

  const WeatherGoalDecision({
    required this.baselineGoalMl,
    required this.weatherAdjustmentMl,
    required this.userAdjustmentMl,
    required this.recommendedGoalMl,
    required this.explanation,
    required this.eligible,
  });
}

class DeterministicWeatherGoalService {
  static const maxWeatherAdjustmentMl = 600;
  static const minUserAdjustmentMl = -500;
  static const maxUserAdjustmentMl = 500;

  const DeterministicWeatherGoalService();

  WeatherGoalDecision recommend(WeatherGoalInputs inputs) {
    final baseline = inputs.baselineGoalMl.clamp(
      UserSettings.minDailyGoalMl,
      UserSettings.maxDailyGoalMl,
    );
    if (!_eligible(inputs)) {
      return WeatherGoalDecision(
        baselineGoalMl: baseline,
        weatherAdjustmentMl: 0,
        userAdjustmentMl: 0,
        recommendedGoalMl: baseline,
        explanation:
            'Manual goal kept because weather-informed goals require age, an explicit sex option, location permission, notification permission, and a forecast provider.',
        eligible: false,
      );
    }

    final temperatureAdjustment = switch (inputs.weather.temperatureC) {
      >= 35 => 450,
      >= 30 => 300,
      >= 26 => 150,
      <= 0 => -100,
      _ => 0,
    };
    final humidityAdjustment = inputs.weather.humidityPercent >= 70 ? 100 : 0;
    final uvAdjustment = inputs.weather.uvIndex >= 8 ? 100 : 0;
    final weatherAdjustment =
        (temperatureAdjustment + humidityAdjustment + uvAdjustment)
            .clamp(-100, maxWeatherAdjustmentMl);
    final userAdjustment = inputs.userAdjustmentMl.clamp(
      minUserAdjustmentMl,
      maxUserAdjustmentMl,
    );
    final recommended = (baseline + weatherAdjustment + userAdjustment).clamp(
      UserSettings.minDailyGoalMl,
      UserSettings.maxDailyGoalMl,
    );

    return WeatherGoalDecision(
      baselineGoalMl: baseline,
      weatherAdjustmentMl: weatherAdjustment,
      userAdjustmentMl: userAdjustment,
      recommendedGoalMl: _roundToNearest50(recommended),
      explanation:
          'Baseline $baseline ml plus bounded weather adjustment $weatherAdjustment ml and user adjustment $userAdjustment ml.',
      eligible: true,
    );
  }

  bool shouldAskForDailyDecision({
    required DateTime now,
    required DateTime? lastDecisionAt,
  }) {
    if (lastDecisionAt == null) {
      return true;
    }
    return now.difference(lastDecisionAt) >= const Duration(hours: 24) ||
        !_sameLocalDay(now, lastDecisionAt);
  }

  bool _eligible(WeatherGoalInputs inputs) {
    return inputs.age != null &&
        inputs.sex != null &&
        inputs.sex != HydrionSex.preferNotToSay &&
        inputs.locationPermissionGranted &&
        inputs.notificationPermissionGranted;
  }

  int _roundToNearest50(int value) {
    return (value / 50).round() * 50;
  }

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
