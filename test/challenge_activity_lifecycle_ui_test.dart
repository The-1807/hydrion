import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/storage/local_store.dart';

// Regression coverage for HYD-CORR-001: `_ChallengeActivityPanelState`
// accessed `context` from `_syncTicker()` after an `await` gap with no
// `mounted` guard, unlike the sibling `_PomodoroTimerCardState`. Starting,
// pausing, or resuming an activity-type challenge and immediately navigating
// away (before the two awaited persistence calls settle) must not throw.
//
// The underlying store can hold its next write behind an uncompleted
// Completer, standing in for a real SharedPreferences platform-channel
// round-trip so the test can deterministically land a widget disposal in the
// middle of an in-flight persistence `await` without depending on
// `flutter_test`'s virtualized clock.
void main() {
  testWidgets(
    'starting an activity challenge and immediately removing the view '
    'does not throw',
    (tester) async {
      final harness = await _pumpHomeworkHydration(tester);

      harness.store.holdNextWrite();
      await tester.tap(
        find.byKey(const Key('activity-start-homework-hydration')),
      );
      // Do not pump/settle here: the tap's onPressed is now suspended inside
      // the held write. Unmounting the view while that await is still
      // in-flight is exactly the HYD-CORR-001 reproduction.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      harness.store.releaseHold();
      await tester.pump();
      await tester.pump();

      expect(
        harness.store.holdEngagedCount,
        1,
        reason: 'the hold must actually have intercepted a write, or this '
            'test would pass vacuously',
      );
      expect(
        harness.services.challengeRepository
            .activeChallengeFor('homework-hydration')
            ?.parameters['activitySessionStatus'],
        'running',
        reason: 'the held write must have actually resolved and persisted, '
            'or this test would pass vacuously',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pausing a running activity session and immediately removing the view '
    'does not throw',
    (tester) async {
      final harness = await _pumpHomeworkHydration(tester);
      await harness.services.challengeRepository.startActivitySession(
        'homework-hydration',
      );
      await tester.pumpAndSettle();

      harness.store.holdNextWrite();
      await tester.tap(
        find.byKey(const Key('activity-pause-homework-hydration')),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      harness.store.releaseHold();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resuming a paused activity session and immediately removing the view '
    'does not throw',
    (tester) async {
      final harness = await _pumpHomeworkHydration(tester);
      await harness.services.challengeRepository.startActivitySession(
        'homework-hydration',
      );
      await harness.services.challengeRepository.pauseActivitySession(
        'homework-hydration',
      );
      await tester.pumpAndSettle();

      harness.store.holdNextWrite();
      await tester.tap(
        find.byKey(const Key('activity-resume-homework-hydration')),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      harness.store.releaseHold();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'activity ticker is disposed when the challenge view is removed',
    (tester) async {
      final harness = await _pumpHomeworkHydration(tester);
      await harness.services.challengeRepository.startActivitySession(
        'homework-hydration',
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
    },
  );
}

class _Harness {
  _Harness(this.services, this.store);

  final HydrionServices services;
  final _HoldableWriteStore store;
}

Future<_Harness> _pumpHomeworkHydration(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = _HoldableWriteStore(MemoryHydrionStore());
  final services = HydrionServices.memory(
    challengeRepository: await ChallengeRepository.load(store),
  );
  await services.challengeRepository.join(
    id: 'homework-hydration',
    name: 'Homework Hydration',
    description: 'A private study session with deliberate checkpoints.',
    targetMl: 2200,
    durationDays: 7,
    profileAge: 15,
    parameters: const {
      'sessionMinutes': 30,
      'checkpointPattern': 'midpoint',
    },
  );
  await tester.pumpWidget(HydrionApp(services: services));
  await tester.pumpAndSettle();
  tester
      .widget<NavigationBar>(
        find.byKey(const Key('hydrion-bottom-nav')),
      )
      .onDestinationSelected
      ?.call(1);
  await tester.pumpAndSettle();
  final card = find.byKey(const Key('challenge-card-homework-hydration'));
  await revealByScrolling(
    tester,
    target: card,
    scrollView: find.byKey(const Key('challenges-catalog-scroll')),
  );
  await tester.tap(card);
  await tester.pumpAndSettle();
  await revealByScrolling(
    tester,
    target: find.byKey(const Key('activity-start-homework-hydration')),
    scrollView: find.byKey(const Key('challenge-scroll-homework-hydration')),
  );
  return _Harness(services, store);
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

/// Wraps a [HydrionLocalStore] with the ability to hold its very next write
/// behind an uncompleted [Completer], standing in for a real SharedPreferences
/// platform-channel round-trip. Deliberately Completer-based rather than
/// time-based, since `flutter_test` virtualizes timers/`Future.delayed` and a
/// real-time delay would never elapse without independently pumping the fake
/// clock forward.
class _HoldableWriteStore implements HydrionLocalStore {
  _HoldableWriteStore(this._inner);

  final HydrionLocalStore _inner;
  Completer<void>? _hold;
  int holdEngagedCount = 0;

  void holdNextWrite() => _hold = Completer<void>();

  void releaseHold() {
    // Complete (but do not null out) the same Completer instance
    // `_awaitHold` is awaiting — nulling `_hold` happens on this side only,
    // after completion, so the in-flight `await` still resolves.
    _hold?.complete();
    _hold = null;
  }

  Future<void> _awaitHold() async {
    final hold = _hold;
    if (hold == null) return;
    holdEngagedCount++;
    await hold.future;
  }

  @override
  Future<String?> readString(String key) => _inner.readString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _awaitHold();
    await _inner.writeString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _awaitHold();
    await _inner.remove(key);
  }
}
