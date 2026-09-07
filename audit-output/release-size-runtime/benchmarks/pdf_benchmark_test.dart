import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_report.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/hydration_report_pdf.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('measures synthetic PDF output and repeated host memory', () async {
    await initializeDateFormatting('en');
    final results = <Map<String, Object?>>[];
    for (final frequency in HydrationReportFrequency.values) {
      results.add(await _benchmarkFrequency(frequency));
    }
    final output = File(
      'audit-output/release-size-runtime/analysis/pdf-benchmark.json',
    );
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'dataClass': 'synthetic-only',
            'platform': Platform.operatingSystem,
            'memoryScope': 'host process RSS; not Android device memory',
            'frequencies': results,
          })}\n',
    );
    expect(results, hasLength(4));
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<Map<String, Object?>> _benchmarkFrequency(
  HydrationReportFrequency frequency,
) async {
  final today = DateTime(2026, 8, 31);
  final period = HydrationReportPeriod.endingOn(frequency, today);
  final days = <HydrationReportDay>[
    for (final date in calendarDays(period.start, period.endExclusive))
      HydrationReportDay(
        date: date,
        recordedMl: 2000 + (date.day % 5) * 100,
        targetMl: 2200,
      ),
  ];
  final report = HydrationReport(
    period: period,
    generatedAt: DateTime(2026, 8, 31, 12),
    displayLabel: 'Synthetic Hydrion user',
    days: days,
    graph: buildHydrationReportGraph(frequency, days),
  );
  const renderer = HydrationReportPdfRenderer();
  final durations = <int>[];
  final rssSamples = <int>[ProcessInfo.currentRss];
  Uint8List? finalBytes;
  for (var run = 0; run < 10; run++) {
    final watch = Stopwatch()..start();
    finalBytes = await renderer.render(
      report: report,
      localeName: 'en',
      volumeUnit: HydrionVolumeUnit.milliliters,
      labels: _labels,
    );
    watch.stop();
    durations.add(watch.elapsedMicroseconds);
    rssSamples.add(ProcessInfo.currentRss);
  }
  final output = File(
    'audit-output/release-size-runtime/analysis/'
    'synthetic-${frequency.name}-report.pdf',
  );
  output.writeAsBytesSync(finalBytes!);
  final pdfText = latin1.decode(finalBytes);
  final pageCountMatch = RegExp(r'/Count\s+(\d+)').firstMatch(pdfText);
  final pageCount = int.parse(pageCountMatch!.group(1)!);
  return {
    'frequency': frequency.name,
    'rows': days.length,
    'runs': 10,
    'pdfBytes': finalBytes.length,
    'pages': pageCount,
    'generationUs': durations,
    'rssSamples': rssSamples,
    'rssStart': rssSamples.first,
    'rssHighestSample': rssSamples.reduce((a, b) => a > b ? a : b),
    'rssEnd': rssSamples.last,
    'processMaxRss': ProcessInfo.maxRss,
    'sha256UnavailableInDartHarness': true,
  };
}

const _labels = HydrationReportPdfLabels(
  title: 'Hydration progress report',
  summary: 'Synthetic user-tracked hydration summary',
  period: 'Period',
  generated: 'Generated',
  frequency: 'Frequency',
  frequencyValue: 'Synthetic benchmark',
  total: 'Total',
  average: 'Average',
  trackedDays: 'Tracked days',
  targetsMet: 'Targets met',
  target: 'Target',
  date: 'Date',
  intake: 'Intake',
  missing: 'Missing',
  unavailable: 'Unavailable',
  partial: 'Partial period',
  empty: 'No tracked hydration records',
  disclaimer: 'Synthetic data. Not medical advice.',
  page: 'Page',
  visualization: 'Hydration visualization',
);
