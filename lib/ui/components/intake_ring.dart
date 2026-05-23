import 'dart:math' as math;

import 'package:flutter/material.dart';

class IntakeRing extends StatefulWidget {
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
    this.animate = const Duration(milliseconds: 700),
  });

  @override
  State<IntakeRing> createState() => _IntakeRingState();
}

class _IntakeRingState extends State<IntakeRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  double _lastPercent = 0.0;

  double get _percent {
    final target =
        widget.targetMl <= 0 ? 0.0 : widget.consumedMl / widget.targetMl;
    if (target.isNaN || !target.isFinite) {
      return 0.0;
    }
    return target.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animate);
    _progress = Tween<double>(begin: 0, end: _percent).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _lastPercent = _percent;
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant IntakeRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _percent;
    _progress = Tween<double>(begin: _lastPercent, end: next).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..duration = widget.animate
      ..forward(from: 0);
    _lastPercent = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consumed = widget.consumedMl.isFinite ? widget.consumedMl : 0.0;
    final target = widget.targetMl > 0 ? widget.targetMl : 0.0;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Hydration progress ring',
      value: '${(_percent * 100).round()} percent',
      hint: 'Consumed ${consumed.toInt()} of ${target.toInt()} milliliters',
      child: SizedBox(
        width: widget.size,
        height: widget.size + 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _progress,
              builder: (_, __) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  progress: _progress.value,
                  stroke: widget.stroke,
                  trackColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '${(_percent * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                '${consumed.toInt()} / ${target.toInt()} ml',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
  final double progress;
  final double stroke;
  final Color trackColor;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);

    final sweep = (2 * math.pi) * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stroke != stroke ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.color != color;
  }
}
