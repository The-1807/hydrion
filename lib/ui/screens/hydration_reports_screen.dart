import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_report.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/hydration_report_export.dart';
import '../../services/hydration_report_pdf.dart';
import '../components/hydrion_viewport.dart';
import '../components/intake_ring.dart';

class HydrationReportsScreen extends StatefulWidget {
  final HydrationReportExporter exporter;
  final DateTime Function() now;

  const HydrationReportsScreen({
    super.key,
    HydrationReportExporter? exporter,
    DateTime Function()? now,
  })  : exporter = exporter ?? const PlatformHydrationReportExporter(),
        now = now ?? DateTime.now;

  @override
  State<HydrationReportsScreen> createState() => _HydrationReportsScreenState();
}

class _HydrationReportsScreenState extends State<HydrationReportsScreen> {
  HydrationReportFrequency _frequency = HydrationReportFrequency.monthly;
  bool _exporting = false;

  HydrationReport _report(BuildContext context) {
    final settings = context.read<UserSettingsRepository>().settings;
    final effectiveAt = settings.weatherAdjustedGoalActive
        ? DateTime.tryParse(settings.lastWeatherGoalLocalDate ?? '')
        : settings.lastManualGoalEditAt;
    return const HydrationReportCalculator().calculate(
      period: HydrationReportPeriod.endingOn(_frequency, widget.now()),
      logs: context.read<HydrationRepository>().logs,
      generatedAt: widget.now(),
      displayLabel: settings.nickname ?? 'Hydrion user',
      targetChanges: effectiveAt == null
          ? const []
          : [
              HydrationReportTargetChange(
                effectiveDate: effectiveAt,
                targetMl: settings.dailyGoalMl,
              ),
            ],
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final settings = context.read<UserSettingsRepository>().settings;
    try {
      final bytes = await const HydrationReportPdfRenderer().render(
        report: _report(context),
        localeName: locale,
        volumeUnit: settings.volumeUnit,
        labels: HydrationReportPdfLabels(
          title: l10n.reportsTitle,
          summary: l10n.reportsDescription,
          period: l10n.reportsPeriod,
          generated: l10n.reportsGenerated,
          frequency: l10n.reportsFrequency,
          frequencyValue: _frequencyLabel(l10n, _frequency),
          total: l10n.reportsTotal,
          average: l10n.reportsAverage,
          trackedDays: l10n.reportsTrackedDays,
          targetsMet: l10n.reportsTargetsMet,
          target: l10n.reportsTarget,
          date: l10n.reportsDate,
          intake: l10n.reportsIntake,
          missing: l10n.reportsMissing,
          unavailable: l10n.reportsUnavailable,
          partial: l10n.reportsPartial,
          empty: l10n.reportsEmpty,
          disclaimer: l10n.reportsDisclaimer,
          page: l10n.reportsPage,
          visualization: l10n.reportsVisualization,
        ),
      );
      final result = await widget.exporter.export(bytes);
      if (!mounted) return;
      final message = switch (result) {
        HydrationReportExportResult.completed => l10n.reportsExported,
        HydrationReportExportResult.dismissed => l10n.reportsDismissed,
        HydrationReportExportResult.unavailable => l10n.reportsExportFailed,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.reportsExportFailed)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    context.watch<HydrationRepository>();
    context.watch<UserSettingsRepository>();
    final report = _report(context);
    final settings = context.read<UserSettingsRepository>().settings;
    final date =
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    String volume(int value) =>
        HydrationVolumeFormatter.format(value, settings.volumeUnit);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: ListView(
        padding: HydrionViewport.scrollPadding(context),
        children: [
          Text(l10n.reportsDescription),
          const SizedBox(height: 16),
          DropdownButtonFormField<HydrationReportFrequency>(
            key: const Key('report-frequency'),
            initialValue: _frequency,
            decoration: InputDecoration(labelText: l10n.reportsFrequency),
            items: HydrationReportFrequency.values
                .map((value) => DropdownMenuItem(
                    value: value, child: Text(_frequencyLabel(l10n, value))))
                .toList(growable: false),
            onChanged: _exporting
                ? null
                : (value) => setState(() => _frequency = value!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.reportsPeriod),
            subtitle: Text(
                '${date.format(report.period.start)} - ${date.format(report.period.end)}'),
          ),
          const Divider(),
          Text(l10n.reportsPreview,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (report.isPartial)
            _Notice(icon: Icons.schedule, text: l10n.reportsPartial),
          if (report.isEmpty)
            _Notice(icon: Icons.water_drop_outlined, text: l10n.reportsEmpty),
          _Metric(
              label: l10n.reportsTotal, value: volume(report.totalRecordedMl)),
          _Metric(
              label: l10n.reportsAverage,
              value: volume(report.averageRecordedMl)),
          _Metric(
              label: l10n.reportsTrackedDays,
              value:
                  '${report.trackedDays}/${report.days.length} (${report.trackedPercent.toStringAsFixed(1)}%)'),
          _Metric(
            label: l10n.reportsTargetsMet,
            value: report.daysWithKnownTarget == 0
                ? l10n.reportsUnavailable
                : '${report.daysTargetMet}/${report.daysWithKnownTarget} (${report.targetMetPercent.toStringAsFixed(1)}%)',
          ),
          const SizedBox(height: 12),
          _HydrationTrendChart(
            graph: report.graph,
            unit: settings.volumeUnit,
            localeName: Localizations.localeOf(context).toLanguageTag(),
            recordedLabel: l10n.reportsIntake,
            targetLabel: l10n.reportsTarget,
            missingLabel: l10n.reportsMissing,
            unavailableLabel: l10n.reportsUnavailable,
          ),
          const SizedBox(height: 8),
          Text(l10n.reportsLegacyTarget,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(l10n.reportsDisclaimer,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('report-export'),
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: Text(l10n.reportsExport),
          ),
        ],
      ),
    );
  }
}

String _frequencyLabel(AppLocalizations l10n, HydrationReportFrequency value) =>
    switch (value) {
      HydrationReportFrequency.weekly => l10n.reportsWeekly,
      HydrationReportFrequency.monthly => l10n.reportsMonthly,
      HydrationReportFrequency.quarterly => l10n.reportsQuarterly,
      HydrationReportFrequency.yearly => l10n.reportsYearly,
    };

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(text),
      );
}

class _HydrationTrendChart extends StatelessWidget {
  final HydrationReportGraph graph;
  final HydrionVolumeUnit unit;
  final String localeName;
  final String recordedLabel;
  final String targetLabel;
  final String missingLabel;
  final String unavailableLabel;

  const _HydrationTrendChart({
    required this.graph,
    required this.unit,
    required this.localeName,
    required this.recordedLabel,
    required this.targetLabel,
    required this.missingLabel,
    required this.unavailableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = DateFormat.MMMd(localeName);
    final semantics = graph.points.map((point) {
      final range = point.start == point.end
          ? date.format(point.start)
          : '${date.format(point.start)}-${date.format(point.end)}';
      final intake = point.recordedMl == null
          ? missingLabel
          : HydrationVolumeFormatter.format(point.recordedMl!, unit);
      final target = point.targetMl == null
          ? unavailableLabel
          : HydrationVolumeFormatter.format(point.targetMl!, unit);
      return '$range: $recordedLabel $intake, $targetLabel $target';
    }).join('. ');
    return Semantics(
      container: true,
      label: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Legend(color: colors.primary, label: recordedLabel),
              const SizedBox(width: 16),
              _Legend(
                color: colors.tertiary,
                label: targetLabel,
                line: true,
              ),
              const SizedBox(width: 16),
              _Legend(
                color: colors.onSurfaceVariant,
                label: missingLabel,
                missing: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            key: const Key('report-trend-chart'),
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _HydrationTrendPainter(
                graph: graph,
                unit: unit,
                localeName: localeName,
                barColor: colors.primary,
                targetColor: colors.tertiary,
                textColor: colors.onSurfaceVariant,
                gridColor: colors.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool missing;
  const _Legend({
    required this.color,
    required this.label,
    this.line = false,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) => Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 12,
              child: CustomPaint(
                painter: _LegendPainter(
                  color: color,
                  line: line,
                  missing: missing,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      );
}

class _LegendPainter extends CustomPainter {
  final Color color;
  final bool line;
  final bool missing;
  const _LegendPainter({
    required this.color,
    required this.line,
    required this.missing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = line || missing ? PaintingStyle.stroke : PaintingStyle.fill;
    if (missing) {
      canvas.drawLine(
          const Offset(4, 2), Offset(size.width - 4, size.height - 2), paint);
      canvas.drawLine(
          Offset(size.width - 4, 2), Offset(4, size.height - 2), paint);
    } else if (line) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
    } else {
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(_LegendPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.line != line ||
      oldDelegate.missing != missing;
}

class _HydrationTrendPainter extends CustomPainter {
  final HydrationReportGraph graph;
  final HydrionVolumeUnit unit;
  final String localeName;
  final Color barColor;
  final Color targetColor;
  final Color textColor;
  final Color gridColor;

  const _HydrationTrendPainter({
    required this.graph,
    required this.unit,
    required this.localeName,
    required this.barColor,
    required this.targetColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0;
    const bottom = 28.0;
    const top = 10.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left;
    final values = graph.points.expand((point) => [
          point.recordedMl ?? 0,
          point.targetMl ?? 0,
        ]);
    final maxMl =
        values.fold<int>(1, (max, value) => value > max ? value : max);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: textColor, fontSize: 9);
    for (var tick = 0; tick <= 2; tick++) {
      final y = top + chartHeight * (1 - tick / 2);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final label =
          HydrationVolumeFormatter.format((maxMl * tick / 2).round(), unit);
      _paintText(canvas, label, Offset(0, y - 6), textStyle,
          maxWidth: left - 4);
    }
    if (graph.points.isEmpty) return;
    final slot = chartWidth / graph.points.length;
    final barPaint = Paint()..color = barColor;
    final targetPaint = Paint()
      ..color = targetColor
      ..strokeWidth = 2;
    final missingPaint = Paint()
      ..color = textColor
      ..strokeWidth = 1.5;
    final labelEvery =
        (graph.points.length / 7).ceil().clamp(1, graph.points.length);
    for (var index = 0; index < graph.points.length; index++) {
      final point = graph.points[index];
      final center = left + slot * (index + 0.5);
      if (point.recordedMl == null) {
        final y = top + chartHeight - 5;
        canvas.drawLine(
            Offset(center - 3, y - 3), Offset(center + 3, y + 3), missingPaint);
        canvas.drawLine(
            Offset(center + 3, y - 3), Offset(center - 3, y + 3), missingPaint);
      } else {
        final height = chartHeight * point.recordedMl! / maxMl;
        final width = (slot * 0.58).clamp(2.0, 20.0);
        canvas.drawRect(
            Rect.fromLTWH(
                center - width / 2, top + chartHeight - height, width, height),
            barPaint);
      }
      if (point.targetMl != null) {
        final y = top + chartHeight * (1 - point.targetMl! / maxMl);
        canvas.drawLine(Offset(center - slot * 0.38, y),
            Offset(center + slot * 0.38, y), targetPaint);
      }
      if (index % labelEvery == 0 || index == graph.points.length - 1) {
        final label = graph.resolution == HydrationGraphResolution.monthly
            ? DateFormat.MMM(localeName).format(point.start)
            : DateFormat.Md(localeName).format(point.start);
        _paintText(canvas, label,
            Offset(center - slot / 2, size.height - bottom + 6), textStyle,
            maxWidth: slot);
      }
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style,
      {required double maxWidth}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_HydrationTrendPainter oldDelegate) =>
      oldDelegate.graph != graph ||
      oldDelegate.unit != unit ||
      oldDelegate.localeName != localeName ||
      oldDelegate.barColor != barColor ||
      oldDelegate.targetColor != targetColor ||
      oldDelegate.textColor != textColor ||
      oldDelegate.gridColor != gridColor;
}
