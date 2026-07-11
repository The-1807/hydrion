import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Coach is a non-interactive future-update notice', () {
    final coach = source('lib/ui/screens/chat_coach_screen.dart');
    expect(coach, contains("key: const Key('coach-coming-soon')"));
    expect(coach, contains('Hydrion Coach is being prepared'));
    expect(coach, isNot(contains('TextField(')));
    expect(coach, isNot(contains('coach-message-input')));
    expect(coach.toLowerCase(), isNot(contains('provider')));
    expect(coach.toLowerCase(), isNot(contains('runtime')));
  });

  test('V1 surfaces do not mount deferred feature cards', () {
    final home = source('lib/ui/screens/home_screen.dart');
    final settings = source('lib/ui/screens/settings_screen.dart');
    expect(home, isNot(contains('_WeatherJourneyPanel(settings: settings)')));
    expect(home, isNot(contains("label: 'Connected devices'")));
    expect(settings,
        isNot(contains('_WeatherGoalSettingsCard(settings: settings)')));
    expect(settings, isNot(contains('_ComingSoonFeaturesCard(')));
    expect(settings, isNot(contains('const _DebugDiagnosticsCard(),')));
  });

  test('Profile does not explain missing accounts or expose age/sex fields',
      () {
    final profile = source('lib/ui/screens/profile_screen.dart');
    expect(profile, isNot(contains('no sign-out action')));
    expect(profile, isNot(contains("labelText: 'Age'")));
    expect(profile, isNot(contains("labelText: 'Sex'")));
  });
}
