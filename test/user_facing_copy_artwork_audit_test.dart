import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_visual_registry.dart';
import 'package:hydrion/ui/components/challenge_artwork.dart';

void main() {
  test('challenge UI source does not render internal audience categories', () {
    final sources = [
      File('lib/ui/screens/social_challenges_screen.dart').readAsStringSync(),
      File('lib/ui/screens/challenge_experience_screen.dart')
          .readAsStringSync(),
      File('lib/ui/presentation/challenge_history_presenter.dart')
          .readAsStringSync(),
    ].join('\n');
    for (final forbidden in [
      'challenge.category',
      'Teen routine',
      'Adult routine',
      'audience.name',
      'eligibility.name',
      'schemaVersion',
    ]) {
      expect(sources, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('every registered challenge artwork path exists and stays owned', () {
    final paths = <String>{};
    for (final identity in ChallengeVisualRegistry.identities.values) {
      for (final path in {
        identity.assetPath,
        identity.maleAsset,
        identity.femaleAsset,
        identity.intersexAsset,
      }.whereType<String>()) {
        expect(paths.add(path), isTrue, reason: path);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('profile-aware challenge artwork never defaults to male', () {
    final desk = ChallengeVisualRegistry.forId('desk-day-reset');
    expect(desk.assetFor('male'), endsWith('desk_day_reset_male.png'));
    expect(desk.assetFor('female'), endsWith('desk_day_reset_female.png'));
    expect(desk.assetFor('intersex'), endsWith('desk_day_reset_intersex.png'));
    expect(
      desk.assetFor('preferNotToSay'),
      endsWith('desk_day_reset_intersex.png'),
    );
  });

  testWidgets('missing custom artwork renders a unique deliberate fallback',
      (tester) async {
    const identity = ChallengeVisualIdentity(
      challengeId: 'missing-test-art',
      assetPath: 'assets/images/challenges/not_present.png',
      primary: Color(0xFF28756E),
      secondary: Color(0xFFE88C67),
      icon: Icons.directions_transit_outlined,
      imageAlignment: Alignment.center,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 200,
          height: 150,
          child: ChallengeArtwork(identity: identity),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('challenge-art-fallback-missing-test-art')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.directions_transit_outlined), findsOneWidget);
  });
}
