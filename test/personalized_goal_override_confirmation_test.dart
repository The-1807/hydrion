import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/ui/components/personalized_goal_override_confirmation.dart';

void main() {
  Future<void> pumpConfirmation(
    WidgetTester tester, {
    required Locale locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => confirmPersonalizedGoalOverride(
              context,
              settings: UserSettings(
                locale: locale,
                dailyGoalMl: 2400,
                baselineDailyGoalMl: 2200,
                baselineSource: HydrionBaselineSource.personalized,
              ),
              proposedGoalMl: 2500,
            ),
            child: const Text('Edit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
  }

  testWidgets('personalized manual override can be cancelled', (tester) async {
    await pumpConfirmation(tester, locale: const Locale('en'));
    expect(find.textContaining('calculated personalized baseline'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('manual-goal-override-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('override warning is localized in French and Spanish',
      (tester) async {
    await pumpConfirmation(tester, locale: const Locale('fr'));
    expect(find.textContaining('référence personnalisée'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manual-goal-override-cancel')));
    await tester.pumpAndSettle();

    await pumpConfirmation(tester, locale: const Locale('es'));
    expect(find.textContaining('referencia personalizada'), findsOneWidget);
  });
}
