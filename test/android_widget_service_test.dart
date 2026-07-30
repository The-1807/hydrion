import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/android_widget_service.dart';

void main() {
  test('widget snapshot uses current progress and saved quick-add amount', () {
    final data = AndroidWidgetService.snapshotData(
      todayMl: 1100,
      settings: const UserSettings(
        locale: Locale('en'),
        dailyGoalMl: 2200,
        reusableContainerEnabled: true,
        containerSizeMl: 500,
      ),
    );

    expect(data, {
      'today_ml': 1100,
      'goal_ml': 2200,
      'progress_percent': 50,
      'quick_add_ml': 500,
      'status': 'Building momentum',
    });
  });

  test('widget snapshot contains no sensitive profile data', () {
    final data = AndroidWidgetService.snapshotData(
      todayMl: 2400,
      settings: const UserSettings(locale: Locale('fr'), dailyGoalMl: 2200),
    );

    expect(data['progress_percent'], 109);
    expect(data['quick_add_ml'], 250);
    expect(data['status'], 'Objectif atteint');
    expect(
      data.keys,
      isNot(containsAll(<String>[
        'bmi',
        'age',
        'sex',
        'pregnancy',
        'clinician_target',
        'fluid_restriction',
        'challenge_id',
      ])),
    );
  });
}
