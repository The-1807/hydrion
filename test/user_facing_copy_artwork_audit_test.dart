import 'dart:convert';
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

  test('manifest covers every challenge with a unique exact PNG path', () {
    final manifest = jsonDecode(
      File('assets/images/challenges/artwork_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = (manifest['artwork'] as List).cast<Map<String, dynamic>>();
    final ids = entries.map((entry) => entry['challenge_id']).toSet();
    final paths = entries.map((entry) => entry['path']).toList();
    expect(entries, hasLength(8));
    expect(
      ids,
      containsAll({
        'lunch-break-refill',
        'homework-hydration',
        'after-school-recharge',
        'backpack-bottle-check',
        'desk-day-reset',
        'shift-hydration-check',
        'commute-cup',
        'evening-goal-review',
      }),
    );
    expect(paths.toSet(), hasLength(paths.length));
    for (final path in paths.cast<String>()) {
      expect(
        path,
        matches(
          RegExp(r'^assets/images/challenges/[a-z0-9_]+\.png$'),
        ),
      );
    }
    final registryPaths =
        ChallengeVisualRegistry.identities.values.map((item) => item.assetPath);
    expect(registryPaths.toSet(), hasLength(14));
    for (final identity in ChallengeVisualRegistry.identities.values) {
      if (!ids.contains(identity.challengeId)) {
        expect(File(identity.assetPath).existsSync(), isTrue);
      }
    }
  });

  testWidgets('missing custom artwork renders a unique deliberate fallback',
      (tester) async {
    final identity = ChallengeVisualRegistry.forId('commute-cup');
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 150,
          child: ChallengeArtwork(identity: identity),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('challenge-art-fallback-commute-cup')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.directions_transit_outlined), findsOneWidget);
  });
}
