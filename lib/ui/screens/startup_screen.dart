import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/release_metadata.dart';

class StartupScreen extends StatefulWidget {
  final Future<void> Function() warmUp;
  final bool Function() isOnboardingCompleted;
  final Duration minimumDuration;
  final Duration timeout;

  const StartupScreen({
    super.key,
    required this.warmUp,
    required this.isOnboardingCompleted,
    this.minimumDuration = const Duration(milliseconds: 2200),
    this.timeout = const Duration(seconds: 6),
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _recoverableError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.minimumDuration,
    )..forward();
    unawaited(_start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await Future.wait([
        Future<void>.delayed(widget.minimumDuration),
        _warmUp().timeout(widget.timeout),
      ]);
      if (!mounted) {
        return;
      }
      _goNext();
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _recoverableError =
            'Hydrion took longer than expected to finish startup checks.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recoverableError =
            'Hydrion could not finish startup checks, but your local data is preserved.';
      });
    }
  }

  Future<void> _warmUp() async {
    await widget.warmUp();
  }

  void _goNext() {
    final route = widget.isOnboardingCompleted() ? '/home' : '/onboarding';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final error = _recoverableError;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 240,
                      child: disableAnimations
                          ? const _StaticMascot()
                          : AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final eased = Curves.easeOutCubic.transform(
                                  _controller.value,
                                );
                                final bob = math.sin(eased * math.pi * 2) * 7;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _BubbleField(progress: eased),
                                    Transform.translate(
                                      offset: Offset(0, 36 * (1 - eased) + bob),
                                      child: Transform.rotate(
                                        angle: (1 - eased) * -0.08,
                                        child: Transform.scale(
                                          scale: 0.9 + eased * 0.1,
                                          child: Opacity(
                                            opacity: eased.clamp(0.0, 1.0),
                                            child: child,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _StartupRingPainter(
                                          progress: eased,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              child: const _StaticMascot(),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      HydrionReleaseMetadata.productName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error ?? 'Starting local-first hydration tracking',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (error == null)
                      const LinearProgressIndicator(
                        key: Key('startup-progress'),
                      )
                    else
                      FilledButton.icon(
                        key: const Key('startup-continue'),
                        onPressed: _goNext,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticMascot extends StatelessWidget {
  const _StaticMascot();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      HydrionAvatarManifest.mascotAssetPath,
      key: const Key('startup-mascot'),
      semanticLabel: 'Hydrion mascot',
      fit: BoxFit.contain,
    );
  }
}

class _BubbleField extends StatelessWidget {
  final double progress;

  const _BubbleField({required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.22);
    return Stack(
      children: [
        for (var index = 0; index < 7; index += 1)
          Positioned(
            left: 36.0 + index * 44,
            bottom: (index * 18 + progress * 120) % 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: SizedBox.square(dimension: 8 + (index % 3) * 4),
            ),
          ),
      ],
    );
  }
}

class _StartupRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _StartupRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) * 0.42,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.7);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _StartupRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
