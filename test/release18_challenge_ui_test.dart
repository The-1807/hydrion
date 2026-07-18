import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';

void main() {
  Future<HydrionServices> pumpActiveChallenge(
    WidgetTester tester,
    String challengeId,
  ) async {
    final services = HydrionServices.memory(
      guidedTourRepository:
          GuidedTourRepository.memory(contextualToursCompleted: false),
    );
    final challenge = HydrionChallengeCatalog.byId(challengeId);
    final parameters = switch (challengeId) {
      'bottle-bingo' => <String, Object?>{
          'cutoffHour': 12,
          'difficulty': 'steady',
          'reminderPreference': 'morning',
          'amountMl': 250,
          'bingoBoardVersion': 2,
        },
      'pomodoro-sip' => <String, Object?>{
          'sessionMinutes': 25,
          'sessionsPerDay': 1,
          'amountMl': 150,
          'shortBreakMinutes': 5,
          'notifications': 'disabled',
          'autoStartNext': 'disabled',
          'challengeDurationDays': 3,
          'timerStatus': 'stopped',
        },
      'temperature-roulette' => <String, Object?>{
          'amountMl': 250,
          'weatherOrdering': 'disabled',
          'temperatureSchedule': const [
            'Cool',
            'Room temperature',
            'Comfortably warm',
            'Cool',
            'Room temperature',
          ],
        },
      _ => <String, Object?>{
          'amountMl': 250,
          'noAddedSugar': 'confirmed',
        },
    };
    await services.challengeRepository.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      parameters: parameters,
    );
    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(
          find.byKey(const Key('hydrion-bottom-nav')),
        )
        .onDestinationSelected
        ?.call(1);
    await tester.pumpAndSettle();
    final card = find.byKey(Key('challenge-card-$challengeId'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    return services;
  }

  for (final entry in const {
    'bottle-bingo': 'Open a tile',
    'pomodoro-sip': 'Start a focus session',
    'temperature-roulette': "Today's temperature",
    'around-the-world-infusion-week': "Today's infusion",
  }.entries) {
    testWidgets('${entry.key} shows its first contextual tutorial once',
        (tester) async {
      final services = await pumpActiveChallenge(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget);
      await tester.tap(find.byKey(const Key('tour-skip')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsNothing);
      expect(
        services.guidedTourRepository.isContextualTourComplete(
          '${entry.key}:release18-v1',
        ),
        isTrue,
      );
    });
  }

  testWidgets('paused challenge renders resume state and releases active slot',
      (tester) async {
    final services = await pumpActiveChallenge(tester, 'pomodoro-sip');
    await tester.tap(find.byKey(const Key('tour-skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('challenge-overflow-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('challenge-confirm-pause')));
    await tester.pumpAndSettle();

    expect(find.text('Challenge paused'), findsOneWidget);
    expect(find.byKey(const Key('challenge-resume')), findsOneWidget);
    expect(services.challengeRepository.activeChallenges, isEmpty);
    expect(services.challengeRepository.pausedChallenges, hasLength(1));
  });
}
