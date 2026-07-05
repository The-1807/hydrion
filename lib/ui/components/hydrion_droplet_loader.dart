import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class HydrionDropletLoader extends StatefulWidget {
  final double progress;
  final double size;
  final bool reducedMotion;
  final String? semanticLabel;

  const HydrionDropletLoader({
    super.key,
    required this.progress,
    this.size = 96,
    this.reducedMotion = false,
    this.semanticLabel,
  });

  static double clampProgress(double value) {
    if (value.isNaN) {
      return 0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  @override
  State<HydrionDropletLoader> createState() => _HydrionDropletLoaderState();
}

class _HydrionDropletLoaderState extends State<HydrionDropletLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncWaveAnimation();
  }

  @override
  void didUpdateWidget(covariant HydrionDropletLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWaveAnimation();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _syncWaveAnimation() {
    final complete = HydrionDropletLoader.clampProgress(widget.progress) >= 1;
    if (widget.reducedMotion || complete) {
      _waveController.stop();
      return;
    }
    if (!_waveController.isAnimating) {
      _waveController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clamped = HydrionDropletLoader.clampProgress(widget.progress);
    final percent = (clamped * 100).round();
    final duration = widget.reducedMotion
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 460);

    return Semantics(
      label:
          widget.semanticLabel ?? 'Loading Hydrion, $percent percent complete',
      value: '$percent%',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: clamped),
          duration: duration,
          curve: widget.reducedMotion ? Curves.linear : Curves.easeOutCubic,
          builder: (context, smoothProgress, _) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return SizedBox.square(
                  key: const Key('hydrion-droplet-loader'),
                  dimension: widget.size,
                  child: CustomPaint(
                    painter: _HydrionDropletPainter(
                      progress: smoothProgress,
                      wavePhase:
                          widget.reducedMotion ? 0 : _waveController.value,
                      reducedMotion: widget.reducedMotion,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HydrionDropletPainter extends CustomPainter {
  static const _deep = Color(0xFF005792);
  static const _mid = Color(0xFF0088CC);
  static const _bright = Color(0xFF00D2FF);

  final double progress;
  final double wavePhase;
  final bool reducedMotion;

  const _HydrionDropletPainter({
    required this.progress,
    required this.wavePhase,
    required this.reducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final droplet = _dropletPath(size);
    final bounds = droplet.getBounds();
    final safeProgress = HydrionDropletLoader.clampProgress(progress);
    final visibleProgress = math.max(0.02, safeProgress);
    final completionGlow = ((safeProgress - 0.85) / 0.15).clamp(0.0, 1.0);
    final side = math.min(size.width, size.height);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * (0.055 + completionGlow * 0.025)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        side * (0.05 + completionGlow * 0.035),
      )
      ..color = _bright.withValues(alpha: 0.17 + completionGlow * 0.2);
    canvas.drawPath(droplet, glowPaint);

    canvas.drawShadow(
      droplet,
      _mid.withValues(alpha: 0.24 + completionGlow * 0.12),
      8 + completionGlow * 3,
      false,
    );

    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          _bright.withValues(alpha: 0.05),
          _deep.withValues(alpha: 0.08),
        ],
      ).createShader(bounds);
    canvas.drawPath(droplet, glassPaint);

    canvas.save();
    canvas.clipPath(droplet);
    final fillTop = bounds.bottom - bounds.height * visibleProgress;
    _drawWaveLayer(
      canvas,
      bounds: bounds,
      fillTop: fillTop,
      phase: wavePhase,
      amplitude: side * (reducedMotion ? 0.012 : 0.038),
      opacity: 0.82,
      direction: 1,
    );
    _drawWaveLayer(
      canvas,
      bounds: bounds,
      fillTop: fillTop + side * 0.035,
      phase: (wavePhase * 1.35 + 0.38) % 1,
      amplitude: side * (reducedMotion ? 0.008 : 0.028),
      opacity: 0.48,
      direction: -1,
    );

    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.55),
        radius: 0.95,
        colors: [
          _bright.withValues(alpha: 0.25 + completionGlow * 0.1),
          _mid.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, innerGlowPaint);
    canvas.restore();

    final reflection = _reflectionPath(size);
    final reflectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.025
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.34);
    canvas.drawPath(reflection, reflectionPaint);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.035
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _bright.withValues(alpha: 0.45 + completionGlow * 0.18);
    canvas.drawPath(droplet, outlinePaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.013
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawPath(droplet, rimPaint);
  }

  void _drawWaveLayer(
    Canvas canvas, {
    required Rect bounds,
    required double fillTop,
    required double phase,
    required double amplitude,
    required double opacity,
    required int direction,
  }) {
    final wavelength = bounds.width * 0.78;
    final travel = wavelength * (direction >= 0 ? phase : -phase);
    var x = bounds.left - wavelength * 2 + travel;
    final path = Path()
      ..moveTo(x, bounds.bottom)
      ..lineTo(x, fillTop);

    while (x < bounds.right + wavelength * 2) {
      path
        ..quadraticBezierTo(
          x + wavelength * 0.25,
          fillTop - amplitude,
          x + wavelength * 0.5,
          fillTop,
        )
        ..quadraticBezierTo(
          x + wavelength * 0.75,
          fillTop + amplitude,
          x + wavelength,
          fillTop,
        );
      x += wavelength;
    }

    path
      ..lineTo(x, bounds.bottom)
      ..lineTo(bounds.left - wavelength * 2, bounds.bottom)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_deep, _mid, _bright],
        stops: [0, 0.55, 1],
      ).createShader(bounds)
      ..color = _mid.withValues(alpha: opacity)
      ..blendMode = BlendMode.srcOver;
    final opacityLayer = Paint()
      ..color = Colors.white.withValues(alpha: opacity);
    canvas.saveLayer(bounds.inflate(bounds.width * 0.2), opacityLayer);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  Path _dropletPath(Size size) {
    return _scaledPath(size, _baseDropletPath());
  }

  Path _reflectionPath(Size size) {
    final reflection = Path()
      ..moveTo(38, 25)
      ..cubicTo(29, 39, 25, 52, 27, 63);
    return _scaledPath(size, reflection);
  }

  Path _scaledPath(Size size, Path path) {
    final side = math.min(size.width, size.height);
    final inset = side * 0.08;
    final scale = (side - inset * 2) / 100;
    final dx = (size.width - side) / 2 + inset;
    final dy = (size.height - side) / 2 + inset;
    final matrix = Float64List.fromList([
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      dx,
      dy,
      0,
      1,
    ]);
    return path.transform(matrix);
  }

  Path _baseDropletPath() {
    return Path()
      ..moveTo(50, 5)
      ..cubicTo(50, 5, 15, 50, 15, 68)
      ..cubicTo(15, 87.3, 30.7, 100, 50, 100)
      ..cubicTo(69.3, 100, 85, 87.3, 85, 68)
      ..cubicTo(85, 50, 50, 5, 50, 5)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _HydrionDropletPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
