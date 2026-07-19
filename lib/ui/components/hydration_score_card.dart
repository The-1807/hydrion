import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';
import 'intake_ring.dart';

String hydrationProgressStatus({
  required int todayMl,
  required int targetMl,
  required int entryCount,
  required HydrionVolumeUnit volumeUnit,
  required String emptyStatus,
}) {
  if (entryCount <= 0 || todayMl <= 0) return emptyStatus;
  final amount = HydrationVolumeFormatter.format(todayMl, volumeUnit);
  final logLabel = entryCount == 1 ? 'log' : 'logs';
  final recorded = '$amount recorded across $entryCount $logLabel today.';
  if (todayMl >= targetMl) {
    return 'Daily goal completed. $recorded';
  }
  final remaining = HydrationVolumeFormatter.format(
    (targetMl - todayMl).clamp(0, targetMl),
    volumeUnit,
  );
  return '$recorded $remaining remaining.';
}

class HydrationScoreCard extends StatelessWidget {
  final double hydrationPercent;
  final int entryCount;
  final int? todayMl;
  final int? targetMl;
  final HydrionVolumeUnit volumeUnit;

  const HydrationScoreCard({
    super.key,
    required this.hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    this.todayMl,
    this.targetMl,
    this.volumeUnit = HydrionVolumeUnit.milliliters,
  }) : entryCount = entryCount ?? activityMinutes ?? 0;

  double _score() {
    final hydration =
        hydrationPercent.isFinite ? hydrationPercent.clamp(0.0, 100.0) : 0.0;
    final consistency =
        (entryCount.clamp(0, 4) / 4.0 * 100.0).clamp(0.0, 100.0);
    return ((0.8 * hydration) + (0.2 * consistency)).clamp(0.0, 100.0);
  }

  Color _colorFor(double score) {
    if (score >= 80) {
      return Colors.green.shade600;
    }
    if (score >= 60) {
      return Colors.amber.shade700;
    }
    return Colors.red.shade600;
  }

  String _tip(double score, AppLocalizations l10n) {
    if (score >= 90) {
      return l10n.hydrationTipExcellent;
    }
    if (score >= 80) {
      return l10n.hydrationTipGreat;
    }
    if (score >= 60) {
      return l10n.hydrationTipClose;
    }
    return l10n.hydrationTipStart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = _score();
    final barColor = _colorFor(score);
    final scheme = Theme.of(context).colorScheme;
    final status = todayMl == null || targetMl == null
        ? _tip(score, l10n)
        : hydrationProgressStatus(
            todayMl: todayMl!,
            targetMl: targetMl!,
            entryCount: entryCount,
            volumeUnit: volumeUnit,
            emptyStatus: l10n.hydrationTipStart,
          );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          label: l10n.hydrationScoreSemantics,
          value: l10n.scoreOutOf100(score: score.toStringAsFixed(0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hydrationScoreTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: barColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.scoreSuffix,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MetricChip(
                        icon: Icons.water_drop,
                        label:
                            '${hydrationPercent.clamp(0.0, 100.0).toStringAsFixed(0)}%',
                      ),
                      const SizedBox(width: 6),
                      _MetricChip(
                        icon: Icons.list_alt,
                        label: l10n.logCount(count: entryCount.clamp(0, 24)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 100.0,
                  minHeight: 10,
                  color: barColor,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
