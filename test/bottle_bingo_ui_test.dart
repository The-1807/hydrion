import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/bottle_bingo.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/challenge_visual_registry.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';

void main() {
  const asset = 'assets/UI_BETA/ble_bottle.png';

  Future<HydrionServices> pumpBingo(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    HydrionThemePreference theme = HydrionThemePreference.light,
    HydrionVolumeUnit unit = HydrionVolumeUnit.milliliters,
    bool active = true,
    int amountMl = 500,
    int cutoffHour = 12,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final services = HydrionServices.memory();
    await services.settingsRepository.setThemePreference(theme);
    await services.settingsRepository.setVolumeUnit(unit);
    if (active) {
      final challenge = HydrionChallengeCatalog.byId('bottle-bingo');
      final today = DateTime.now();
      await services.challengeRepository.join(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        targetMl: 2200,
        durationDays: challenge.durationDays,
        joinedAt: DateTime(today.year, today.month, today.day),
        parameters: {
          'cutoffHour': cutoffHour,
          'difficulty': 'balanced',
          'reminderPreference': 'enabled',
          'amountMl': amountMl,
          'bingoBoardVersion': 2,
        },
      );
    }
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: HydrionApp(
          services: services,
          initialRoute: '/home',
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(
          find.byKey(const Key('hydrion-bottom-nav')),
        )
        .onDestinationSelected
        ?.call(1);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('challenge-card-bottle-bingo'));
    final challengeList = find.descendant(
      of: find.byKey(const Key('challenges-refresh-indicator')),
      matching: find.byType(Scrollable),
    );
    for (var attempt = 0;
        attempt < 10 && card.evaluate().isEmpty;
        attempt += 1) {
      await tester.drag(challengeList, const Offset(0, -360));
      await tester.pumpAndSettle();
    }
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    if (active) {
      await tester.tap(card);
      await tester.pumpAndSettle();
    }
    return services;
  }

  Finder bingoCells() => find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>)
                .value
                .startsWith('live-bingo-tile-'),
      );

  bool usesAsset(Image image, String name) {
    final provider = image.image;
    if (provider is AssetImage) return provider.assetName == name;
    if (provider is ResizeImage && provider.imageProvider is AssetImage) {
      return (provider.imageProvider as AssetImage).assetName == name;
    }
    return false;
  }

  test('Bottle Bingo registry uses the supplied local transparent artwork', () {
    final visual = ChallengeVisualRegistry.forId('bottle-bingo');
    expect(visual.cardAsset, asset);
    expect(visual.dashboardAssetFor(null), asset);
    expect(File(asset).existsSync(), isTrue);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/UI_BETA/'),
    );
    expect(asset, isNot(contains('reference')));
    expect(asset, isNot(contains('screenshot')));
  });

  for (final theme in const {
    HydrionThemePreference.light: 'day',
    HydrionThemePreference.dark: 'night',
  }.entries) {
    testWidgets('catalogue card uses supplied artwork in ${theme.value} theme',
        (tester) async {
      await pumpBingo(tester, active: false, theme: theme.key);
      final header = find.byKey(const Key('bottle-bingo-catalogue-header'));
      expect(header, findsOneWidget);
      final images = tester.widgetList<Image>(
        find.descendant(of: header, matching: find.byType(Image)),
      );
      expect(
        images.where((image) => usesAsset(image, asset)),
        hasLength(1),
      );
      expect(find.text('Open the board preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1280, 800),
    Size(844, 390),
  ]) {
    testWidgets('board is a readable square 5 by 5 game at $size',
        (tester) async {
      await pumpBingo(tester, size: size);
      final board = find.byKey(const Key('live-bottle-bingo-board'));
      await tester.scrollUntilVisible(
        board,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(board, findsOneWidget);
      expect(bingoCells(), findsNWidgets(25));
      final center = find.byKey(const Key('live-bingo-tile-12'));
      expect(center, findsOneWidget);
      final centerSize = tester.getSize(center);
      expect((centerSize.width - centerSize.height).abs(), lessThan(0.5));
      expect(centerSize.width, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('dashboard hero uses supplied artwork and concise metrics',
      (tester) async {
    await pumpBingo(tester);
    final hero = find.byKey(const Key('bottle-bingo-dashboard-hero'));
    expect(hero, findsOneWidget);
    final image = tester.widget<Image>(
      find.descendant(of: hero, matching: find.byType(Image)),
    );
    expect(usesAsset(image, asset), isTrue);
    expect(find.byKey(const Key('bottle-bingo-tiles-metric')), findsOneWidget);
    expect(find.byKey(const Key('bottle-bingo-lines-metric')), findsOneWidget);
    expect(find.byKey(const Key('bottle-bingo-today-metric')), findsOneWidget);
    expect(find.text('Challenge-qualified hydration'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact tile opens friendly details and measured action',
      (tester) async {
    final services = await pumpBingo(tester, size: const Size(390, 844));
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final index = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.hydrationAction,
    );
    final tileFinder = find.byKey(Key('live-bingo-tile-$index'));
    await tester.scrollUntilVisible(
      tileFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tileFinder);
    await tester.pumpAndSettle();
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();
    expect(find.text(board.tiles[index].instruction), findsOneWidget);
    expect(find.text('Why it counts'), findsOneWidget);
    expect(find.text('Home hydration'), findsOneWidget);
    expect(find.text('Adds hydration'), findsOneWidget);
    expect(find.text('Log 500 ml'), findsOneWidget);
    expect(find.textContaining('tile-'), findsNothing);
    expect(find.textContaining('BingoTileKind'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout keeps selected tile details beside the board',
      (tester) async {
    final services = await pumpBingo(tester, size: const Size(1280, 800));
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final index = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.checkIn,
    );
    final tileFinder = find.byKey(Key('live-bingo-tile-$index'));
    await tester.scrollUntilVisible(
      tileFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();
    final details = find.byKey(const Key('bottle-bingo-selected-tile-details'));
    expect(details, findsOneWidget);
    expect(tester.getTopLeft(details).dx,
        greaterThan(tester.getTopLeft(tileFinder).dx));
    expect(find.text(board.tiles[index].instruction), findsOneWidget);
    expect(find.text('Complete check-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet layout keeps selected tile details beside the board',
      (tester) async {
    final services = await pumpBingo(tester, size: const Size(768, 1024));
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final index = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.checkIn,
    );
    final tileFinder = find.byKey(Key('live-bingo-tile-$index'));
    await tester.scrollUntilVisible(
      tileFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tileFinder);
    await tester.pumpAndSettle();
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    final details = find.byKey(const Key('bottle-bingo-selected-tile-details'));
    expect(details, findsOneWidget);
    expect(
      tester.getTopLeft(details).dx,
      greaterThan(tester.getTopLeft(tileFinder).dx),
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default test viewport selects measured tile details',
      (tester) async {
    final services = await pumpBingo(tester, size: const Size(800, 600));
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final index = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.hydrationAction,
    );
    final tileFinder = find.byKey(Key('live-bingo-tile-$index'));
    await tester.scrollUntilVisible(
      tileFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tileFinder);
    await tester.pumpAndSettle();
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();
    expect(find.text(board.tiles[index].instruction), findsOneWidget);
    expect(
      find.byKey(const Key('bottle-bingo-tile-primary-action')),
      findsOneWidget,
    );
    expect(find.text('Log 500 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial automatic progress uses selected fluid-ounce unit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final services = await pumpBingo(
      tester,
      unit: HydrionVolumeUnit.ounces,
    );
    await services.hydrationRepository.addLog(
      volumeMl: 250,
      timestamp: DateTime.now(),
      source: 'home',
    );
    await tester.pumpAndSettle();
    final boardFinder = find.byKey(const Key('live-bottle-bingo-board'));
    await tester.scrollUntilVisible(
      boardFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('In progress.*oz')), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('automatic, available, missed, and setup states are announced',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final services = await pumpBingo(
      tester,
      amountMl: 0,
      cutoffHour: 0,
    );
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final missedIndex = board.tiles.indexWhere(
      (tile) => tile.id == 'before-lunch',
    );
    final setupIndex = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.hydrationAction,
    );
    final checkInIndex = board.tiles.indexWhere(
      (tile) => tile.kind == BingoTileKind.checkIn,
    );
    final boardFinder = find.byKey(const Key('live-bottle-bingo-board'));
    await tester.scrollUntilVisible(
      boardFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(
        '^${RegExp.escape(board.tiles[missedIndex].title)}.*Missed today',
      )),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(
        '^${RegExp.escape(board.tiles[setupIndex].title)}.*Needs setup',
      )),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(
        '^${RegExp.escape(board.tiles[checkInIndex].title)}.*Available',
      )),
      findsOneWidget,
    );
    final setupTile = find.byKey(Key('live-bingo-tile-$setupIndex'));
    await tester.ensureVisible(setupTile);
    await tester.pumpAndSettle();
    await tester.tap(setupTile);
    await tester.pumpAndSettle();
    expect(
      find.text('Set a measured challenge amount before logging.'),
      findsOneWidget,
    );
    final setupAction = find.byKey(
      const Key('bottle-bingo-tile-primary-action'),
    );
    expect(find.text('Set up challenge amount'), findsOneWidget);
    await tester.ensureVisible(setupAction);
    await tester.tap(setupAction);
    await tester.pumpAndSettle();
    expect(find.text('Challenge settings'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('automatic tile details explain existing Home hydration',
      (tester) async {
    final services = await pumpBingo(tester);
    final active = services.challengeRepository.activeChallengeFor(
      'bottle-bingo',
    )!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final index = board.tiles.indexWhere(
      (tile) => tile.goalFraction != null,
    );
    final tileFinder = find.byKey(Key('live-bingo-tile-$index'));
    await tester.scrollUntilVisible(
      tileFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tileFinder);
    await tester.pumpAndSettle();
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    expect(find.text(board.tiles[index].instruction), findsOneWidget);
    expect(find.text('Can satisfy this tile automatically.'), findsOneWidget);
    expect(find.text('No new hydration record is added.'), findsOneWidget);
    expect(
      find.byKey(const Key('bottle-bingo-tile-primary-action')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed board presents all lines and reverses with evidence',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final services = await pumpBingo(tester);
    final challenges = services.challengeRepository;
    final hydration = services.hydrationRepository;
    final active = challenges.activeChallengeFor('bottle-bingo')!;
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final today = DateTime.now();
    for (var index = 0; index < board.tiles.length; index += 1) {
      final tile = board.tiles[index];
      if (tile.kind == BingoTileKind.checkIn) {
        expect(await challenges.toggleBottleBingoTile(index), isTrue);
      } else if (tile.kind == BingoTileKind.hydrationAction) {
        expect(
          await challenges.completeHydrationAction(
            hydrationRepository: hydration,
            volumeMl: 500,
            actionKey: tile.id,
            timestamp: DateTime(today.year, today.month, today.day, 15),
            challengeId: active.id,
            metadata: HydrationMetadata(bingoTileSource: tile.id),
          ),
          isNotNull,
        );
      }
    }
    for (final hour in const [8, 10, 13, 15]) {
      await hydration.addLog(
        volumeMl: 550,
        timestamp: DateTime(today.year, today.month, today.day, hour),
        source: 'home',
      );
    }
    await tester.pumpAndSettle();

    expect(
      challenges.bottleBingoCompletedIndexes(
        hydration,
        challenge: challenges.activeChallengeFor('bottle-bingo'),
        dailyGoalMl: 2200,
      ),
      hasLength(25),
    );
    expect(find.text('12 / 12'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Part of a completed Bingo line')),
      findsNWidgets(25),
    );

    final evidence = List<HydrationLog>.of(hydration.logs);
    for (final log in evidence) {
      expect(await hydration.deleteLog(log.id), isTrue);
    }
    await tester.pumpAndSettle();
    final reversedLines = board
        .completedLines(
          challenges.bottleBingoCompletedIndexes(
            hydration,
            challenge: challenges.activeChallengeFor('bottle-bingo'),
            dailyGoalMl: 2200,
          ),
        )
        .length;
    expect(reversedLines, lessThan(12));
    expect(find.text('$reversedLines / 12'), findsOneWidget);

    for (final log in evidence) {
      expect(await hydration.restoreLog(log), isTrue);
    }
    await tester.pumpAndSettle();
    expect(find.text('12 / 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('large text keeps compact board usable without overflow',
      (tester) async {
    await pumpBingo(
      tester,
      size: const Size(360, 640),
      textScale: 1.5,
      theme: HydrionThemePreference.dark,
    );
    final board = find.byKey(const Key('live-bottle-bingo-board'));
    await tester.scrollUntilVisible(
      board,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(bingoCells(), findsNWidgets(25));
    expect(tester.takeException(), isNull);
  });
}
