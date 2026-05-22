import 'dart:math' as math;
import 'package:flutter/material.dart';

/// IntakeRing — animated circular progress ring for hydration intake.
/// - Handles target == 0 safely
/// - Smoothly animates to new values
/// - Center text shows % and bottom shows "X / Y ml"
/// - Accessible semantics and RTL-aware (via inherited Directionality)
class IntakeRing extends StatefulWidget {
  final double consumedMl;
  final double targetMl;
  final double size;        // outer diameter
  final double stroke;      // ring thickness
  final Duration animate;   // animation duration

  const IntakeRing({
    super.key,
    required this.consumedMl,
    required this.targetMl,
    this.size = 160,
    this.stroke = 12,
    this.animate = const Duration(milliseconds: 700),
  });

  @override
  State<IntakeRing> createState() => _IntakeRingState();
}

class _IntakeRingState extends State<IntakeRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _tween;
  double _lastPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.animate);
    _tween = Tween<double>(begin: 0, end: _percent).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    _lastPercent = _percent;
  }

  double get _percent {
    final t = widget.targetMl <= 0 ? 0.0 : (widget.consumedMl / widget.targetMl);
    if (t.isNaN || !t.isFinite) return 0.0;
    return t.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant IntakeRing old) {
    super.didUpdateWidget(old);
    final next = _percent;
    _tween = Tween<double>(begin: _lastPercent, end: next).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl
      ..duration = widget.animate
      ..forward(from: 0);
    _lastPercent = next;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    final consumed = widget.consumedMl.isFinite ? widget.consumedMl : 0.0;
    final target = widget.targetMl > 0 ? widget.targetMl : 0.0;

    return Semantics(
      label: 'Hydration progress ring',
      value: '${(_percent * 100).round()} percent',
      hint: 'Consumed ${consumed.toInt()} of ${target.toInt()} milliliters',
      child: SizedBox(
        width: widget.size,
        height: widget.size + 24, // extra room for bottom label
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _tween,
              builder: (_, __) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  progress: _tween.value,
                  stroke: widget.stroke,
                  trackColor: Theme.of(context).colorScheme.surfaceVariant,
                  gradient: SweepGradient(
                    startAngle: -math.pi / 2,
                    endAngle: 3 * math.pi / 2,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Center percentage
            Positioned.fill(
              child: Center(
                child: Text(
                  '${(_percent * 100).round()}%',
                  textAlign: TextAlign.center,
                  textDirection: dir,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
            // Bottom consumed/target label
            Positioned(
              bottom: 0,
              child: Text(
                '${consumed.toInt()} / ${target.toInt()} ml',
                textAlign: TextAlign.center,
                textDirection: dir,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final double stroke;
  final Color trackColor;
  final Gradient gradient;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      track,
    );

    // Progress arc
    final sweep = (2 * math.pi) * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.trackColor != trackColor ||
      old.gradient != gradient;
}
