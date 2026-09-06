import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_report.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/hydration_report_export.dart';
import 'package:hydrion/services/hydration_report_pdf.dart';
import 'package:hydrion/ui/components/intake_ring.dart';
import 'package:hydrion/ui/screens/hydration_reports_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  group('rolling local calendar periods', () {
    test('weekly is today plus the previous six local dates', () {
      final period = HydrationReportPeriod.endingOn(
        HydrationReportFrequency.weekly,
        DateTime(2026, 1, 1, 23, 59),
      );
      expect(period.start, DateTime(2025, 12, 26));
      expect(period.end, DateTime(2026, 1, 1));
      expect(period.dayCount, 7);
    });

    test('month subtraction clamps before selecting the next date', () {
      expect(
          addMonthsClamped(DateTime(2025, 3, 31), -1), DateTime(2025, 2, 28));
      final period = HydrationReportPeriod.endingOn(
        HydrationReportFrequency.monthly,
        DateTime(2025, 3, 31),
      );
      expect(period.start, DateTime(2025, 3, 1));
      expect(period.end, DateTime(2025, 3, 31));
    });

    test('quarter and year use calendar months rather than durations', () {
      final quarter = HydrationReportPeriod.endingOn(
        HydrationReportFrequency.quarterly,
        DateTime(2026, 8, 31),
      );
      expect(quarter.start, DateTime(2026, 6, 1));
      expect(quarter.end, DateTime(2026, 8, 31));
      final year = HydrationReportPeriod.endingOn(
        HydrationReportFrequency.yearly,
        DateTime(2024, 2, 29),
      );
      expect(year.start, DateTime(2023, 3, 1));
      expect(year.end, DateTime(2024, 2, 29));
      expect(year.dayCount, 366);
    });

    test('calendar iteration remains stable across DST boundaries', () {
      final days = calendarDays(DateTime(2026, 3, 6), DateTime(2026, 3, 13));
      expect(days, hasLength(7));
      expect(days.map((day) => day.hour).toSet(), {0});
      expect(days.last, DateTime(2026, 3, 12));
    });

    test('UTC event timestamps are assigned to their actual local date', () {
      final localTimestamp = DateTime(2026, 1, 2, 0, 15);
      final report = _report(
        HydrationReportFrequency.weekly,
        localTimestamp,
        logs: [_log('utc-boundary', 250, localTimestamp.toUtc())],
      );
      expect(
        report.days.singleWhere((day) => day.recordedMl == 250).date,
        localDate(localTimestamp),
      );
    });
  });

  test('empty current window is safely identified as partial', () {
    final report = _report(
      HydrationReportFrequency.monthly,
      DateTime(2026, 8, 12, 10),
    );
    expect(report.isEmpty, isTrue);
    expect(report.isPartial, isTrue);
    expect(report.totalRecordedMl, 0);
    expect(report.graph.recordedTotalMl, 0);
  });

  test('stored events aggregate without filling missing days', () {
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      logs: [
        _log('a', 150, DateTime(2026, 8, 10, 23, 59)),
        _log('b', 350, DateTime(2026, 8, 10)),
      ],
      targets: [
        HydrationReportTargetChange(
          effectiveDate: DateTime(2026, 8, 1),
          targetMl: 500,
        ),
      ],
    );
    expect(report.totalRecordedMl, 500);
    expect(report.trackedDays, 1);
    expect(report.daysTargetMet, 1);
    expect(report.days.where((day) => day.recordedMl == null), hasLength(6));
    expect(report.graph.points.where((point) => point.recordedMl == null),
        hasLength(6));
  });

  test('explicit zero and missing remain distinct in graph data', () {
    final days = [
      HydrationReportDay(
          date: DateTime(2026, 8, 10), recordedMl: 0, targetMl: 2000),
      HydrationReportDay(
          date: DateTime(2026, 8, 11), recordedMl: null, targetMl: 2000),
    ];
    final graph =
        buildHydrationReportGraph(HydrationReportFrequency.weekly, days);
    expect(graph.points.first.recordedMl, 0);
    expect(graph.points.first.trackedDays, 1);
    expect(graph.points.last.recordedMl, isNull);
    expect(graph.points.last.trackedDays, 0);
  });

  test('explicit zero survives canonical repository persistence', () async {
    final repository = HydrationRepository.memory();
    final recorded = await repository.addLog(
      volumeMl: 0,
      timestamp: DateTime(2026, 8, 10, 12),
      source: 'explicit-zero',
    );
    expect(recorded, isNotNull);
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      logs: repository.logs,
    );
    final day = report.days.singleWhere(
      (candidate) => candidate.date == DateTime(2026, 8, 10),
    );
    expect(day.recordedMl, 0);
    expect(day.tracked, isTrue);
    expect(report.trackedDays, 1);
  });

  test('known target changes apply by effective local date', () {
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      targets: [
        HydrationReportTargetChange(
            effectiveDate: DateTime(2026, 8, 1), targetMl: 2000),
        HydrationReportTargetChange(
            effectiveDate: DateTime(2026, 8, 10), targetMl: 2400),
      ],
    );
    expect(report.days[3].targetMl, 2000);
    expect(report.days[4].targetMl, 2400);
  });

  test('partially known targets remain visibly partial in graph data', () {
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      targets: [
        HydrationReportTargetChange(
          effectiveDate: DateTime(2026, 8, 10),
          targetMl: 2400,
        ),
      ],
    );
    expect(
      report.graph.points.take(4).every(
            (point) =>
                point.targetCoverage == HydrationTargetCoverage.unavailable,
          ),
      isTrue,
    );
    expect(
      report.graph.points.skip(4).every(
            (point) => point.targetCoverage == HydrationTargetCoverage.complete,
          ),
      isTrue,
    );
  });

  test('unknown legacy targets are unavailable and never retroactive', () {
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      targets: [
        HydrationReportTargetChange(
            effectiveDate: DateTime(2026, 8, 10), targetMl: 2400),
      ],
    );
    expect(report.days.take(4).every((day) => day.targetMl == null), isTrue);
    expect(report.days.skip(4).every((day) => day.targetMl == 2400), isTrue);
  });

  test('quarterly graph uses chronological seven-day aggregates', () {
    final today = DateTime(2026, 8, 31);
    final period = HydrationReportPeriod.endingOn(
        HydrationReportFrequency.quarterly, today);
    final logs = List.generate(
      period.dayCount,
      (index) => _log(
          'q$index',
          100,
          DateTime(period.start.year, period.start.month,
              period.start.day + index, 12)),
    );
    final report =
        _report(HydrationReportFrequency.quarterly, today, logs: logs);
    expect(report.graph.resolution, HydrationGraphResolution.weekly);
    expect(report.graph.points.first.recordedMl, 700);
    expect(
        report.graph.points.last.start.isAfter(report.graph.points.first.start),
        isTrue);
    expect(report.graph.recordedTotalMl, report.totalRecordedMl);
  });

  test('monthly graph preserves daily ordering and canonical totals', () {
    final report = _report(
      HydrationReportFrequency.monthly,
      DateTime(2026, 8, 31),
      logs: [
        _log('later', 300, DateTime(2026, 8, 20, 12)),
        _log('earlier', 200, DateTime(2026, 8, 2, 12)),
      ],
    );
    expect(report.graph.resolution, HydrationGraphResolution.daily);
    expect(report.graph.points, hasLength(report.period.dayCount));
    expect(report.graph.points.first.start, report.period.start);
    expect(report.graph.points.last.end, report.period.end);
    expect(report.graph.recordedTotalMl, report.totalRecordedMl);
    expect(
      report.graph.points.map((point) => point.start).toList(growable: false),
      orderedEquals(report.days.map((day) => day.date)),
    );
  });

  test('display-unit conversion does not alter canonical graph values', () {
    final report = _report(
      HydrationReportFrequency.weekly,
      DateTime(2026, 8, 12),
      logs: [_log('unit', 1000, DateTime(2026, 8, 12, 12))],
    );
    expect(report.graph.recordedTotalMl, 1000);
    expect(
      HydrationVolumeFormatter.format(
        report.graph.recordedTotalMl,
        HydrionVolumeUnit.ounces,
      ),
      '34 oz',
    );
  });

  test('yearly graph uses bounded chronological calendar-month aggregates', () {
    final report = _report(
      HydrationReportFrequency.yearly,
      DateTime(2026, 8, 31),
      logs: [
        _log('one', 100, DateTime(2025, 9, 1, 12)),
        _log('two', 200, DateTime(2026, 8, 31, 12)),
      ],
    );
    expect(report.graph.resolution, HydrationGraphResolution.monthly);
    expect(report.graph.points.length, lessThanOrEqualTo(12));
    expect(report.graph.recordedTotalMl, 300);
    expect(report.graph.points.first.start, DateTime(2025, 9, 1));
  });

  test('large yearly history remains bounded and reconciled', () {
    final today = DateTime(2026, 8, 31);
    final period =
        HydrationReportPeriod.endingOn(HydrationReportFrequency.yearly, today);
    final logs = <HydrationLog>[];
    for (var day = 0; day < period.dayCount; day++) {
      for (var entry = 0; entry < 48; entry++) {
        logs.add(_log(
          '$day-$entry',
          50,
          DateTime(period.start.year, period.start.month,
              period.start.day + day, entry ~/ 2, (entry % 2) * 30),
        ));
      }
    }
    final stopwatch = Stopwatch()..start();
    final report = _report(HydrationReportFrequency.yearly, today, logs: logs);
    expect(report.graph.points, hasLength(12));
    expect(report.graph.recordedTotalMl, report.totalRecordedMl);
    expect(report.totalRecordedMl, period.dayCount * 2400);
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('PDF consumes canonical graph model for EN ES and FR', () async {
    for (final locale in ['en', 'es', 'fr']) {
      await initializeDateFormatting(locale);
      final bytes = await const HydrationReportPdfRenderer().render(
        report: _report(
          HydrationReportFrequency.monthly,
          DateTime(2026, 8, 31),
          logs: [_log('pdf', 500, DateTime(2026, 8, 30, 12))],
        ),
        labels: _labels,
        localeName: locale,
        volumeUnit: HydrionVolumeUnit.ounces,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    }
  });

  testWidgets('frequency change immediately updates dates and graph',
      (tester) async {
    await tester.pumpWidget(_app(
      now: () => DateTime(2026, 8, 31, 10),
      exporter: _FakeExporter(HydrationReportExportResult.dismissed),
    ));
    expect(find.textContaining('Aug 1, 2026 - Aug 31, 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('report-frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yearly').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 1, 2025 - Aug 31, 2026'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(find.byKey(const Key('report-trend-chart')), findsOneWidget);
  });

  testWidgets('rapid consecutive frequency changes keep the latest report',
      (tester) async {
    await tester.pumpWidget(_app(
      now: () => DateTime(2026, 8, 31, 10),
      exporter: _FakeExporter(HydrationReportExportResult.dismissed),
    ));
    for (final label in ['Weekly', 'Quarterly', 'Yearly']) {
      await tester.tap(find.byKey(const Key('report-frequency')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 1, 2025 - Aug 31, 2026'), findsOneWidget);
    expect(find.textContaining('Aug 25, 2026 - Aug 31, 2026'), findsNothing);
  });

  testWidgets(
      'duplicate export taps produce one request and dismissal is neutral',
      (tester) async {
    final exporter = _BlockingExporter();
    await tester.pumpWidget(
        _app(now: () => DateTime(2026, 8, 31, 10), exporter: exporter));
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('report-export'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    exporter.complete();
    await tester.pumpAndSettle();
    expect(exporter.calls, 1);
    expect(find.text('Sharing was cancelled.'), findsOneWidget);
    expect(find.text('Report shared successfully.'), findsNothing);
  });

  testWidgets('navigation away during export does not update disposed state',
      (tester) async {
    final exporter = _BlockingExporter();
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                    create: (_) => HydrationRepository.memory()),
                ChangeNotifierProvider(
                    create: (_) => UserSettingsRepository.memory()),
              ],
              child: HydrationReportsScreen(
                exporter: exporter,
                now: () => DateTime(2026, 8, 31, 10),
              ),
            ),
          )),
          child: const Text('Open'),
        );
      }),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-export')));
    await tester.pump();
    Navigator.of(tester.element(find.byType(HydrationReportsScreen))).pop();
    await tester.pumpAndSettle();
    exporter.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('export failure is recoverable', (tester) async {
    await tester.pumpWidget(_app(
      now: () => DateTime(2026, 8, 31, 10),
      exporter: _ThrowingExporter(),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-export')));
    await tester.pumpAndSettle();
    expect(find.text('The report could not be exported. Please try again.'),
        findsOneWidget);
    expect(find.byKey(const Key('report-export')), findsOneWidget);
  });
}

HydrationReport _report(
  HydrationReportFrequency frequency,
  DateTime today, {
  List<HydrationLog> logs = const [],
  List<HydrationReportTargetChange> targets = const [],
}) =>
    const HydrationReportCalculator().calculate(
      period: HydrationReportPeriod.endingOn(frequency, today),
      logs: logs,
      generatedAt: today,
      displayLabel: 'Test user',
      targetChanges: targets,
    );

HydrationLog _log(String id, int ml, DateTime timestamp) => HydrationLog(
      id: id,
      volumeMl: ml,
      timestamp: timestamp,
      source: 'test',
    );

Widget _app(
        {required DateTime Function() now,
        required HydrationReportExporter exporter}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HydrationRepository.memory()),
        ChangeNotifierProvider(create: (_) => UserSettingsRepository.memory()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HydrationReportsScreen(exporter: exporter, now: now),
      ),
    );

const _labels = HydrationReportPdfLabels(
  title: 'Hydration report',
  summary: 'Summary',
  period: 'Period',
  generated: 'Generated',
  frequency: 'Frequency',
  frequencyValue: 'Monthly',
  total: 'Total',
  average: 'Average',
  trackedDays: 'Tracked days',
  targetsMet: 'Targets met',
  target: 'Target',
  date: 'Date',
  intake: 'Intake',
  missing: 'No record',
  unavailable: 'Unavailable',
  partial: 'Partial',
  empty: 'No records',
  disclaimer: 'Not medical advice.',
  page: 'Page',
  visualization: 'Progress',
);

class _FakeExporter implements HydrationReportExporter {
  final HydrationReportExportResult result;
  _FakeExporter(this.result);
  @override
  Future<HydrationReportExportResult> export(Uint8List bytes) async => result;
}

class _BlockingExporter implements HydrationReportExporter {
  int calls = 0;
  final _completion = Completer<void>();
  void complete() => _completion.complete();
  @override
  Future<HydrationReportExportResult> export(Uint8List bytes) async {
    calls++;
    await _completion.future;
    return HydrationReportExportResult.dismissed;
  }
}

class _ThrowingExporter implements HydrationReportExporter {
  @override
  Future<HydrationReportExportResult> export(Uint8List bytes) =>
      Future.error(StateError('synthetic export failure'));
}
