import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';

void main() {
  testWidgets('countdown and meter consume the same timer snapshot',
      (tester) async {
    final services = await pumpPomodoro(tester);

    final countdown = countdownSeconds(tester);
    final meter = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('pomodoro-meter')),
        )
        .value!;
    final expected = ((25 * 60 - countdown) / (25 * 60)).clamp(0.0, 1.0);

    expect(meter, closeTo(expected, 0.001));
    expect(services.hydrationRepository.logs, isEmpty);
  });

  testWidgets('pause freezes countdown and meter and resume advances both',
      (tester) async {
    await pumpPomodoro(tester);
    await tester.tap(find.byKey(const Key('pomodoro-pause')));
    await tester.pumpAndSettle();
    final pausedSeconds = countdownSeconds(tester);
    final pausedMeter = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('pomodoro-meter')),
        )
        .value;

    await tester.pump(const Duration(seconds: 4));
    expect(countdownSeconds(tester), pausedSeconds);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('pomodoro-meter')),
          )
          .value,
      pausedMeter,
    );

    await tester.tap(find.byKey(const Key('pomodoro-resume')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(countdownSeconds(tester), lessThan(pausedSeconds));
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('pomodoro-meter')),
          )
          .value,
      greaterThan(pausedMeter!),
    );
  });

  testWidgets('restart resets both values with a fresh session',
      (tester) async {
    final services = await pumpPomodoro(tester);
    final firstId = services.pomodoroSessionService.currentState()!.sessionId;
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.byKey(const Key('pomodoro-restart')));
    await tester.pumpAndSettle();

    expect(
      services.pomodoroSessionService.currentState()!.sessionId,
      isNot(firstId),
    );
    expect(countdownSeconds(tester), inInclusiveRange(1499, 1500));
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('pomodoro-meter')),
          )
          .value,
      lessThanOrEqualTo(1 / 1500),
    );
  });

  testWidgets('completion exposes sip without fabricating hydration',
      (tester) async {
    final services = await pumpPomodoro(tester);
    await tester.tap(find.byKey(const Key('pomodoro-end-early')));
    await tester.pumpAndSettle();

    expect(find.text('Sip ready'), findsOneWidget);
    expect(services.hydrationRepository.logs, isEmpty);
    expect(
      services.pomodoroSessionService.currentState()!.history,
      hasLength(1),
    );
  });

  testWidgets('rapid confirmed sip taps persist one real hydration event',
      (tester) async {
    final services = await pumpPomodoro(tester);
    await tester.tap(find.byKey(const Key('pomodoro-end-early')));
    await tester.pumpAndSettle();
    final sip = find.byKey(
      const Key('challenge-primary-action-pomodoro-sip'),
    );
    await revealByScrolling(
      tester,
      target: sip,
      scrollView: find.byKey(const Key('challenge-scroll-pomodoro-sip')),
    );

    await tester.tap(sip);
    await tester.tap(sip);
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.logs, hasLength(1));
    expect(services.hydrationRepository.logs.single.volumeMl, 150);
    expect(
      services.hydrationRepository.logs.single.timestamp.hour,
      isNot(0),
    );
  });

  testWidgets('timer ticker is disposed when the challenge view is removed',
      (tester) async {
    await pumpPomodoro(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });
}

Future<HydrionServices> pumpPomodoro(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final services = HydrionServices.memory(
    guidedTourRepository:
        GuidedTourRepository.memory(contextualToursCompleted: true),
  );
  await services.challengeRepository.join(
    id: 'pomodoro-sip',
    name: 'Pomodoro Sip',
    description: 'Focus and hydrate deliberately.',
    targetMl: 2200,
    durationDays: 3,
    parameters: const {
      'sessionMinutes': 25,
      'sessionsPerDay': 1,
      'amountMl': 150,
      'shortBreakMinutes': 5,
      'notifications': 'disabled',
      'autoStartNext': 'disabled',
      'challengeDurationDays': 3,
      'timerStatus': 'stopped',
    },
  );
  await services.pomodoroSessionService.start();
  await tester.pumpWidget(HydrionApp(services: services));
  await tester.pumpAndSettle();
  tester
      .widget<NavigationBar>(
        find.byKey(const Key('hydrion-bottom-nav')),
      )
      .onDestinationSelected
      ?.call(1);
  await tester.pumpAndSettle();
  final card = find.byKey(const Key('challenge-card-pomodoro-sip'));
  await revealByScrolling(
    tester,
    target: card,
    scrollView: find.byKey(const Key('challenges-catalog-scroll')),
  );
  await tester.tap(card);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('pomodoro-countdown')), findsOneWidget);
  await revealByScrolling(
    tester,
    target: find.byKey(const Key('pomodoro-pause')),
    scrollView: find.byKey(const Key('challenge-scroll-pomodoro-sip')),
  );
  return services;
}

Future<void> revealByScrolling(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollView,
}) async {
  for (var attempt = 0; attempt < 60 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollView, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final viewportHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final center = tester.getRect(target).center;
  if (center.dy < 0 || center.dy > viewportHeight) {
    await tester.drag(
      scrollView,
      Offset(0, viewportHeight / 2 - center.dy),
    );
    await tester.pumpAndSettle();
  }
}

int countdownSeconds(WidgetTester tester) {
  final text =
      tester.widget<Text>(find.byKey(const Key('pomodoro-countdown'))).data!;
  final parts = text.split(':').map(int.parse).toList();
  return parts[0] * 60 + parts[1];
}
