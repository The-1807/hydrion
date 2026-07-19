import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/ui/components/guided_tour_overlay.dart';
import 'package:provider/provider.dart';

void main() {
  Widget harness(
    GuidedTourRepository repository, {
    required GlobalKey target,
    String tourId = 'bottle-bingo:release18-v1',
    bool includeTarget = true,
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return ChangeNotifierProvider.value(
      value: repository,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: ContextualGuidedTourOverlay(
            tourId: tourId,
            semanticsLabel: 'Bottle Bingo tutorial',
            steps: [
              GuidedTourStep(
                targetKey: target,
                title: 'Open a tile',
                body: 'Open a tile to see what it requires.',
              ),
              GuidedTourStep(
                targetKey: target,
                title: 'Automatic tiles',
                body: 'Some tiles update from hydration logs.',
              ),
            ],
            child: Scaffold(
              body: Center(
                child: includeTarget
                    ? FilledButton(
                        key: target,
                        onPressed: () {},
                        child: const Text('Bingo tile'),
                      )
                    : const Text('Target unavailable'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('first activation supports next, back, finish and no replay',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository =
        GuidedTourRepository.memory(contextualToursCompleted: false);
    final target = GlobalKey();
    await tester.pumpWidget(harness(repository, target: target));
    await tester.pumpAndSettle();

    expect(find.text('Open a tile'), findsOneWidget);
    expect(find.bySemanticsLabel('Bottle Bingo tutorial step 1 of 2'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(find.text('Automatic tiles'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-back')));
    await tester.pumpAndSettle();
    expect(find.text('Open a tile'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();

    expect(find.text('Open a tile'), findsNothing);
    expect(
        repository.isContextualTourComplete(
          'bottle-bingo:release18-v1',
        ),
        isTrue);

    await tester.pumpWidget(harness(repository, target: target));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tour-next')), findsNothing);
  });

  testWidgets('skip persists and explicit replay works', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository =
        GuidedTourRepository.memory(contextualToursCompleted: false);
    final target = GlobalKey();
    await tester.pumpWidget(harness(repository, target: target));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tour-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tour-next')), findsNothing);

    repository.replayContextualTour('bottle-bingo:release18-v1');
    await tester.pumpAndSettle();
    expect(find.text('Open a tile'), findsOneWidget);
  });

  testWidgets(
      'missing target, compact layout, large text and reduced motion work',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final repository =
        GuidedTourRepository.memory(contextualToursCompleted: false);
    await tester.pumpWidget(
      harness(
        repository,
        target: GlobalKey(),
        includeTarget: false,
        size: const Size(320, 568),
        textScale: 1.5,
        reducedMotion: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open a tile'), findsNothing);
    expect(
      repository.isContextualTourComplete('bottle-bingo:release18-v1'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded layout anchors without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    final repository =
        GuidedTourRepository.memory(contextualToursCompleted: false);
    final target = GlobalKey();
    await tester.pumpWidget(
      harness(
        repository,
        target: target,
        size: const Size(1280, 800),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open a tile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
