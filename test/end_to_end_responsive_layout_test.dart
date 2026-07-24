import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';

void main() {
  Future<HydrionServices> pumpHydrion(
    WidgetTester tester, {
    required Size size,
    required String route,
    double textScale = 1,
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool dark = false,
    HydrionServices? services,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final resolved = services ??
        HydrionServices.memory(
          guidedTourRepository: GuidedTourRepository.memory(completed: true),
        );
    if (dark) {
      await resolved.settingsRepository
          .setThemePreference(HydrionThemePreference.dark);
    }
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: viewPadding,
          viewPadding: viewPadding,
          viewInsets: viewInsets,
        ),
        child: HydrionApp(
          key: ValueKey<HydrionServices>(resolved),
          services: resolved,
          initialRoute: route,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expectNoLayoutFailure(tester);
    return resolved;
  }

  group('application shell viewport matrix', () {
    const variants = <({
      String name,
      Size size,
      double scale,
      EdgeInsets padding,
      bool dark,
    })>[
      (
        name: 'compact three-button light',
        size: Size(320, 568),
        scale: 1,
        padding: EdgeInsets.only(top: 24, bottom: 48),
        dark: false,
      ),
      (
        name: 'narrow gesture dark',
        size: Size(360, 640),
        scale: 1.3,
        padding: EdgeInsets.only(top: 28, bottom: 20),
        dark: true,
      ),
      (
        name: 'modern phone large text',
        size: Size(360, 780),
        scale: 1.5,
        padding: EdgeInsets.only(top: 32, bottom: 24),
        dark: false,
      ),
      (
        name: 'medium phone no bottom inset',
        size: Size(412, 915),
        scale: 2,
        padding: EdgeInsets.only(top: 36),
        dark: true,
      ),
      (
        name: 'wide portrait cutout',
        size: Size(480, 960),
        scale: 1.3,
        padding: EdgeInsets.fromLTRB(8, 44, 8, 28),
        dark: false,
      ),
    ];

    for (final variant in variants) {
      testWidgets('${variant.name} keeps header, body, and navigation separate',
          (tester) async {
        await pumpHydrion(
          tester,
          size: variant.size,
          route: '/home',
          textScale: variant.scale,
          viewPadding: variant.padding,
          dark: variant.dark,
        );

        final safeStack =
            tester.getRect(find.byKey(const Key('hydrion-tab-safe-stack')));
        final appBar = tester.getRect(find.byKey(const Key('home-appbar')));
        final gauge =
            tester.getRect(find.byKey(const Key('hydration-progress-gauge')));
        final nav = tester.getRect(find.byKey(const Key('hydrion-bottom-nav')));
        final navBackground = tester
            .getRect(find.byKey(const Key('hydrion-bottom-nav-background')));

        expect(safeStack.top, greaterThanOrEqualTo(variant.padding.top));
        expect(appBar.bottom, lessThanOrEqualTo(gauge.top));
        expect(nav.height, inInclusiveRange(64, 76));
        expect(
          navBackground.height,
          closeTo(nav.height + variant.padding.bottom, 0.01),
        );
        expect(navBackground.bottom, closeTo(variant.size.height, 0.01));

        await tester.scrollUntilVisible(
          find.byKey(const Key('log-water-button')),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final logButton =
            tester.getRect(find.byKey(const Key('log-water-button')));
        expect(logButton.bottom, lessThanOrEqualTo(navBackground.top));
        expectNoLayoutFailure(tester);
      });
    }
  });

  testWidgets('all persistent destinations render at 2x text on compact phone',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/home',
      textScale: 2,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
    );
    for (var index = 0; index < 4; index++) {
      tester
          .widget<NavigationBar>(
            find.byKey(const Key('hydrion-bottom-nav')),
          )
          .onDestinationSelected
          ?.call(index);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
      expectNoLayoutFailure(tester, reason: 'Shell destination $index');
    }
  });

  testWidgets('long reminder cards measure content and never overlap',
      (tester) async {
    final services = HydrionServices.memory(
      guidedTourRepository: GuidedTourRepository.memory(completed: true),
    );
    final first = await services.reminderRepository.save(
      triggerTime: DateTime.now().add(const Duration(hours: 2)),
      message:
          'Take a calm hydration break after your current activity and review the amount you actually drank before continuing with the rest of your day.',
      priority: 1,
    );
    final second = await services.reminderRepository.save(
      triggerTime: DateTime.now().add(const Duration(hours: 3)),
      message:
          'A second intentionally long reminder confirms that wrapped descriptions, scheduling feedback, edit actions, and delete actions receive their own measured space.',
      priority: 1,
    );
    await services.reminderRepository.setScheduleState(
      id: first.id,
      state: ReminderScheduleState.scheduledApproximately,
    );
    await services.reminderRepository.setScheduleState(
      id: second.id,
      state: ReminderScheduleState.needsRescheduling,
    );

    await pumpHydrion(
      tester,
      size: const Size(360, 1400),
      route: '/reminders',
      textScale: 1.3,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      services: services,
    );

    final firstCard =
        tester.getRect(find.byKey(Key('reminder-card-${first.id}')));
    final secondCard =
        tester.getRect(find.byKey(Key('reminder-card-${second.id}')));
    expect(firstCard.bottom, lessThan(secondCard.top));
    for (final action in [
      find.byKey(Key('edit-reminder-${first.id}')),
      find.byKey(Key('delete-reminder-${first.id}')),
    ]) {
      final rect = tester.getRect(action);
      expect(firstCard.contains(rect.topLeft), isTrue);
      expect(firstCard.contains(rect.bottomRight), isTrue);
    }
    expect(find.textContaining('ArgumentError'), findsNothing);
    expect(find.textContaining('PlatformException'), findsNothing);
    expectNoLayoutFailure(tester);
  });

  testWidgets('one long reminder remains usable at 2x text on compact phone',
      (tester) async {
    final services = HydrionServices.memory(
      guidedTourRepository: GuidedTourRepository.memory(completed: true),
    );
    final reminder = await services.reminderRepository.save(
      triggerTime: DateTime.now().add(const Duration(hours: 2)),
      message:
          'This long hydration reminder wraps across several lines while its edit and delete actions remain separate, visible, and reachable.',
      priority: 1,
    );
    await services.reminderRepository.setScheduleState(
      id: reminder.id,
      state: ReminderScheduleState.scheduledExactly,
    );
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/reminders',
      textScale: 2,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      services: services,
    );
    final card = find.byKey(Key('reminder-card-${reminder.id}'));
    await revealByScrolling(
      tester,
      target: card,
      scrollView: find.byKey(const Key('reminders-scroll-view')),
    );
    final cardRect = tester.getRect(card);
    for (final action in [
      find.byKey(Key('edit-reminder-${reminder.id}')),
      find.byKey(Key('delete-reminder-${reminder.id}')),
    ]) {
      final actionRect = tester.getRect(action);
      expect(cardRect.contains(actionRect.topLeft), isTrue);
      expect(cardRect.contains(actionRect.bottomRight), isTrue);
    }
    expectNoLayoutFailure(tester);
  });

  testWidgets('Pomodoro setup keeps Join reachable above three-button inset',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/challenges',
      textScale: 1.5,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
    );
    final card = find.byKey(const Key('challenge-card-pomodoro-sip'));
    await revealByScrolling(
      tester,
      target: card,
      scrollView: find.byKey(const Key('challenges-catalog-scroll')),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();

    final join = find.byKey(const Key('activate-challenge-pomodoro-sip'));
    await revealByScrolling(
      tester,
      target: join,
      scrollView: find.byKey(const Key('challenge-scroll-pomodoro-sip')),
    );

    expect(tester.getRect(join).bottom, lessThanOrEqualTo(568 - 48));
    expect(find.text('Required challenge configuration.'), findsNothing);
    expectNoLayoutFailure(tester);
  });

  testWidgets('every challenge setup exposes its final action on compact phone',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/challenges',
      textScale: 1.3,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
    );

    for (final challenge in HydrionChallengeCatalog.challenges) {
      final card = find.byKey(Key('challenge-card-${challenge.id}'));
      await revealByScrolling(
        tester,
        target: card,
        scrollView: find.byKey(const Key('challenges-catalog-scroll')),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      final action = find.byKey(Key('activate-challenge-${challenge.id}'));
      await revealByScrolling(
        tester,
        target: action,
        scrollView: find.byKey(Key('challenge-scroll-${challenge.id}')),
      );
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(568 - 48),
        reason: challenge.name,
      );
      expectNoLayoutFailure(tester, reason: challenge.name);
      Navigator.of(tester.element(action)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'every active challenge keeps progress and settings reachable on compact phone',
      (tester) async {
    for (final challenge in HydrionChallengeCatalog.challenges) {
      final services = HydrionServices.memory(
        guidedTourRepository: GuidedTourRepository.memory(completed: true),
      );
      await services.challengeRepository.join(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        targetMl: challenge.targetMl,
        durationDays: challenge.durationDays,
        parameters: activeParametersFor(challenge.id),
      );
      await pumpHydrion(
        tester,
        size: const Size(320, 568),
        route: '/challenges',
        textScale: 1.3,
        viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
        services: services,
      );

      final card = find.byKey(Key('challenge-card-${challenge.id}'));
      await revealByScrolling(
        tester,
        target: card,
        scrollView: find.byKey(const Key('challenges-catalog-scroll')),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expectNoLayoutFailure(tester, reason: challenge.name);

      if (challenge.id == 'eat-your-water-day') {
        final rule = find.textContaining('Food completion and fluid hydration');
        await revealByScrolling(
          tester,
          target: rule,
          scrollView: find.byKey(Key('challenge-scroll-${challenge.id}')),
        );
        expect(rule, findsOneWidget);
        expect(find.textContaining('No hydration volume will be added'),
            findsNothing);
      }

      final settings =
          find.byKey(Key('challenge-edit-settings-${challenge.id}'));
      await revealByScrolling(
        tester,
        target: settings,
        scrollView: find.byKey(Key('challenge-scroll-${challenge.id}')),
      );
      expect(
        tester.getRect(settings).bottom,
        lessThanOrEqualTo(568 - 48),
        reason: challenge.name,
      );
      expectNoLayoutFailure(tester, reason: challenge.name);
    }
  });

  testWidgets('settings form remains usable with a simulated keyboard',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(360, 640),
      route: '/settings',
      textScale: 1.5,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      viewInsets: const EdgeInsets.only(bottom: 260),
    );
    final field = find.byKey(const Key('settings-daily-goal-field'));
    await revealByScrolling(
      tester,
      target: field,
      scrollView: find.byKey(const Key('settings-scroll-view')),
    );
    await tester.tap(field);
    await tester.pump();
    final save = find.byKey(const Key('settings-daily-goal-save'));
    await revealByScrolling(
      tester,
      target: save,
      scrollView: find.byKey(const Key('settings-scroll-view')),
    );
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(640 - 260));
    expectNoLayoutFailure(tester);
  });

  testWidgets('profile editor keeps Save reachable above the keyboard',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/profile',
      textScale: 1.5,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      viewInsets: const EdgeInsets.only(bottom: 220),
    );
    final edit = find.byKey(const Key('profile-edit-action'));
    await revealByScrolling(
      tester,
      target: edit,
      scrollView: find.byKey(const Key('profile-scroll-view')),
    );
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('profile-save'));
    await revealByScrolling(
      tester,
      target: save,
      scrollView: find.byKey(const Key('profile-editor-list')),
    );
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(568 - 220));
    expectNoLayoutFailure(tester);
  });

  testWidgets('compact onboarding keeps navigation reachable at 2x text',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(320, 568),
      route: '/onboarding',
      textScale: 2,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
    );
    final next = tester.getRect(find.byKey(const Key('onboarding-next')));
    expect(next.bottom, lessThanOrEqualTo(568 - 48));
    expectNoLayoutFailure(tester);
  });

  testWidgets('onboarding input keeps Continue reachable with keyboard open',
      (tester) async {
    await pumpHydrion(
      tester,
      size: const Size(360, 640),
      route: '/onboarding',
      textScale: 1.5,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      viewInsets: const EdgeInsets.only(bottom: 240),
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    final nickname = find.byKey(const Key('onboarding-nickname'));
    await revealByScrolling(
      tester,
      target: nickname,
      scrollView: find.byKey(const Key('onboarding-step-scroll')),
    );
    await tester.tap(nickname);
    await tester.pump();
    final next = tester.getRect(find.byKey(const Key('onboarding-next')));
    expect(next.bottom, lessThanOrEqualTo(640 - 240));
    expectNoLayoutFailure(tester);
  });
}

Map<String, Object?> activeParametersFor(String challengeId) {
  return switch (challengeId) {
    'around-the-world-infusion-week' => <String, Object?>{
        'amountMl': 250,
        'noAddedSugar': 'confirmed',
      },
    'temperature-roulette' => <String, Object?>{
        'amountMl': 250,
        'weatherOrdering': 'disabled',
        'temperatureSchedule': const [
          'Cool',
          'Room temperature',
          'Comfortably warm',
          'Cool',
          'Room temperature',
        ],
      },
    'eat-your-water-day' => <String, Object?>{
        'meal': 'lunch',
        'food': 'cucumber and watermelon',
      },
    'pomodoro-sip' => <String, Object?>{
        'sessionMinutes': 25,
        'sessionsPerDay': 4,
        'amountMl': 150,
        'shortBreakMinutes': 5,
        'notifications': 'disabled',
        'autoStartNext': 'disabled',
        'challengeDurationDays': 5,
        'timerStatus': 'stopped',
      },
    'bottle-bingo' => <String, Object?>{
        'cutoffHour': 12,
        'difficulty': 'balanced',
        'reminderPreference': 'enabled',
        'amountMl': 250,
      },
    _ => <String, Object?>{
        'cue': 'Water the plant and review the reusable bottle station',
      },
  };
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

void expectNoLayoutFailure(
  WidgetTester tester, {
  String? reason,
}) {
  final exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception!);
  }
  expect(
    exceptions,
    isEmpty,
    reason: reason == null
        ? 'No Flutter layout exception was expected.'
        : '$reason should not produce a Flutter layout exception.',
  );
}
