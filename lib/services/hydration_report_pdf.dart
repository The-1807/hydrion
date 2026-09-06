import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/hydration_report.dart';
import '../repositories/settings_repository.dart';
import '../ui/components/intake_ring.dart';

class HydrationReportPdfLabels {
  final String title;
  final String summary;
  final String period;
  final String generated;
  final String frequency;
  final String frequencyValue;
  final String total;
  final String average;
  final String trackedDays;
  final String targetsMet;
  final String target;
  final String date;
  final String intake;
  final String missing;
  final String unavailable;
  final String partial;
  final String empty;
  final String disclaimer;
  final String page;
  final String visualization;

  const HydrationReportPdfLabels({
    required this.title,
    required this.summary,
    required this.period,
    required this.generated,
    required this.frequency,
    required this.frequencyValue,
    required this.total,
    required this.average,
    required this.trackedDays,
    required this.targetsMet,
    required this.target,
    required this.date,
    required this.intake,
    required this.missing,
    required this.unavailable,
    required this.partial,
    required this.empty,
    required this.disclaimer,
    required this.page,
    required this.visualization,
  });
}

class HydrationReportPdfRenderer {
  const HydrationReportPdfRenderer();

  Future<Uint8List> render({
    required HydrationReport report,
    required HydrationReportPdfLabels labels,
    required String localeName,
    required HydrionVolumeUnit volumeUnit,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final document = pw.Document(
      title: labels.title,
      author: 'Hydrion',
      creator: 'Hydrion local report generator',
      subject: labels.summary,
    );
    final date = DateFormat.yMMMd(localeName);
    String volume(int value) =>
        HydrationVolumeFormatter.format(value, volumeUnit);
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 44, 36, 44),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('HYDRION',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(report.displayLabel),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
                child: pw.Text(labels.disclaimer,
                    style: const pw.TextStyle(fontSize: 7))),
            pw.SizedBox(width: 12),
            pw.Text(
                '${labels.page} ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        build: (context) => [
          pw.Text(labels.title,
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              '${labels.period}: ${date.format(report.period.start)} - ${date.format(report.period.end)}'),
          pw.Text(
              '${labels.generated}: ${DateFormat.yMMMd(localeName).add_jm().format(report.generatedAt)}'),
          pw.Text('${labels.frequency}: ${labels.frequencyValue}'),
          if (report.isPartial)
            pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(labels.partial,
                    style: const pw.TextStyle(color: PdfColors.orange800))),
          pw.SizedBox(height: 18),
          pw.Wrap(spacing: 8, runSpacing: 8, children: [
            _metric(labels.total, volume(report.totalRecordedMl)),
            _metric(labels.average, volume(report.averageRecordedMl)),
            _metric(labels.trackedDays,
                '${report.trackedDays}/${report.days.length} (${report.trackedPercent.toStringAsFixed(1)}%)'),
            _metric(
                labels.targetsMet,
                report.daysWithKnownTarget == 0
                    ? labels.unavailable
                    : '${report.daysTargetMet}/${report.daysWithKnownTarget} (${report.targetMetPercent.toStringAsFixed(1)}%)'),
          ]),
          pw.SizedBox(height: 18),
          if (!report.isEmpty) ...[
            pw.Text(labels.visualization,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _chart(report, localeName, volumeUnit, labels),
            pw.SizedBox(height: 18),
          ],
          if (report.isEmpty)
            pw.Container(
                padding: const pw.EdgeInsets.all(14),
                color: PdfColors.blueGrey50,
                child: pw.Text(labels.empty)),
          pw.TableHelper.fromTextArray(
            headers: [labels.date, labels.intake, labels.target],
            data: report.days
                .map((day) => [
                      date.format(day.date),
                      day.recordedMl == null
                          ? labels.missing
                          : volume(day.recordedMl!),
                      day.targetMl == null
                          ? labels.unavailable
                          : volume(day.targetMl!),
                    ])
                .toList(growable: false),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _metric(String label, String value) => pw.Container(
        width: 235,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blueGrey200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 3),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ]),
      );

  pw.Widget _chart(
    HydrationReport report,
    String localeName,
    HydrionVolumeUnit volumeUnit,
    HydrationReportPdfLabels labels,
  ) {
    final points = report.graph.points;
    final maxValue = points
        .expand((point) => [
              point.recordedMl ?? 0,
              point.targetMl ?? 0,
            ])
        .fold<int>(
          1,
          (value, item) => item > value ? item : value,
        );
    String volume(int value) =>
        HydrationVolumeFormatter.format(value, volumeUnit);
    String pointLabel(HydrationGraphPoint point) =>
        report.graph.resolution == HydrationGraphResolution.monthly
            ? DateFormat.MMM(localeName).format(point.start)
            : DateFormat.Md(localeName).format(point.start);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Wrap(spacing: 14, children: [
          pw.Text('[ ] ${labels.intake}',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text('-- ${labels.target}',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text('x ${labels.missing}',
              style: const pw.TextStyle(fontSize: 8)),
        ]),
        pw.SizedBox(height: 4),
        pw.Text('${volume(maxValue)}  |',
            style: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(
          height: 88,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final point in points)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          child: pw.Stack(
                            children: [
                              pw.Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: point.recordedMl == null
                                    ? pw.Text(
                                        'x',
                                        textAlign: pw.TextAlign.center,
                                        style: const pw.TextStyle(fontSize: 9),
                                      )
                                    : pw.Container(
                                        height:
                                            62 * point.recordedMl! / maxValue,
                                        color: PdfColors.cyan600,
                                      ),
                              ),
                              if (point.targetMl != null)
                                pw.Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 62 * point.targetMl! / maxValue,
                                  child: pw.Container(
                                    height: 1.5,
                                    color: PdfColors.orange700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          pointLabel(point),
                          maxLines: 1,
                          style: const pw.TextStyle(fontSize: 5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        pw.Text('0 ${volumeUnit == HydrionVolumeUnit.ounces ? 'fl oz' : 'ml'}',
            style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }
}
