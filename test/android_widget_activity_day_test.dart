import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/services/android_widget_service.dart';

// D7: the widget must key challenge checkpoints by the repository's activity
// day, not by the calendar day, or an overnight shift shows 0 of N after
// midnight.
void main() {
  Future<ChallengeRepository> overnightShift() async {
    final repository = ChallengeRepository.memory();
    final joined = await repository.join(
      id: 'shift-hydration-check',
      name: 'Shift Hydration Check',
      description: 'An overnight shift.',
      targetMl: 2200,
      durationDays: 7,
      joinedAt: DateTime(2026, 7, 30, 8),
      profileAge: 30,
      parameters: const {
        'shiftStartMinutes': 22 * 60,
        'shiftDurationMinutes': 600,
      },
    );
    expect(joined, isTrue);
    return repository;
  }

  test('widget shows overnight shift checkpoints after midnight', () async {
    final repository = await overnightShift();
    expect(
      await repository.completeActivityCheckpoint(
        challengeId: 'shift-hydration-check',
        checkpointId: 'shift-start',
        completedAt: DateTime(2026, 7, 30, 22, 30),
      ),
      isTrue,
    );
    expect(
      await repository.completeActivityCheckpoint(
        challengeId: 'shift-hydration-check',
        checkpointId: 'shift-midpoint',
        completedAt: DateTime(2026, 7, 31, 2),
      ),
      isTrue,
    );
    final afterMidnight = DateTime(2026, 7, 31, 2, 5);
    expect(
      repository.activityCheckpointComplete(
        'shift-hydration-check',
        'shift-midpoint',
        day: afterMidnight,
      ),
      isTrue,
    );

    final data = AndroidWidgetService.snapshotData(
      repository.activeChallengeFor('shift-hydration-check'),
      now: afterMidnight,
    );

    expect(data['active_challenge_progress'], 67);
    expect(data['active_challenge_status'], '2 of 3 checkpoints today');
  });

  test('widget and repository agree on the activity day token', () async {
    final repository = await overnightShift();
    final challenge = repository.activeChallengeFor('shift-hydration-check')!;
    expect(
      ChallengeRepository.activityDayToken(challenge, DateTime(2026, 7, 31, 2)),
      '2026-07-30',
    );
    expect(
      ChallengeRepository.activityDayToken(
          challenge, DateTime(2026, 7, 31, 22)),
      '2026-07-31',
    );
    expect(
      ChallengeRepository.activityDayToken(
          challenge, DateTime(2026, 8, 1, 0, 10)),
      '2026-07-31',
    );
    // Month and year boundaries keep the stored yyyy-MM-dd format.
    expect(
      ChallengeRepository.activityDayToken(challenge, DateTime(2027, 1, 1, 1)),
      '2026-12-31',
    );
  });

  test('widget snapshot has no private copy of the day policy', () {
    final source =
        File('lib/services/android_widget_service.dart').readAsStringSync();
    expect(source, contains('ChallengeRepository.activityDayToken('));
    expect(source, isNot(contains("padLeft(2, '0')")));
  });
}
