import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/components/guided_tour_overlay.dart';
import 'package:hydrion/ui/components/hydration_score_card.dart';
import 'package:provider/provider.dart';

void main() {
  group('guided tour layout geometry', () {
    test('uses the rendered target and keeps the card clear of it', () {
      const target = Rect.fromLTWH(120, 120, 96, 48);
      final geometry = GuidedTourLayout.calculate(
        viewport: const Size(390, 844),
        safePadding: const EdgeInsets.only(top: 24, bottom: 20),
        viewInsets: EdgeInsets.zero,
        cardSize: const Size(358, 240),
        targetRect: target,
      );

      expect(geometry.spotlightRect, target.inflate(7));
      expect(geometry.cardRect.overlaps(geometry.spotlightRect!), isFalse);
      expect(geometry.cardRect.left, greaterThanOrEqualTo(12));
      expect(geometry.cardRect.right, lessThanOrEqualTo(378));
      expect(geometry.pointerStart, isNotNull);
      expect(
        (geometry.pointerEnd! - geometry.spotlightRect!.center).distance,
        lessThan(geometry.spotlightRect!.longestSide / 2 + 1),
      );
    });

    test('selects safe horizontal placement on an expanded screen', () {
      const target = Rect.fromLTWH(120, 300, 88, 52);
      final geometry = GuidedTourLayout.calculate(
        viewport: const Size(1280, 800),
        safePadding: const EdgeInsets.all(8),
        viewInsets: EdgeInsets.zero,
        cardSize: const Size(400, 260),
        targetRect: target,
        expanded: true,
      );

      expect(geometry.placement, TourCardPlacement.right);
      expect(geometry.cardRect.left, greaterThan(target.right));
      expect(geometry.cardRect.overlaps(geometry.spotlightRect!), isFalse);
    });

    test('centers safely and omits pointer without a target', () {
      final geometry = GuidedTourLayout.calculate(
        viewport: const Size(360, 640),
        safePadding: const EdgeInsets.only(top: 32, bottom: 24),
        viewInsets: const EdgeInsets.only(bottom: 220),
        cardSize: const Size(328, 220),
        targetRect: null,
      );

      expect(geometry.placement, TourCardPlacement.centered);
      expect(geometry.pointerStart, isNull);
      expect(geometry.cardRect.bottom, lessThanOrEqualTo(408));
    });
  });

  group('guided tour persistence and launch policy', () {
    test('new users receive the beginner tour', () async {
      final repository = await GuidedTourRepository.load(MemoryHydrionStore());

      expect(repository.shouldShowCoreTour, isTrue);
      expect(repository.shouldOfferWhatsNew, isFalse);
    });

    test('established users receive a dismissible optional prompt', () async {
      final store = MemoryHydrionStore();
      final repository = await GuidedTourRepository.load(
        store,
        establishedUser: true,
      );

      expect(repository.shouldShowCoreTour, isFalse);
      expect(repository.shouldOfferWhatsNew, isTrue);
      await repository.dismissWhatsNew();

      final reloaded = await GuidedTourRepository.load(
        store,
        establishedUser: true,
      );
      expect(reloaded.shouldOfferWhatsNew, isFalse);
      expect(reloaded.shouldShowCoreTour, isFalse);
    });

    test('manual replay preserves the normal completed state', () async {
      final store = MemoryHydrionStore();
      final repository = await GuidedTourRepository.load(
        store,
        establishedUser: true,
      );
      await repository.dismissWhatsNew();
      await repository.replayCoreTour();

      expect(repository.shouldShowCoreTour, isTrue);
      expect(repository.state.completed, isTrue);
      await repository.completeCoreTour();
      expect(repository.shouldShowCoreTour, isFalse);
      expect(repository.state.completed, isTrue);
    });

    test('core version upgrade preserves contextual tutorial completion',
        () async {
      final store = MemoryHydrionStore();
      await store.writeString(
        GuidedTourRepository.storageKey,
        jsonEncode({
          'version': 'release18-core-tour',
          'completed': true,
          'completedContextualTours': ['bottle-bingo:release18-v1'],
          'contextualCurrentSteps': <String, int>{},
        }),
      );

      final repository = await GuidedTourRepository.load(
        store,
        establishedUser: true,
      );
      expect(repository.shouldOfferWhatsNew, isTrue);
      expect(
        repository.isContextualTourComplete('bottle-bingo:release18-v1'),
        isTrue,
      );
    });

    test('an old interrupted step does not reopen days later', () async {
      final store = MemoryHydrionStore();
      final interaction = DateTime(2026, 7, 10, 8);
      await store.writeString(
        GuidedTourRepository.storageKey,
        jsonEncode({
          'version': GuidedTourRepository.currentVersion,
          'completed': false,
          'skipped': false,
          'currentStep': 3,
          'completedContextualTours': <String>[],
          'contextualCurrentSteps': <String, int>{},
          'whatsNewPromptPending': false,
          'lastCoreInteractionAt': interaction.toIso8601String(),
        }),
      );

      final repository = await GuidedTourRepository.load(
        store,
        now: DateTime(2026, 7, 12, 8),
      );
      expect(repository.shouldShowCoreTour, isFalse);
      expect(repository.state.skipped, isTrue);
      expect(repository.currentStep, 0);
    });
  });

  group('factual progress status', () {
    const empty = 'Start with 300 to 500 ml now and set a reminder.';

    test('zero logs retains the empty factual state', () {
      expect(
        hydrationProgressStatus(
          todayMl: 0,
          targetMl: 2200,
          entryCount: 0,
          volumeUnit: HydrionVolumeUnit.milliliters,
          emptyStatus: empty,
        ),
        empty,
      );
    });

    test('partial progress reports logs and remaining amount', () {
      final status = hydrationProgressStatus(
        todayMl: 500,
        targetMl: 2450,
        entryCount: 2,
        volumeUnit: HydrionVolumeUnit.milliliters,
        emptyStatus: empty,
      );

      expect(status, '500 ml recorded across 2 logs today. 1950 ml remaining.');
      expect(status, isNot(contains('Start with')));
    });

    test('completed and over-goal progress uses completion state', () {
      for (final amount in [2200, 2500]) {
        final status = hydrationProgressStatus(
          todayMl: amount,
          targetMl: 2200,
          entryCount: 1,
          volumeUnit: HydrionVolumeUnit.milliliters,
          emptyStatus: empty,
        );
        expect(status, startsWith('Daily goal completed.'));
        expect(status, contains('1 log today'));
      }
    });

    test('fluid ounces use the selected unit', () {
      final status = hydrationProgressStatus(
        todayMl: 500,
        targetMl: 2200,
        entryCount: 1,
        volumeUnit: HydrionVolumeUnit.ounces,
        emptyStatus: empty,
      );

      expect(status, contains('oz'));
      expect(status, isNot(contains(' ml')));
    });
  });

  group('rendered tour behavior', () {
    Widget harness({
      required GuidedTourRepository repository,
      required GlobalKey target,
      required Size size,
      double textScale = 1,
      bool dark = false,
      bool reducedMotion = false,
      bool pullGesture = false,
    }) {
      return ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: GuidedTourOverlay(
              steps: [
                GuidedTourStep(
                  targetKey: target,
                  title: 'Log what you drink',
                  body: 'Use your saved container or choose the actual amount.',
                  demonstratesPullToRefresh: pullGesture,
                ),
              ],
              child: Scaffold(
                body: Align(
                  alignment: const Alignment(0, -0.45),
                  child: FilledButton(
                    key: target,
                    onPressed: () {},
                    child: const Text('Log water'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final variant in <(String, Size, double, bool)>[
      ('compact day', const Size(360, 640), 1, false),
      ('tall night', const Size(430, 932), 1, true),
      ('tablet day', const Size(768, 1024), 1, false),
      ('landscape night', const Size(844, 390), 1, true),
      ('large text', const Size(390, 844), 1.8, false),
    ]) {
      testWidgets('${variant.$1} keeps actions and target usable',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = variant.$2;
        addTearDown(tester.view.reset);
        final repository = GuidedTourRepository.memory(completed: false);
        final target = GlobalKey();

        await tester.pumpWidget(
          harness(
            repository: repository,
            target: target,
            size: variant.$2,
            textScale: variant.$3,
            dark: variant.$4,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tour-spotlight')), findsOneWidget);
        expect(find.byKey(const Key('tour-next')), findsOneWidget);
        expect(find.byKey(const Key('tour-back')), findsNothing);
        expect(find.byKey(const Key('tour-pointer')), findsOneWidget);
        expect(tester.getRect(find.byKey(const Key('tour-next'))).bottom,
            lessThanOrEqualTo(variant.$2.height));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'pull gesture is static with reduced motion and never refreshes',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final repository = GuidedTourRepository.memory(completed: false);
      final target = GlobalKey();

      await tester.pumpWidget(
        harness(
          repository: repository,
          target: target,
          size: const Size(390, 844),
          reducedMotion: true,
          pullGesture: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tour-pull-gesture')), findsOneWidget);
      expect(find.text('Pull to refresh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('existing user can dismiss the optional whats-new prompt',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = GuidedTourRepository.memory(
      completed: true,
      whatsNewPromptPending: true,
    );
    final services = HydrionServices.memory(guidedTourRepository: repository);

    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/home'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new-tour-prompt')), findsOneWidget);
    expect(find.text('See what\u2019s new'), findsOneWidget);
    expect(find.byKey(const Key('tour-next')), findsNothing);

    await tester.tap(find.byKey(const Key('whats-new-not-now')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new-tour-prompt')), findsNothing);
    expect(repository.shouldOfferWhatsNew, isFalse);
  });

  testWidgets('core tour navigates to actual destinations and returns home',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = GuidedTourRepository.memory(completed: false);
    final services = HydrionServices.memory(guidedTourRepository: repository);
    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/home'),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's hydration"), findsOneWidget);
    expect(find.byKey(const Key('tour-back')), findsNothing);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(find.text('Log water'), findsWidgets);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(find.text('Review and correct'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('hydrion-bottom-nav')))
          .selectedIndex,
      1,
    );
    expect(find.text('Challenges'), findsWidgets);

    await tester.tap(find.byKey(const Key('tour-back')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('hydrion-bottom-nav')))
          .selectedIndex,
      0,
    );
    await repository.setCurrentStep(4);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('hydrion-bottom-nav')))
          .selectedIndex,
      2,
    );
    expect(find.byKey(const Key('tour-pull-gesture')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(repository.state.completed, isTrue);
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('hydrion-bottom-nav')))
          .selectedIndex,
      0,
    );
    expect(find.byKey(const Key('tour-next')), findsNothing);
  });

  testWidgets('progress chart has readable responsive day labels and units',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);
    final services = HydrionServices.memory();
    await services.settingsRepository.setVolumeUnit(HydrionVolumeUnit.ounces);
    await services.hydrationRepository.addLog(
      volumeMl: 500,
      timestamp: DateTime.now(),
      source: 'test',
    );
    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/home'),
    );
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(find.byKey(const Key('hydrion-bottom-nav')))
        .onDestinationSelected
        ?.call(2);
    await tester.pumpAndSettle();

    Finder dayLabels() => find.byWidgetPredicate(
          (widget) =>
              widget.key?.toString().contains('weekly-day-label-') == true,
        );
    expect(dayLabels(), findsNWidgets(4));
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('recorded across 1 log today'), findsOneWidget);
    expect(find.textContaining('oz remaining'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpAndSettle();
    expect(dayLabels(), findsNWidgets(7));
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
