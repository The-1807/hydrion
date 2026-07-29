import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  testWidgets('existing unsupported profile is routed to review', (
    tester,
  ) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.setProfile(
      nickname: 'Existing profile',
      age: 12,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Review profile age'), findsOneWidget);
    expect(find.byKey(const Key('profile-age-correction')), findsOneWidget);
    expect(find.byKey(const Key('delete-unsupported-profile')), findsOneWidget);
    expect(find.byKey(const Key('home-logo')), findsNothing);
  });

  testWidgets('valid correction unlocks the existing local profile', (
    tester,
  ) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.setProfile(
      nickname: 'Existing profile',
      age: 12,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-age-correction')),
      '13',
    );
    await tester.tap(find.byKey(const Key('save-profile-age-correction')));
    await tester.pumpAndSettle();

    expect(services.settingsRepository.settings.age, 13);
    expect(find.byKey(const Key('home-logo')), findsOneWidget);
  });
}
