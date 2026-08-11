import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/ui/screens/body_metrics_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Locale locale,
    required HydrionSex sex,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
    BodyMetricsRepository? bodyMetricsRepository,
  }) async {
    final settings = UserSettingsRepository.memory(locale);
    await settings.setProfile(nickname: 'River', age: 30, sex: sex);
    final bodyMetrics = bodyMetricsRepository ?? BodyMetricsRepository.memory();
    final dailyContext = DailyHydrationContextRepository.memory();
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
          Provider.value(value: coordinator),
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
          home: const BodyMetricsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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
