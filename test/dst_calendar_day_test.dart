import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/ui/presentation/challenge_history_presenter.dart';
import 'package:hydrion/ui/screens/challenge_experience_screen.dart';
import 'package:hydrion/ui/screens/log_screen.dart';
import 'package:hydrion/ui/screens/reminders_screen.dart';

// D8: calendar-day questions must be answered in civil days, not by
// DateTime.difference().inDays or fixed 24-hour arithmetic on local values.
//
// The dates below straddle the America/New_York 2025 transitions (spring
// forward 9 March, fall back 2 November). With civil-day arithmetic every
// expectation holds in any host zone. The old instant arithmetic fails them
// when the host zone observes those transitions (run with
// TZ=America/New_York to reproduce); the source guard at the end fails on
// the old code in every zone.
void main() {
  group('D8 challenge schedule index', () {
    Future<ChallengeRepository> joined(String id, DateTime joinedAt) async {
      final challenges = ChallengeRepository.memory();
      await challenges.join(
        id: id,
        name: id,
        description: id,
        targetMl: 2200,
        durationDays: 7,
        joinedAt: joinedAt,
        parameters: const {
          'amountMl': 250,
          'weatherOrdering': 'disabled',
          'temperatureSchedule': ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
          'infusionThemeSchedule': ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        },
      );
      return challenges;
    }

    test('temperature schedule advances one entry per civil day across DST',
        () async {
      final spring =
          await joined('temperature-roulette', DateTime(2025, 3, 8, 7));
      expect(
          spring.temperatureForDay(
              'temperature-roulette', DateTime(2025, 3, 9, 12)),
          'B');
      expect(
          spring.temperatureForDay(
              'temperature-roulette', DateTime(2025, 3, 10, 12)),
          'C');
      expect(
          spring.temperatureForDay(
              'temperature-roulette', DateTime(2025, 3, 11, 0, 30)),
          'D');
      final fall =
          await joined('temperature-roulette', DateTime(2025, 11, 1, 7));
      expect(
          fall.temperatureForDay(
              'temperature-roulette', DateTime(2025, 11, 3, 12)),
          'C');
    });

    test('infusion theme schedule advances one entry per civil day across DST',
        () async {
      final spring = await joined(
          'around-the-world-infusion-week', DateTime(2025, 3, 8, 7));
      expect(
          spring.infusionThemeForDay(
              'around-the-world-infusion-week', DateTime(2025, 3, 10, 9)),
          'C');
      expect(
          spring.infusionThemeForDay(
              'around-the-world-infusion-week', DateTime(2025, 3, 7, 9)),
          isNull);
    });
  });

  group('D8 challenge history day index', () {
    test('history theme uses the civil day of the recorded action', () {
      final challenge = JoinedChallenge(
        id: 'around-the-world-infusion-week',
        name: 'Infusion',
        description: 'Infusion',
        targetMl: 2200,
        durationDays: 7,
        joinedAt: DateTime(2025, 3, 8, 9),
        completedActionIds: const {
          'around-the-world-infusion-week:x:2025-3-10:day-3',
        },
      );
      final items = ChallengeHistoryPresenter.present(
        l10n: lookupAppLocalizations(const Locale('en')),
        challenge: challenge,
        hydrationLogs: const [],
        unit: HydrionVolumeUnit.milliliters,
      );
      // Themes are Citrus, Berry, Herbal, ...; 10 March is day index 2.
      expect(items.single.description, 'Tried the Herbal infusion');
    });
  });

  group('D8 challenge day number', () {
    test('day number counts civil days across spring forward and fall back',
        () {
      expect(
        ChallengeExperienceScreen.elapsedChallengeDays(
            DateTime(2025, 3, 8, 7), DateTime(2025, 3, 10, 0, 30)),
        2,
      );
      expect(
        ChallengeExperienceScreen.elapsedChallengeDays(
            DateTime(2025, 11, 1, 7), DateTime(2025, 11, 2, 23, 30)),
        1,
      );
      expect(
        ChallengeExperienceScreen.elapsedChallengeDays(
            DateTime(2025, 11, 1, 7), DateTime(2025, 11, 1, 23, 59)),
        0,
      );
    });
  });

  group('D8 yesterday labels', () {
    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ));
      return captured;
    }

    final cases = <String, (DateTime, DateTime, String)>{
      'after spring forward': (
        DateTime(2025, 3, 9, 10),
        DateTime(2025, 3, 10, 12),
        'Yesterday'
      ),
      'after fall back': (
        DateTime(2025, 11, 2, 10),
        DateTime(2025, 11, 3, 12),
        'Yesterday'
      ),
      'same day after spring forward': (
        DateTime(2025, 3, 9, 1),
        DateTime(2025, 3, 9, 23),
        'Today'
      ),
      'two days back over spring forward': (
        DateTime(2025, 3, 8, 10),
        DateTime(2025, 3, 10, 12),
        'Sat, Mar 8'
      ),
    };

    for (final MapEntry(key: name, value: (time, now, label))
        in cases.entries) {
      testWidgets('log and reminders screens label $name', (tester) async {
        final context = await pumpContext(tester);
        expect(LogScreen.formatTimestamp(context, time, now: now),
            startsWith('$label, '));
        expect(RemindersScreen.formatTimestamp(context, time, now: now),
            startsWith('$label, '));
      });
    }
  });

  test('D8 source guard: owned calendar-day sites use civil arithmetic', () {
    final sites = <String, List<String>>{
      'lib/ui/presentation/challenge_history_presenter.dart': [
        'static int _dayIndex(',
      ],
      'lib/ui/screens/challenge_experience_screen.dart': [
        'static int elapsedChallengeDays(',
      ],
      'lib/ui/screens/log_screen.dart': ['static String formatTimestamp('],
      'lib/ui/screens/reminders_screen.dart': [
        'static String formatTimestamp(',
      ],
      'lib/repositories/challenge_repository.dart': [
        'String? _temperatureForDay(',
        'String? _infusionThemeForDay(',
      ],
    };
    final violations = <String>[];
    for (final MapEntry(key: path, value: names) in sites.entries) {
      final source = File(path).readAsStringSync();
      for (final name in names) {
        final start = source.indexOf(name);
        expect(start, isNonNegative, reason: '$name missing in $path');
        final next = source.indexOf(RegExp(r'\n  [^\s/}]'), start + 1);
        final body = source.substring(start, next == -1 ? null : next);
        if (body.contains('.inDays') ||
            body.contains('Duration(days:') ||
            body.contains('Duration(hours: 24')) {
          violations.add('$path $name');
        }
        if (!body.contains('LocalDate')) {
          violations.add('$path $name does not use LocalDate');
        }
      }
    }
    expect(violations, isEmpty);
  });
}
