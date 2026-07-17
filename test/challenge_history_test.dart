import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/presentation/challenge_history_presenter.dart';

void main() {
  final joinedAt = DateTime(2026, 7, 1, 9);

  JoinedChallenge challenge(
    String id, {
    Map<String, Object?> parameters = const {},
    Set<String> actions = const {},
    Set<int> bingoTiles = const {},
  }) =>
      JoinedChallenge(
        id: id,
        name: 'Friendly challenge',
        description: 'A friendly challenge.',
        targetMl: 2200,
        durationDays: 7,
        joinedAt: joinedAt,
        parameters: parameters,
        completedActionIds: actions,
        bottleBingoCompletedTiles: bingoTiles,
      );

  HydrationLog log(String action, int ml, DateTime timestamp) => HydrationLog(
        id: 'log-1',
        volumeMl: ml,
        timestamp: timestamp,
        source: 'challenge',
        actionId: action,
      );

  List<ChallengeHistoryItem> present(
    JoinedChallenge active, {
    List<HydrationLog> logs = const [],
    HydrionVolumeUnit unit = HydrionVolumeUnit.milliliters,
  }) =>
      ChallengeHistoryPresenter.present(
        challenge: active,
        hydrationLogs: logs,
        unit: unit,
      );

  test('hydration history shows amount and controlled timestamp in ml', () {
    const action = 'temperature-roulette:instance:2026-7-4:day-4';
    final timestamp = DateTime(2026, 7, 4, 15, 30);
    final items = present(
      challenge('temperature-roulette', parameters: const {
        'temperatureSchedule': ['Chilled', 'Room temperature']
      }, actions: {
        action
      }),
      logs: [log(action, 250, timestamp)],
    );
    expect(
        items.single.description, 'Logged a Room temperature drink · 250 ml');
    expect(items.single.timestamp, timestamp);
  });

  test('hydration history follows a fluid-ounce unit change', () {
    const action = 'temperature-roulette:instance:2026-7-4:day-4';
    final active = challenge('temperature-roulette', actions: {action});
    final logs = [log(action, 250, DateTime(2026, 7, 4, 15, 30))];
    expect(present(active, logs: logs).single.description, contains('250 ml'));
    expect(
      present(active, logs: logs, unit: HydrionVolumeUnit.ounces)
          .single
          .description,
      contains('8.5 oz'),
    );
  });

  test('Infusion Week history names the daily infusion theme', () {
    const action = 'around-the-world-infusion-week:x:2026-7-3:day-3';
    expect(
      present(challenge('around-the-world-infusion-week', actions: {action}))
          .single
          .description,
      'Tried the Herbal infusion',
    );
  });

  test('Pomodoro history names the session and hydration amount', () {
    const action = 'pomodoro-sip:x:2026-7-2:day-2-pomodoro-sip-session-3';
    expect(
      present(challenge('pomodoro-sip', actions: {action}),
              logs: [log(action, 180, DateTime(2026, 7, 2, 10))])
          .single
          .description,
      'Completed Pomodoro session 3 · 180 ml',
    );
  });

  test('Eat Your Water check-in includes meal and food without an amount', () {
    const action = '2026-07-02:day-2-eat-your-water-day';
    final item = present(challenge('eat-your-water-day', parameters: const {
      'meal': 'lunch',
      'food': 'cucumber',
    }, actions: {
      action
    })).single;
    expect(item.description, 'Added cucumber to lunch');
    expect(item.description, isNot(contains('ml')));
    expect(item.description, isNot(contains('oz')));
  });

  test('missing check-in metadata uses friendly values', () {
    final item = present(
            challenge('eat-your-water-day', actions: const {'legacy-check-in'}))
        .single;
    expect(item.description, 'Added water-rich food to meal');
    expect(item.description, isNot(contains('null')));
  });

  test('Bottle Bingo history names a tile', () {
    final item =
        present(challenge('bottle-bingo', bingoTiles: const {0})).first;
    expect(item.description, startsWith('Completed '));
    expect(item.description, isNot(contains('tile-0')));
  });

  test('Bottle Bingo history announces a completed line', () {
    final items =
        present(challenge('bottle-bingo', bingoTiles: const {0, 1, 2, 3, 4}));
    expect(
      items.map((item) => item.description),
      contains('Completed Bottle Bingo line 1'),
    );
  });

  test('migrated and unknown actions use a safe friendly fallback', () {
    final item = present(challenge('retired-challenge',
            actions: const {'hydrion.storage.internal:enumValue:1700000000'}))
        .single;
    expect(item.description, 'Completed a challenge task');
    expect(item.timestamp, joinedAt);
  });

  test('unknown hydration action uses a friendly fallback with amount', () {
    const action = 'internal_instance_id:raw_enum';
    final item = present(challenge('future-challenge', actions: {action}),
        logs: [log(action, 300, DateTime(2026, 7, 5, 8))]).single;
    expect(item.description, 'Logged a challenge drink · 300 ml');
  });

  test('history is ordered newest first by timestamp', () {
    const older = 'future:2026-7-2:older';
    const newer = 'future:2026-7-5:newer';
    final items = present(
      challenge('future-challenge', actions: const {older, newer}),
      logs: [
        log(older, 100, DateTime(2026, 7, 2, 8)),
        log(newer, 200, DateTime(2026, 7, 5, 18)),
      ],
    );
    expect(items.map((item) => item.timestamp), [
      DateTime(2026, 7, 5, 18),
      DateTime(2026, 7, 2, 8),
    ]);
  });

  test('history survives challenge repository restart', () async {
    final store = MemoryHydrionStore();
    final first = await ChallengeRepository.load(store);
    await first.join(
      id: 'eat-your-water-day',
      name: 'Eat Your Water Day',
      description: 'Friendly',
      targetMl: 2200,
      durationDays: 1,
      joinedAt: joinedAt,
      parameters: const {'meal': 'snack', 'food': 'watermelon'},
    );
    await first.completeCheckIn('2026-07-02:day-2-eat-your-water-day');
    final reloaded = await ChallengeRepository.load(store);
    expect(
      present(reloaded.activeChallenge!).single.description,
      'Added watermelon to snack',
    );
  });

  test('friendly output never leaks internal identifiers', () {
    const action = 'bottle-bingo:987654321:2026-7-4:tile-99';
    final description = present(
      challenge('bottle-bingo', actions: const {action}),
      logs: [log(action, 250, DateTime(2026, 7, 4))],
    ).single.description;
    for (final forbidden in [
      action,
      '987654321',
      'tile-99',
      'challenge:',
      'null'
    ]) {
      expect(description, isNot(contains(forbidden)));
    }
  });

  group('localized history view', () {
    Future<void> pumpView(
      WidgetTester tester, {
      ThemeMode themeMode = ThemeMode.light,
      Size size = const Size(320, 568),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en', 'US')],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChallengeHistoryView(items: [
              ChallengeHistoryItem(
                description: 'Logged a friendly drink · 250 ml',
                timestamp: DateTime(2026, 7, 4, 15, 30),
              ),
            ]),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('renders localized date and time', (tester) async {
      await pumpView(tester);
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data ?? '')
          .join(' | ');
      expect(rendered, contains('Sat, Jul 4'));
      expect(rendered, contains('3:30 PM'));
      expect(rendered, isNot(contains('2026-07-04T15:30')));
    });

    testWidgets('renders in day theme on a small screen', (tester) async {
      await pumpView(tester);
      expect(
          Theme.of(tester.element(find.byType(ChallengeHistoryView)))
              .brightness,
          Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in night theme with scaled text', (tester) async {
      await pumpView(tester, themeMode: ThemeMode.dark, textScale: 2);
      expect(
          Theme.of(tester.element(find.byType(ChallengeHistoryView)))
              .brightness,
          Brightness.dark);
      expect(find.textContaining('250 ml'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
