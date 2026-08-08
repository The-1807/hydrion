import 'app_localizations.dart';
import 'challenge_localizations.dart';
import '../services/weather_goal_service.dart';

extension HydrionWeatherLocalizations on AppLocalizations {
  String weatherUserMessage(WeatherUserMessageCode code) =>
      challengeText(switch (code) {
        WeatherUserMessageCode.profileIncomplete =>
          'Complete age and sex in Profile before enabling weather-informed goals.',
        WeatherUserMessageCode.manualGoalChangedToday =>
          'Manual goal was edited today, so Hydrion will not replace it silently.',
        WeatherUserMessageCode.locationBlocked =>
          'Location access is blocked. Enable it in device settings.',
        WeatherUserMessageCode.locationPermissionRequired =>
          'Allow location access to use local weather assistance.',
        WeatherUserMessageCode.locationServicesDisabled =>
          'Turn on device location services to use weather assistance.',
        WeatherUserMessageCode.locationTimeout =>
          'Location lookup took too long. Check your signal and try again.',
        WeatherUserMessageCode.locationUnavailable =>
          'Your location is unavailable right now. Try again later.',
        WeatherUserMessageCode.weatherTimeout =>
          'Weather lookup took too long. Try again shortly.',
        WeatherUserMessageCode.weatherOffline =>
          'Weather is unavailable while the device is offline.',
        WeatherUserMessageCode.weatherBusy =>
          'The weather service is busy right now. Try again shortly.',
        WeatherUserMessageCode.weatherUnavailableInBuild =>
          'Weather assistance is unavailable in this build.',
        WeatherUserMessageCode.weatherUnavailable =>
          'Local weather is unavailable right now. Try again later.',
      });

  String weatherCondition(String condition) => switch (condition) {
        'Clear' => weatherClear,
        'Cloudy' => weatherCloudy,
        'Fog' => weatherFog,
        'Rain' => weatherRain,
        'Snow' => weatherSnow,
        'Storm' => weatherStorm,
        'Mixed' => weatherMixed,
        'Unknown' => weatherUnknown,
        _ => condition,
      };
}
