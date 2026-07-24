import '../services/weather_goal_service.dart';

enum TemperatureAssignmentSource {
  standardRotation,
  weatherRecommendation,
  weatherMatchedStandard,
  weatherUnavailableFallback,
  weatherDisabled,
}

class TemperatureRoulettePlan {
  final List<String> schedule;
  final TemperatureAssignmentSource source;
  final String explanation;

  const TemperatureRoulettePlan({
    required this.schedule,
    required this.source,
    required this.explanation,
  });
}

class TemperatureRoulettePlanner {
  const TemperatureRoulettePlanner._();

  static TemperatureRoulettePlan plan({
    required List<String> standardSchedule,
    required bool weatherEnabled,
    WeatherSnapshot? forecast,
  }) {
    final standard = List<String>.of(standardSchedule);
    if (!weatherEnabled) {
      return TemperatureRoulettePlan(
        schedule: standard,
        source: TemperatureAssignmentSource.weatherDisabled,
        explanation:
            'Weather guidance is off. Today’s standard rotation is active.',
      );
    }
    if (forecast == null) {
      return TemperatureRoulettePlan(
        schedule: standard,
        source: TemperatureAssignmentSource.weatherUnavailableFallback,
        explanation:
            'Weather is unavailable, so today’s standard rotation is active.',
      );
    }

    final recommendation = forecast.temperatureC >= 24
        ? 'Cool'
        : forecast.temperatureC <= 10
            ? 'Comfortably warm'
            : 'Room temperature';
    final reordered = <String>[
      recommendation,
      ...standard.where((style) => style != recommendation),
    ];
    while (reordered.length < standard.length) {
      reordered.add(standard[reordered.length % standard.length]);
    }
    final matched = standard.first == recommendation;
    return TemperatureRoulettePlan(
      schedule: reordered.take(standard.length).toList(),
      source: matched
          ? TemperatureAssignmentSource.weatherMatchedStandard
          : TemperatureAssignmentSource.weatherRecommendation,
      explanation: matched
          ? 'Weather also recommends $recommendation today; the standard assignment already matched.'
          : 'Weather recommends $recommendation today, replacing the standard ${standard.first} assignment.',
    );
  }
}
