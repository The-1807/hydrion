import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/ui/components/intake_ring.dart';

void main() {
  Future<void> pumpGauge(
    WidgetTester tester, {
    required double consumedMl,
    required double targetMl,
    HydrionVolumeUnit unit = HydrionVolumeUnit.milliliters,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HydrationProgressGauge(
              consumedMl: consumedMl,
              targetMl: targetMl,
              volumeUnit: unit,
              animate: Duration.zero,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('gauge is clear at 0 percent', (tester) async {
    await pumpGauge(tester, consumedMl: 0, targetMl: 2200);

    expect(find.byKey(const Key('hydration-progress-gauge')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 ml / 2200 ml'), findsOneWidget);
    expect(find.text('Daily progress'), findsOneWidget);
  });

  testWidgets('gauge renders partial progress', (tester) async {
    await pumpGauge(tester, consumedMl: 1100, targetMl: 2200);

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1100 ml / 2200 ml'), findsOneWidget);
  });

  testWidgets('gauge renders 100 percent without overflow messaging',
      (tester) async {
    await pumpGauge(tester, consumedMl: 2200, targetMl: 2200);

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('2200 ml / 2200 ml'), findsOneWidget);
    expect(find.text('Goal reached'), findsOneWidget);
  });

  testWidgets('gauge clamps visible arc but shows actual over-goal intake',
      (tester) async {
    await pumpGauge(tester, consumedMl: 2600, targetMl: 2200);

    expect(find.text('118%'), findsOneWidget);
    expect(find.text('2600 ml / 2200 ml'), findsOneWidget);
    expect(find.text('Over goal, ease up'), findsOneWidget);
  });

  testWidgets('gauge supports ounce display', (tester) async {
    await pumpGauge(
      tester,
      consumedMl: 500,
      targetMl: 2200,
      unit: HydrionVolumeUnit.ounces,
    );

    expect(find.text('23%'), findsOneWidget);
    expect(find.text('17 oz / 74 oz'), findsOneWidget);
  });

  testWidgets('gauge handles missing or corrupted goal data safely',
      (tester) async {
    await pumpGauge(tester, consumedMl: 500, targetMl: double.nan);

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('500 ml / 0 ml'), findsOneWidget);
    expect(find.text('Set a daily goal'), findsOneWidget);
  });

  testWidgets('gauge exposes an accurate accessibility label', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpGauge(tester, consumedMl: 500, targetMl: 2200);

    final node = tester.getSemantics(
      find.byKey(const Key('hydration-progress-gauge-semantics')),
    );
    expect(node.label, contains('Hydration progress gauge, 23 percent'));
    expect(node.label, contains('500 ml consumed of 2200 ml daily goal'));
    semantics.dispose();
  });
}
