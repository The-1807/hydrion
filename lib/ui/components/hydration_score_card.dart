import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HydrationScoreCard extends StatelessWidget {
  final double hydrationPercent;
  final int entryCount;

  const HydrationScoreCard({
    super.key,
    required this.hydrationPercent,
    int? entryCount,
    int? activityMinutes,
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
              Row(
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.scoreSuffix,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
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
                _tip(score, l10n),
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
