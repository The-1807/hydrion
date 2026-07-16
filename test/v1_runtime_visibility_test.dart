import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('deferred coaching has no V1 route navigation or Home surface', () {
    final main = source('lib/main.dart');
    final shell = source('lib/ui/screens/hydrion_shell.dart');
    final home = source('lib/ui/screens/home_screen.dart');
    expect(main, isNot(contains("'/chat':")));
    expect(shell, isNot(contains("label: 'Coach'")));
    expect(shell, isNot(contains("Key('nav-coach')")));
    expect(home, isNot(contains('          _HydrionLifestyleRail(')));
    expect(home, isNot(contains("route: '/chat'")));
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
