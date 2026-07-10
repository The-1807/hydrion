import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../repositories/settings_repository.dart';

class HydrationVolumeFormatter {
  static const double _mlPerOunce = 29.5735295625;

  const HydrationVolumeFormatter._();

  static String format(num volumeMl, HydrionVolumeUnit unit) {
    final safeMl = volumeMl.isFinite ? math.max(0, volumeMl.toDouble()) : 0.0;
    return switch (unit) {
      HydrionVolumeUnit.milliliters => '${safeMl.round()} ml',
      HydrionVolumeUnit.ounces => '${_formatOunces(safeMl / _mlPerOunce)} oz',
    };
  }

  static String _formatOunces(double value) {
    if (value >= 10 || value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class HydrationProgressGauge extends StatefulWidget {
  final double consumedMl;
  final double targetMl;
  final HydrionVolumeUnit volumeUnit;
  final double width;
  final double height;
  final double stroke;
  final int segments;
  final bool onDarkBackground;
  final Duration animate;

  const HydrationProgressGauge({
    super.key,
    required this.consumedMl,
    required this.targetMl,
    required this.volumeUnit,
    this.width = 280,
    this.height = 172,
    this.stroke = 14,
    this.segments = 18,
    this.onDarkBackground = false,
    this.animate = const Duration(milliseconds: 520),
  });

  @override
  State<HydrationProgressGauge> createState() => _HydrationProgressGaugeState();
}

class _HydrationProgressGaugeState extends State<HydrationProgressGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  double _lastVisibleProgress = 0.0;

  double get _visibleProgress => _safeRatio.clamp(0.0, 1.0);

  double get _safeRatio {
    final consumed = _safeConsumed;
    final target = _safeTarget;
    if (target <= 0) {
      return 0.0;
    }
    final ratio = consumed / target;
    if (!ratio.isFinite || ratio.isNaN) {
      return 0.0;
    }
    return ratio;
  }

  double get _safeConsumed {
    return widget.consumedMl.isFinite ? math.max(0, widget.consumedMl) : 0.0;
  }

  double get _safeTarget {
    return widget.targetMl.isFinite ? math.max(0, widget.targetMl) : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animate);
    _lastVisibleProgress = _visibleProgress;
    _progress = Tween<double>(begin: 0, end: _visibleProgress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HydrationProgressGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _visibleProgress;
    _progress = Tween<double>(
      begin: _lastVisibleProgress,
      end: next,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..duration = widget.animate
      ..forward(from: 0);
    _lastVisibleProgress = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (_visibleProgress * 100).round();
    final actualPercent = (_safeRatio * 100).round();
    final consumedLabel = HydrationVolumeFormatter.format(
      _safeConsumed,
      widget.volumeUnit,
    );
    final goalLabel = HydrationVolumeFormatter.format(
      _safeTarget,
      widget.volumeUnit,
    );
    final overGoal = _safeTarget > 0 && _safeConsumed > _safeTarget;
    final invalidGoal = _safeTarget <= 0;
    final foreground =
        widget.onDarkBackground ? Colors.white : scheme.onSurface;
    final muted = widget.onDarkBackground
        ? Colors.white.withValues(alpha: 0.76)
        : scheme.onSurfaceVariant;
    final track = widget.onDarkBackground
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.surfaceContainerHighest;
    final fill = overGoal
        ? scheme.tertiary
        : widget.onDarkBackground
            ? Colors.white
            : scheme.primary;
    final status = invalidGoal
        ? 'Set a daily goal'
        : overGoal
            ? 'Over goal, ease up'
            : percent >= 100
                ? 'Goal reached'
                : 'Daily progress';
    final semanticsLabel = 'Hydration progress gauge, $actualPercent percent. '
        '$consumedLabel consumed of $goalLabel daily goal. $status.';

    return Semantics(
      key: const Key('hydration-progress-gauge-semantics'),
      label: semanticsLabel,
      value: '$actualPercent percent',
      child: SizedBox(
        key: const Key('hydration-progress-gauge'),
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _SegmentedGaugePainter(
                      progress: _progress.value,
                      stroke: widget.stroke,
                      trackColor: track,
                      fillColor: fill,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: widget.height * 0.34,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$actualPercent%',
                    key: const Key('hydration-gauge-percent'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          height: 0.96,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$consumedLabel / $goalLabel',
                    key: const Key('home-progress-text'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    key: const Key('hydration-gauge-status'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedGaugePainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color trackColor;
  final Color fillColor;

  const _SegmentedGaugePainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(
      (size.width - stroke) / 2,
      size.height - stroke,
    );
    final center = Offset(size.width / 2, size.height - stroke / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi;
    const totalSweep = math.pi;
    final normalized = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fillColor;

    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);
    if (normalized > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        totalSweep * normalized,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stroke != stroke ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class IntakeRing extends StatelessWidget {
  final double consumedMl;
  final double targetMl;
  final double size;
  final double stroke;
  final Duration animate;

  const IntakeRing({
    super.key,
    required this.consumedMl,
    required this.targetMl,
    this.size = 160,
    this.stroke = 12,
    this.animate = const Duration(milliseconds: 520),
  });

  @override
  Widget build(BuildContext context) {
    return HydrationProgressGauge(
      consumedMl: consumedMl,
      targetMl: targetMl,
      volumeUnit: HydrionVolumeUnit.milliliters,
      width: size,
      height: size * 0.64,
      stroke: stroke,
      animate: animate,
    );
  }
}
