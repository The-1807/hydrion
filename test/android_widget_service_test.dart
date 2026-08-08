import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/android_widget_service.dart';

void main() {
  JoinedChallenge activityChallenge({
    Set<String> completedActionIds = const {},
    Map<String, Object?> parameters = const {
      'windowStartHour': 12,
      'reminderEnabled': 'enabled',
    },
  }) {
    final joinedAt = DateTime(2026, 7, 30, 8);
    return JoinedChallenge(
      id: 'lunch-break-refill',
      name: 'Lunch Break Refill',
      description: 'Check a bottle during a lunch window.',
      targetMl: 2200,
      durationDays: 7,
      joinedAt: joinedAt,
      storedInstanceId: 'lunch-instance',
      parameters: parameters,
      completedActionIds: completedActionIds,
    );
  }

  test('empty widget snapshot offers a privacy-safe challenge entry point', () {
    expect(AndroidWidgetService.snapshotData(null), {
      'active_challenge_id': '',
      'active_challenge_title': 'No active challenge',
      'active_challenge_status': 'Open Hydrion to choose a challenge.',
      'active_challenge_progress': 0,
      'active_challenge_action': 'Open challenges',
    });
  });

  test('active challenge snapshot reports deliberate checkpoint progress', () {
    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final data = AndroidWidgetService.snapshotData(
      activityChallenge(
        completedActionIds: {'lunch-instance:$day:activity:bottle-check'},
      ),
    );

    expect(data['active_challenge_title'], 'Lunch Break Refill');
    expect(data['active_challenge_progress'], 100);
    expect(data['active_challenge_status'], "Today's activity complete");
    expect(data['active_challenge_action'], 'Open challenge');
  });

  test('widget snapshot exposes no health, profile, or eligibility data', () {
    final data = AndroidWidgetService.snapshotData(activityChallenge());

    expect(
      data.keys,
      isNot(
        containsAll(<String>[
          'age',
          'sex',
          'pregnancy',
          'bmi',
          'clinician_target',
          'fluid_restriction',
          'eligibility',
          'today_ml',
          'goal_ml',
        ]),
      ),
    );
    expect(data.keys, contains('active_challenge_id'));
  });

  test('daily and quick-log widgets use the canonical hydration snapshot', () {
    const settings = UserSettings(
      locale: Locale('en'),
      dailyGoalMl: 2000,
      containerSizeMl: 300,
      reusableContainerEnabled: true,
    );
    final data = AndroidWidgetService.hydrationSnapshotData(
      todayMl: 750,
      settings: settings,
    );

    expect(data['today_ml'], 750);
    expect(data['goal_ml'], 2000);
    expect(data['progress_percent'], 38);
    expect(data['quick_add_ml'], 300);
    expect(data['status'], '1250 mL left');
  });

  test('Android manifest registers three separate widget providers', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('.HydrionDailyProgressWidget'));
    expect(manifest, contains('.HydrionQuickLogWidget'));
    expect(manifest, contains('.HydrionActiveChallengeWidget'));
    expect(RegExp('android.appwidget.provider').allMatches(manifest),
        hasLength(3));
  });
}
