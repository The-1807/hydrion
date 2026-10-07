import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/ui/screens/startup_screen.dart';

/// D2 / owner decision O2: a startup failure must never leave the user on the
/// splash screen. Class (a) failures (services could not be composed) show a
/// localized error screen with Retry; class (b) failures (non-essential
/// post-composition steps) are contained per step and the app routes into a
/// degraded state with a visible notice and Retry.
void main() {
  testWidgets(
      'class (a): composition failure shows a localized error with retry '
      'instead of a stuck splash', (tester) async {
    var attempts = 0;
    final services = HydrionServices.memory();

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: Duration.zero,
        servicesLoader: () async {
          attempts += 1;
          if (attempts == 1) {
            throw const _CompositionFailure();
          }
          return services;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('startup-error')), findsOneWidget);
    expect(find.text("Hydrion couldn't start"), findsOneWidget);
    expect(find.byKey(const Key('startup-retry')), findsOneWidget);
    expect(find.byKey(const Key('hydrion-bottom-nav')), findsNothing);

    await tester.tap(find.byKey(const Key('startup-retry')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const Key('startup-error')), findsNothing);
    expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
  });

  testWidgets('class (a): the startup error screen follows the device locale',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: Duration.zero,
        servicesLoader: () async => throw const _CompositionFailure(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('startup-error')), findsOneWidget);
    expect(find.text("Hydrion n'a pas pu démarrer"), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets(
      'class (b): a failed post-composition step routes into a degraded app '
      'with a visible notice and retry', (tester) async {
    final adapter = _FlakyInitNotificationAdapter();
    final services = HydrionServices.memory(notificationAdapter: adapter);

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: Duration.zero,
        servicesLoader: () async {
          await HydrionServices.runPostCompositionStartup(services);
          return services;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('startup-degraded-notice')), findsOneWidget);
    expect(
      find.textContaining("didn't finish starting"),
      findsOneWidget,
    );

    adapter.failInitialize = false;
    await tester.tap(find.byKey(const Key('startup-degraded-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup-degraded-notice')), findsNothing);
    expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
  });
  test(
      'class (b): each post-composition step is contained; later independent '
      'steps still run and failures are recorded', () async {
    final adapter = _FlakyInitNotificationAdapter();
    final services = HydrionServices.memory(notificationAdapter: adapter);
    final health = services.startupHealth;

    await HydrionServices.runPostCompositionStartup(services);

    expect(
      health.outcomeFor('notification_init'),
      HydrionStartupStepOutcome.failed,
    );
    expect(
      health.results
          .singleWhere((result) => result.id == 'notification_init')
          .errorType,
      '_NotificationInitFailure',
    );
    expect(
      health.outcomeFor('notification_reconcile_schedules'),
      HydrionStartupStepOutcome.skippedDependencyFailed,
    );
    for (final id in const [
      'permissions_refresh',
      'pomodoro_reconcile',
      'homework_timed_notification',
      'android_widget_init',
      'watch_connectivity_init',
    ]) {
      expect(
        health.outcomeFor(id),
        HydrionStartupStepOutcome.succeeded,
        reason: id,
      );
    }
    // The permissions refresh after the failed step really ran.
    expect(
      services.permissions.snapshot.refreshedAt,
      isNot(DateTime.fromMillisecondsSinceEpoch(0)),
    );
    expect(health.isDegraded, isTrue);
    expect(health.incompleteStepIds, [
      'notification_init',
      'notification_reconcile_schedules',
    ]);

    adapter.failInitialize = false;
    await health.retry();

    expect(health.isDegraded, isFalse);
    expect(adapter.initialized, isTrue);
    expect(
      health.outcomeFor('notification_reconcile_schedules'),
      HydrionStartupStepOutcome.succeeded,
    );
  });

  testWidgets(
      'StartupScreen shows retry on warm-up failure and routes after '
      'a successful retry', (tester) async {
    var attempts = 0;
    String? selectedRoute;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupScreen(
          warmUp: () async {
            attempts += 1;
            if (attempts == 1) throw const _CompositionFailure();
          },
          isOnboardingCompleted: () => true,
          onRouteSelected: (route) => selectedRoute = route,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('startup-error')), findsOneWidget);
    expect(selectedRoute, isNull);

    await tester.tap(find.byKey(const Key('startup-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(attempts, 2);
    expect(selectedRoute, '/home');
  });
  testWidgets('degraded notice fits a 320 px phone in every enabled locale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final health = HydrionStartupHealth();
    await health.run([
      HydrionStartupStep(
        'failing',
        () async => throw const _NotificationInitFailure(),
      ),
    ]);
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              StartupDegradedNotice(health: health, child: child!),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('startup-degraded-notice')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }

    await tester.tap(find.byKey(const Key('startup-degraded-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startup-degraded-notice')), findsNothing);
  });
}

class _CompositionFailure implements Exception {
  const _CompositionFailure();
}

class _FlakyInitNotificationAdapter extends FakeHydrionNotificationAdapter {
  bool failInitialize = true;

  @override
  Future<void> initialize() async {
    if (failInitialize) {
      throw const _NotificationInitFailure();
    }
    await super.initialize();
  }
}

class _NotificationInitFailure implements Exception {
  const _NotificationInitFailure();
}
