import 'package:flutter/material.dart';

/// HydrationScoreCard — simple composite score with color gradient and tips.
/// Score formula (bounded 0..100):
///   70% hydrationPercent + 30% activityFactor(0..100)
/// activityFactor scales 0..60 min -> 0..100 (capped)
class HydrationScoreCard extends StatelessWidget {
  final double hydrationPercent; // 0..100
  final int activityMinutes;     // minutes today

  const HydrationScoreCard({
    super.key,
    required this.hydrationPercent,
    required this.activityMinutes,
  });

  double _score() {
    final hp = hydrationPercent.isFinite ? hydrationPercent.clamp(0, 100) : 0.0;
    final act = activityMinutes.isFinite ? activityMinutes : 0;
    final actFactor = (act / 60.0 * 100.0).clamp(0.0, 100.0);
    final s = (0.7 * hp) + (0.3 * actFactor);
    return s.clamp(0.0, 100.0);
  }

  Color _colorFor(BuildContext ctx, double score) {
    // Map 0..100 to red -> amber -> green
    final cs = Theme.of(ctx).colorScheme;
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  String _tip(double s) {
    if (s >= 90) return 'Elite hydration rhythm—keep the streak alive.';
    if (s >= 80) return 'Great pace. Maintain consistent sips through the afternoon.';
    if (s >= 60) return 'You’re close. Add a bottle in the next hour to push over the top.';
    return 'Start with a solid 300–500 ml now and set a reminder.';
  }

  @override
  Widget build(BuildContext context) {
    final s = _score();
    final barColor = _colorFor(context, s);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          label: 'Hydration score',
          value: '${s.toStringAsFixed(0)} out of 100',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hydration Score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    s.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text('/ 100', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  _MetricChip(
                    icon: Icons.water_drop,
                    label: '${hydrationPercent.clamp(0, 100).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(width: 6),
                  _MetricChip(
                    icon: Icons.directions_run,
                    label: '${activityMinutes.clamp(0, 180)} min',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: s / 100.0,
                  minHeight: 10,
                  color: barColor,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _tip(s),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
