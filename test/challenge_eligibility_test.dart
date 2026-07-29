import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/challenge_eligibility.dart';
import 'package:hydrion/repositories/challenge_repository.dart';

void main() {
  group('HydrionChallengeEligibilityPolicy', () {
    test('keeps universal challenges available for teen and adult profiles',
        () {
      for (final age in [13, 17, 18, 20]) {
        expect(
          HydrionChallengeEligibilityPolicy.evaluate(
            challengeId: 'bottle-bingo',
            age: age,
          ).eligible,
          isTrue,
        );
      }
    });

    test('separates teen and adult extras at age 18', () {
      expect(
        HydrionChallengeEligibilityPolicy.evaluate(
          challengeId: 'homework-hydration',
          age: 17,
        ).eligible,
        isTrue,
      );
      expect(
        HydrionChallengeEligibilityPolicy.evaluate(
          challengeId: 'homework-hydration',
          age: 18,
        ).eligible,
        isFalse,
      );
      expect(
        HydrionChallengeEligibilityPolicy.evaluate(
          challengeId: 'evening-goal-review',
          age: 17,
        ).eligible,
        isFalse,
      );
      expect(
        HydrionChallengeEligibilityPolicy.evaluate(
          challengeId: 'evening-goal-review',
          age: 18,
        ).eligible,
        isTrue,
      );
    });

    test('blocks all challenges for unsupported or corrupt profiles', () {
      for (final age in [12, -1, 121]) {
        expect(
          HydrionChallengeEligibilityPolicy.evaluate(
            challengeId: 'bottle-bingo',
            age: age,
          ).eligible,
          isFalse,
        );
      }
    });
  });

  test('repository rejects a direct ineligible join', () async {
    final repository = ChallengeRepository.memory();
    final challenge = HydrionChallengeCatalog.byId('desk-day-reset');

    final joined = await repository.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: challenge.targetMl,
      durationDays: challenge.durationDays,
      profileAge: 17,
    );

    expect(joined, isFalse);
    expect(repository.activeChallenges, isEmpty);
  });

  test('repository preserves the two-active-challenge limit', () async {
    final repository = ChallengeRepository.memory();
    for (final id in ['bottle-bingo', 'pomodoro-sip']) {
      final challenge = HydrionChallengeCatalog.byId(id);
      expect(
        await repository.join(
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          targetMl: challenge.targetMl,
          durationDays: challenge.durationDays,
          profileAge: 18,
        ),
        isTrue,
      );
    }
    final third = HydrionChallengeCatalog.byId('desk-day-reset');
    expect(
      await repository.join(
        id: third.id,
        name: third.name,
        description: third.description,
        targetMl: third.targetMl,
        durationDays: third.durationDays,
        profileAge: 18,
      ),
      isFalse,
    );
  });
}
