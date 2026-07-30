import 'package:flutter/material.dart';

import '../../domain/challenge_visual_registry.dart';

class ChallengeArtwork extends StatelessWidget {
  final ChallengeVisualIdentity identity;
  final BoxFit fit;
  final double iconSize;
  final int? cacheWidth;

  const ChallengeArtwork({
    super.key,
    required this.identity,
    this.fit = BoxFit.contain,
    this.iconSize = 44,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      identity.assetPath,
      fit: fit,
      alignment: identity.imageAlignment,
      cacheWidth: cacheWidth,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => _ChallengeArtFallback(
        identity: identity,
        iconSize: iconSize,
      ),
    );
  }
}

class _ChallengeArtFallback extends StatelessWidget {
  final ChallengeVisualIdentity identity;
  final double iconSize;

  const _ChallengeArtFallback({
    required this.identity,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: Key('challenge-art-fallback-${identity.challengeId}'),
      color: identity.primary.withValues(alpha: 0.12),
      child: CustomPaint(
        painter: _ChallengePatternPainter(
          primary: identity.primary,
          secondary: identity.secondary,
          seed: identity.challengeId.hashCode,
        ),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: identity.secondary.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                identity.icon,
                size: iconSize,
                color: identity.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengePatternPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final int seed;

  const _ChallengePatternPainter({
    required this.primary,
    required this.secondary,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final offset = (seed.abs() % 17).toDouble();
    for (var index = 0; index < 5; index++) {
      paint.color = (index.isEven ? primary : secondary).withValues(alpha: 0.2);
      final radius = size.shortestSide * (0.12 + index * 0.09);
      canvas.drawCircle(
        Offset(
          size.width * 0.5 + (offset - 8) * (index.isEven ? 1 : -1),
          size.height * 0.5,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChallengePatternPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.seed != seed;
}
