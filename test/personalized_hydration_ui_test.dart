import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/domain/hydration_recommendation.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/body_metrics_screen.dart';
import 'package:provider/provider.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'support/memory_protected_app_store.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Locale locale,
    required HydrionSex sex,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
    bool personalizedBaseline = false,
    DailyHydrationRecommendationCoordinator Function(
            DailyHydrationRecommendationCoordinator)?
        wrapCoordinator,
    BodyMetricsRepository? bodyMetricsRepository,
    DailyHydrationContextRepository? dailyContextRepository,
  }) async {
    final settings = UserSettingsRepository.memory(locale);
    await settings.setProfile(nickname: 'River', age: 30, sex: sex);
    if (personalizedBaseline) {
      await settings.setPersonalizedGoalOptions(
          baselineSource: HydrionBaselineSource.personalized,
          weatherModifierEnabled: true);
    }
    final bodyMetrics = bodyMetricsRepository ?? BodyMetricsRepository.memory();
    final dailyContext =
        dailyContextRepository ?? DailyHydrationContextRepository.memory();
    final state = PersonalizationStateRepository.memory();
    final coordinator = DailyHydrationRecommendationCoordinator(
      settingsRepository: settings,
      bodyMetricsRepository: bodyMetrics,
      dailyContextRepository: dailyContext,
      stateRepository: state,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: bodyMetrics),
          ChangeNotifierProvider.value(value: dailyContext),
          ChangeNotifierProvider.value(value: state),
          Provider<DailyHydrationRecommendationCoordinator>.value(
              value: wrapCoordinator?.call(coordinator) ?? coordinator),
        ],
        child: MaterialApp(
          locale: locale,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          initialRoute: '/metrics',
          routes: {
            '/': (_) => const Scaffold(body: Text('Previous screen')),
            '/metrics': (_) => const BodyMetricsScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['en', 'fr', 'es']) {
    testWidgets(
        'H2 recovered context initializes editor rather than defaults: $locale',
        (tester) async {
      final saved = DailyHydrationContext(
        localDateKey: hydrionLocalDateKey(DateTime.now()),
        activityIntensity: HydrionActivityIntensity.vigorous,
        activityMinutes: 85,
        environment: HydrionEnvironmentExposure.mostlyOutdoors,
        sweatLevel: HydrionSweatLevel.high,
        temporaryCondition: HydrionTemporaryCondition.recovering,
        userAdjustmentMl: 175,
        updatedAt: DateTime.now(),
      );
      final protected = MemoryProtectedAppStore()
        ..record = ProtectedContextRecord(
            revision: 7, phase: ContextRecordPhase.active, contexts: [saved])
        ..readFailure = ProtectedReadStatus.unavailable;
      final daily = await DailyHydrationContextRepository.load(
          MemoryHydrionStore(),
          protectedStore: protected);
      await pumpScreen(tester,
          locale: Locale(locale),
          sex: HydrionSex.female,
          dailyContextRepository: daily);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(BodyMetricsScreen)));
      final coordinator = tester
          .element(find.byType(BodyMetricsScreen))
          .read<DailyHydrationRecommendationCoordinator>();
      expect(
          (await coordinator.calculateResult(now: DateTime.now()))
              .recommendation,
          isNull);
      final scroll = find
          .descendant(
              of: find.byKey(const Key('body-metrics-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
          find.byKey(const Key('retry-daily-context')), 300,
          scrollable: scroll);
      await tester.ensureVisible(find.byKey(const Key('retry-daily-context')));
      await tester.pumpAndSettle();
      protected.readFailure = null;
      await tester.tap(find.byKey(const Key('retry-daily-context')));
      await tester.pumpAndSettle();
      expect(daily.forDate(saved.localDateKey)!.activityMinutes, 85);
      final recommendation = coordinator.stateRepository.latestRecommendation!;
      expect(recommendation.userAdjustmentMl, 175);
      expect(recommendation.activityAdjustmentMl, greaterThan(0));
      expect(recommendation.safetyNotices,
          contains(HydrationFactorCode.illnessGuidance));
      expect(find.text(l10n.dailyContextUnavailable), findsNothing);
      final edit = find.descendant(
          of: find.byKey(const Key('daily-context-summary')),
          matching: find.widgetWithText(OutlinedButton, l10n.edit));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      void expectRecoveredEditor() {
        expect(
            tester
                .state<FormFieldState<HydrionActivityIntensity>>(find
                    .byType(DropdownButtonFormField<HydrionActivityIntensity>))
                .value,
            saved.activityIntensity);
        expect(
            tester
                .state<FormFieldState<HydrionEnvironmentExposure>>(find.byType(
                    DropdownButtonFormField<HydrionEnvironmentExposure>))
                .value,
            saved.environment);
        expect(
            tester
                .state<FormFieldState<HydrionSweatLevel>>(
                    find.byType(DropdownButtonFormField<HydrionSweatLevel>))
                .value,
            saved.sweatLevel);
        expect(
            tester
                .state<FormFieldState<HydrionTemporaryCondition>>(find
                    .byType(DropdownButtonFormField<HydrionTemporaryCondition>))
                .value,
            saved.temporaryCondition);
        expect(
            tester
                .widget<TextField>(find.byKey(const Key('activity-minutes')))
                .controller!
                .text,
            '85');
      }

      expectRecoveredEditor();
      await tester.ensureVisible(find.text(l10n.saveDailyContext));
      await tester.tap(find.text(l10n.saveDailyContext));
      await tester.pumpAndSettle();
      final actual = daily.forDate(saved.localDateKey)!.toJson()
        ..remove('updatedAt');
      expect(actual, saved.toJson()..remove('updatedAt'));
      expect(coordinator.stateRepository.latestRecommendation!.userAdjustmentMl,
          175);
      await tester.pumpWidget(const SizedBox());
      await pumpScreen(tester,
          locale: Locale(locale),
          sex: HydrionSex.female,
          dailyContextRepository: daily);
      await tester.scrollUntilVisible(edit, 300, scrollable: scroll);
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expectRecoveredEditor();
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in ['en', 'fr', 'es']) {
    testWidgets('protected context draft survives failure and retry: $locale',
        (tester) async {
      final protected = MemoryProtectedAppStore();
      final local = MemoryHydrionStore();
      final daily = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      await pumpScreen(tester,
          locale: Locale(locale),
          sex: HydrionSex.female,
          dailyContextRepository: daily);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(BodyMetricsScreen)));
      final scroll = find
          .descendant(
              of: find.byKey(const Key('body-metrics-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
          find.byKey(const Key('set-daily-context')), 300,
          scrollable: scroll);
      await tester.tap(find.byKey(const Key('set-daily-context')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('activity-minutes')));
      await tester.enterText(find.byKey(const Key('activity-minutes')), '47');
      tester
          .widget<DropdownButtonFormField<HydrionActivityIntensity>>(
              find.byType(DropdownButtonFormField<HydrionActivityIntensity>))
          .onChanged!(HydrionActivityIntensity.moderate);
      tester
          .widget<DropdownButtonFormField<HydrionEnvironmentExposure>>(
              find.byType(DropdownButtonFormField<HydrionEnvironmentExposure>))
          .onChanged!(HydrionEnvironmentExposure.mixed);
      tester
          .widget<DropdownButtonFormField<HydrionSweatLevel>>(
              find.byType(DropdownButtonFormField<HydrionSweatLevel>))
          .onChanged!(HydrionSweatLevel.high);
      tester
          .widget<DropdownButtonFormField<HydrionTemporaryCondition>>(
              find.byType(DropdownButtonFormField<HydrionTemporaryCondition>))
          .onChanged!(HydrionTemporaryCondition.fever);
      await tester.pump();
      protected.writeFailure = ProtectedWriteStatus.failed;
      await tester.ensureVisible(find.text(l10n.saveDailyContext));
      await tester.tap(find.text(l10n.saveDailyContext));
      await tester.pumpAndSettle();
      expect(find.text(l10n.dailyContextSaved), findsNothing);
      expect(find.text(l10n.dailyContextNotSaved), findsOneWidget);
      // Only the payload-free authority marker; the failed save adds no
      // plaintext and does not advance the marker.
      expect(
          local.snapshot, {DailyHydrationContextRepository.authorityKey: '1'});
      protected.writeFailure = null;
      tester.state<ScrollableState>(scroll).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(
          find.byKey(const Key('retry-daily-context')), 250,
          scrollable: scroll);
      await tester.tap(find.byKey(const Key('retry-daily-context')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('activity-minutes')))
              .controller!
              .text,
          '47');
      await tester.ensureVisible(find.text(l10n.saveDailyContext));
      await tester.tap(find.text(l10n.saveDailyContext));
      await tester.pumpAndSettle();
      expect(find.text(l10n.dailyContextSaved), findsOneWidget);
      expect(protected.record!.contexts.single.activityMinutes, 47);
      expect(protected.record!.contexts.single.activityIntensity,
          HydrionActivityIntensity.moderate);
      expect(protected.record!.contexts.single.environment,
          HydrionEnvironmentExposure.mixed);
      expect(
          protected.record!.contexts.single.sweatLevel, HydrionSweatLevel.high);
      expect(protected.record!.contexts.single.temporaryCondition,
          HydrionTemporaryCondition.fever);
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in ['en', 'fr', 'es']) {
    testWidgets('secure save failure keeps editor draft and retries: $locale',
        (tester) async {
      final secure = _RetrySaveStore();
      final local = MemoryHydrionStore();
      final body = await BodyMetricsRepository.load(local, secureStore: secure);
      await pumpScreen(tester,
          locale: Locale(locale),
          sex: HydrionSex.female,
          bodyMetricsRepository: body);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(BodyMetricsScreen)));
      await tester.ensureVisible(find.text(l10n.addHeight));
      await tester.tap(find.text(l10n.addHeight));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('manual-height')), '183.5');
      secure.reject = true;
      await tester.tap(find.byKey(const Key('save-height')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.bodyMetricsSaved), findsNothing);
      expect(find.text(l10n.bodyMetricsNotSaved), findsWidgets);
      expect(local.snapshot.toString(), isNot(contains('183.5')));
      secure.reject = false;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('manual-height')))
              .controller!
              .text,
          '183.5');
      await tester.tap(find.byKey(const Key('save-height')));
      await tester.pumpAndSettle();
      expect(body.metrics.heightCm, 183.5);
      expect(find.text(l10n.bodyMetricsSaved), findsOneWidget);
      expect(local.snapshot.toString(), isNot(contains('183.5')));
      expect(tester.takeException(), isNull);
    });
  }

  for (final retry in [false, true]) {
    testWidgets('H1 deletion completion clears sensitive drafts: retry=$retry',
        (tester) async {
      final secure = _RetryDeleteStore()..reject = retry;
      final body = await BodyMetricsRepository.load(MemoryHydrionStore(),
          secureStore: secure);
      await body.save(
          const HydrionBodyMetrics(
            personalizationEnabled: true,
            weightKg: 83,
            heightCm: 183,
            reproductiveState: HydrionReproductiveHydrationState.pregnant,
            pregnancyGestationalDays: 140,
            fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
            clinicianTargetMl: 1850,
            allowAdjustmentsAboveClinicianTarget: true,
          ),
          femaleProfile: true);
      await pumpScreen(tester,
          locale: const Locale('en'),
          sex: HydrionSex.female,
          bodyMetricsRepository: body,
          personalizedBaseline: true);
      final settings = tester
          .element(find.byType(BodyMetricsScreen))
          .read<UserSettingsRepository>();
      final goal = settings.settings.dailyGoalMl;
      Future<void> reveal(String key) async {
        final scroll = find
            .descendant(
                of: find.byKey(const Key('body-metrics-scroll')),
                matching: find.byType(Scrollable))
            .first;
        tester.state<ScrollableState>(scroll).position.jumpTo(0);
        await tester.pump();
        await tester.scrollUntilVisible(find.byKey(Key(key)), 350,
            scrollable: scroll);
        await tester.pumpAndSettle();
      }

      await reveal('review-suggestion');
      await tester.tap(find.byKey(const Key('review-suggestion')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apply-suggested-goal')), findsOneWidget);
      await reveal('delete-body-metrics');
      await tester.tap(find.byKey(const Key('delete-body-metrics')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Delete body metrics'));
      await tester.pumpAndSettle();
      if (retry) {
        expect(find.text('Body metrics deleted.'), findsNothing);
        expect(body.state.status, BodyMetricsStatus.deletionPending);
        secure.reject = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
      expect(body.state.status, BodyMetricsStatus.absent);
      expect(settings.settings.baselineSource, HydrionBaselineSource.manual);
      expect(settings.settings.dailyGoalMl, goal);
      expect(settings.settings.weatherModifierEnabled, isTrue);
      await reveal('review-suggestion');
      expect(find.byKey(const Key('apply-suggested-goal')), findsNothing);
      await reveal('edit-personalization');
      await tester.tap(find.byKey(const Key('edit-personalization')));
      await tester.pumpAndSettle();
      await reveal('reproductive-state');
      expect(
          tester
              .widget<
                      DropdownButtonFormField<
                          HydrionReproductiveHydrationState>>(
                  find.byKey(const Key('reproductive-state')))
              .initialValue,
          HydrionReproductiveHydrationState.none);
      expect(find.byKey(const Key('pregnancy-duration-input')), findsNothing);
      await reveal('fluid-safety-mode');
      expect(
          tester
              .widget<DropdownButtonFormField<HydrionFluidSafetyMode>>(
                  find.byKey(const Key('fluid-safety-mode')))
              .initialValue,
          HydrionFluidSafetyMode.none);
      expect(find.byKey(const Key('clinician-target')), findsNothing);
      tester
          .widget<DropdownButtonFormField<HydrionFluidSafetyMode>>(
              find.byKey(const Key('fluid-safety-mode')))
          .onChanged!(HydrionFluidSafetyMode.clinicianTarget);
      await tester.pumpAndSettle();
      await reveal('clinician-target');
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('clinician-target')))
              .controller!
              .text,
          isEmpty);
      expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isFalse);
      await reveal('fluid-safety-mode');
      tester
          .widget<DropdownButtonFormField<HydrionFluidSafetyMode>>(
              find.byKey(const Key('fluid-safety-mode')))
          .onChanged!(HydrionFluidSafetyMode.none);
      await tester.pumpAndSettle();
      await reveal('reproductive-state');
      tester
          .widget<DropdownButtonFormField<HydrionReproductiveHydrationState>>(
              find.byKey(const Key('reproductive-state')))
          .onChanged!(HydrionReproductiveHydrationState.pregnant);
      await tester.pumpAndSettle();
      await reveal('pregnancy-duration-input');
      expect(
          tester
              .widget<TextField>(
                  find.byKey(const Key('pregnancy-duration-input')))
              .controller!
              .text,
          isEmpty);
      await reveal('reproductive-state');
      tester
          .widget<DropdownButtonFormField<HydrionReproductiveHydrationState>>(
              find.byKey(const Key('reproductive-state')))
          .onChanged!(HydrionReproductiveHydrationState.none);
      await tester.pumpAndSettle();
      await reveal('save-body-metrics');
      await tester.tap(find.byKey(const Key('save-body-metrics')));
      await tester.pumpAndSettle();
      void expectEmpty() {
        expect(body.metrics.weightKg, isNull);
        expect(body.metrics.heightCm, isNull);
        expect(body.metrics.reproductiveState,
            HydrionReproductiveHydrationState.none);
        expect(body.metrics.pregnancyGestationalDays, isNull);
        expect(body.metrics.clinicianTargetMl, isNull);
        expect(body.metrics.fluidSafetyMode, HydrionFluidSafetyMode.none);
        expect(body.metrics.allowAdjustmentsAboveClinicianTarget, isFalse);
        expect(body.metrics.personalizationEnabled, isFalse);
      }

      expectEmpty();
      await tester.pumpWidget(const SizedBox());
      await pumpScreen(tester,
          locale: const Locale('en'),
          sex: HydrionSex.female,
          bodyMetricsRepository: body);
      expectEmpty();
      await reveal('edit-personalization');
      await tester.tap(find.byKey(const Key('edit-personalization')));
      await tester.pumpAndSettle();
      await reveal('reproductive-state');
      expect(
          tester
              .widget<
                      DropdownButtonFormField<
                          HydrionReproductiveHydrationState>>(
                  find.byKey(const Key('reproductive-state')))
              .initialValue,
          HydrionReproductiveHydrationState.none);
      await reveal('fluid-safety-mode');
      expect(
          tester
              .widget<DropdownButtonFormField<HydrionFluidSafetyMode>>(
                  find.byKey(const Key('fluid-safety-mode')))
              .initialValue,
          HydrionFluidSafetyMode.none);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'H1 deletion discards a recommendation delivered after completion',
      (tester) async {
    final body = BodyMetricsRepository.memory(const HydrionBodyMetrics(
        personalizationEnabled: true, weightKg: 83, heightCm: 183));
    late _DelayedCoordinator delayed;
    await pumpScreen(tester,
        locale: const Locale('en'),
        sex: HydrionSex.female,
        bodyMetricsRepository: body,
        wrapCoordinator: (base) => delayed = _DelayedCoordinator(base));
    Future<void> reveal(String key) async {
      final scroll = find
          .descendant(
              of: find.byKey(const Key('body-metrics-scroll')),
              matching: find.byType(Scrollable))
          .first;
      tester.state<ScrollableState>(scroll).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(find.byKey(Key(key)), 350,
          scrollable: scroll);
      await tester.pumpAndSettle();
    }

    await reveal('review-suggestion');
    await tester.tap(find.byKey(const Key('review-suggestion')));
    await tester.pumpAndSettle();
    expect(delayed.captured.isCompleted, isTrue);
    await reveal('delete-body-metrics');
    await tester.tap(find.byKey(const Key('delete-body-metrics')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete body metrics'));
    await tester.pumpAndSettle();
    expect(body.state.status, BodyMetricsStatus.absent);
    delayed.release.complete();
    await tester.pumpAndSettle();
    await reveal('review-suggestion');
    expect(find.byKey(const Key('apply-suggested-goal')), findsNothing);
  });

  testWidgets('failed body deletion never shows success and retry completes',
      (tester) async {
    final secure = _RetryDeleteStore();
    final body = await BodyMetricsRepository.load(MemoryHydrionStore(),
        secureStore: secure);
    await body.save(const HydrionBodyMetrics(weightKg: 70),
        femaleProfile: false);
    await pumpScreen(tester,
        locale: const Locale('en'),
        sex: HydrionSex.male,
        bodyMetricsRepository: body);
    final button = find.byKey(const Key('delete-body-metrics'));
    await tester.scrollUntilVisible(button, 400,
        scrollable: find.descendant(
            of: find.byKey(const Key('body-metrics-scroll')),
            matching: find.byType(Scrollable)));
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete body metrics'));
    await tester.pumpAndSettle();
    expect(find.text('Body metrics deleted.'), findsNothing);
    expect(find.byKey(const Key('body-metrics-unavailable')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-metrics-unavailable')), findsOneWidget);
    expect(tester.takeException(), isNull);
    secure.reject = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-metrics-unavailable')), findsNothing);
    expect(body.state.status, BodyMetricsStatus.absent);
    expect((await secure.readResult()).status, SensitiveBodyReadStatus.absent);
  });

  testWidgets('optional controls support narrow Android and large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
      themeMode: ThemeMode.dark,
      textScale: 1.5,
    );

    expect(find.byKey(const Key('body-metrics-scroll')), findsOneWidget);
    expect(find.byKey(const Key('weight-wheel')), findsNothing);
    expect(find.byKey(const Key('height-wheel')), findsNothing);
    tester
        .widget<TextButton>(
          find.ancestor(
            of: find.text('Add weight'),
            matching: find.byType(TextButton),
          ),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('body-metrics-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight-wheel')), findsOneWidget);
    expect(find.byKey(const Key('height-wheel')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reproductive controls stay hidden for non-female profiles', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.intersex,
    );
    expect(find.byKey(const Key('reproductive-state')), findsNothing);
  });

  testWidgets(
    'pregnancy duration is required, saves, and switches without drift',
    (tester) async {
      final repository = BodyMetricsRepository.memory();
      await pumpScreen(
        tester,
        locale: const Locale('en'),
        sex: HydrionSex.female,
        bodyMetricsRepository: repository,
      );
      expect(find.byKey(const Key('pregnancy-duration-editor')), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('edit-personalization')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('edit-personalization')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('reproductive-state')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('reproductive-state')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pregnant').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('pregnancy-duration-editor')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('save-body-metrics')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save-body-metrics')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('pregnancy-duration-input')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      final durationField = tester.widget<TextField>(
        find.byKey(const Key('pregnancy-duration-input')),
      );
      expect(
        durationField.decoration?.errorText,
        contains('valid pregnancy duration'),
      );
      expect(
        repository.metrics.reproductiveState,
        HydrionReproductiveHydrationState.none,
      );

      await tester.enterText(
        find.byKey(const Key('pregnancy-duration-input')),
        '24',
      );
      await tester.pump();
      expect(find.text('Approximately 24 weeks, 0 days.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-body-metrics')));
      await tester.pumpAndSettle();
      expect(repository.metrics.pregnancyGestationalDays, 168);

      expect(repository.metrics.pregnancyGestationalDays, 168);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved measurements render as summaries until edited', (
    tester,
  ) async {
    final repository = BodyMetricsRepository.memory(
      HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 175,
        weightUpdatedAt: DateTime(2026, 7, 28),
        heightUpdatedAt: DateTime(2026, 7, 29),
      ),
    );
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
      bodyMetricsRepository: repository,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-weight')),
        matching: find.textContaining('70.0 kg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-height')),
        matching: find.textContaining('175 cm'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weight-wheel')), findsNothing);
    expect(find.byKey(const Key('height-wheel')), findsNothing);

    await tester.ensureVisible(find.text('Update weight'));
    await tester.tap(find.text('Update weight'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight-wheel')), findsOneWidget);
    expect(find.byKey(const Key('height-wheel')), findsNothing);
  });

  testWidgets('French and Spanish body-metric consent copy is localized', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      locale: const Locale('fr'),
      sex: HydrionSex.female,
    );
    expect(find.text('Mesures corporelles'), findsWidgets);

    await pumpScreen(
      tester,
      locale: const Locale('es'),
      sex: HydrionSex.female,
    );
    expect(find.text('Medidas corporales'), findsWidgets);
  });

  testWidgets('height editor saves exact metric and imperial values', (
    tester,
  ) async {
    final repository = BodyMetricsRepository.memory();
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
      bodyMetricsRepository: repository,
    );

    await tester.ensureVisible(find.text('Add height'));
    await tester.tap(find.text('Add height'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('manual-height')), '180');
    await tester.tap(find.byKey(const Key('save-height')));
    await tester.pumpAndSettle();
    expect(repository.metrics.heightCm, 180);
    expect(
      repository.metrics.preferredHeightUnit,
      HydrionHeightUnit.centimetres,
    );

    await tester.ensureVisible(find.text('Update height'));
    await tester.tap(find.text('Update height'));
    await tester.pump();
    await tester.tap(find.text('ft and in'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('height-feet')), '5');
    await tester.enterText(find.byKey(const Key('height-inches')), '9');
    await tester.tap(find.byKey(const Key('save-height')));
    await tester.pumpAndSettle();

    expect(repository.metrics.heightCm, closeTo(175.26, 0.001));
    expect(
      repository.metrics.preferredHeightUnit,
      HydrionHeightUnit.feetAndInches,
    );
    expect(find.textContaining('5 ft 9 in'), findsOneWidget);
  });

  testWidgets('suggestion requires review and explicit apply', (tester) async {
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-suggestion')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('review-suggestion')), findsOneWidget);
    expect(find.byKey(const Key('apply-suggested-goal')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('review-suggestion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-suggestion')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('apply-suggested-goal')), findsOneWidget);
  });

  testWidgets('applying a suggestion updates the goal and exits Body Metrics',
      (tester) async {
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-suggestion')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('review-suggestion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-suggested-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggested-goal-yes')));
    await tester.pumpAndSettle();

    expect(find.text('Previous screen'), findsOneWidget);
    expect(find.byType(BodyMetricsScreen), findsNothing);
  });

  testWidgets(
      'wake/sleep schedule shows not-added until configured, then '
      'reflects the saved time', (tester) async {
    // A tall surface keeps the whole scroll body within the sliver cache
    // extent, so every summary tile is actually built and findable without
    // needing to drive ListView scrolling for each assertion.
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = BodyMetricsRepository.memory();
    await pumpScreen(
      tester,
      locale: const Locale('en'),
      sex: HydrionSex.female,
      bodyMetricsRepository: repository,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-wake time')),
        matching: find.text('Add wake time'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-sleep time')),
        matching: find.text('Add sleep time'),
      ),
      findsOneWidget,
    );

    await repository.update(
      wakeMinuteOfDay: 7 * 60,
      sleepMinuteOfDay: 23 * 60,
      femaleProfile: true,
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-wake time')),
        matching: find.text('Update wake time'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-wake time')),
        matching: find.textContaining('7:00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-sleep time')),
        matching: find.text('Update sleep time'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('measurement-summary-sleep time')),
        matching: find.textContaining('11:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'wake/sleep schedule never appears on the weight/height measurement '
    'flow and does not affect the personalized baseline',
    (tester) async {
      final repository = BodyMetricsRepository.memory(
        const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
        ),
      );
      await pumpScreen(
        tester,
        locale: const Locale('en'),
        sex: HydrionSex.female,
        bodyMetricsRepository: repository,
      );

      final beforeBmiText = tester
          .widgetList<Text>(find.textContaining('BMI'))
          .map((t) => t.data)
          .toList();

      await repository.update(
        wakeMinuteOfDay: 22 * 60,
        sleepMinuteOfDay: 6 * 60,
        femaleProfile: true,
      );
      await tester.pumpAndSettle();

      final afterBmiText = tester
          .widgetList<Text>(find.textContaining('BMI'))
          .map((t) => t.data)
          .toList();
      expect(afterBmiText, beforeBmiText);
      expect(repository.metrics.weightKg, 70);
      expect(repository.metrics.heightCm, 170);
    },
  );
}

class _RetrySaveStore extends MemorySensitiveBodyMetricsStore {
  bool reject = false;
  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (reject) throw StateError('synthetic secure write rejection');
    await super.write(fields);
  }
}

class _RetryDeleteStore extends MemorySensitiveBodyMetricsStore {
  bool reject = true;
  @override
  Future<SensitiveBodyDeleteStatus> delete() async =>
      reject ? SensitiveBodyDeleteStatus.failed : await super.delete();
}

class _DelayedCoordinator extends DailyHydrationRecommendationCoordinator {
  final captured = Completer<void>();
  final release = Completer<void>();
  _DelayedCoordinator(DailyHydrationRecommendationCoordinator base)
      : super(
            settingsRepository: base.settingsRepository,
            bodyMetricsRepository: base.bodyMetricsRepository,
            dailyContextRepository: base.dailyContextRepository,
            stateRepository: base.stateRepository);
  @override
  Future<BodyMetricsRecommendationResult> calculateResult(
      {required DateTime now,
      WeatherSnapshot? weather,
      bool locationPermissionGranted = false,
      bool cachedWeatherUsed = false}) async {
    final result = await super.calculateResult(
        now: now,
        weather: weather,
        locationPermissionGranted: locationPermissionGranted,
        cachedWeatherUsed: cachedWeatherUsed);
    captured.complete();
    await release.future;
    return result;
  }
}
