import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/release_metadata.dart';
import '../../utils/startup_trace.dart';
import '../components/hydrion_droplet_loader.dart';

class StartupScreen extends StatefulWidget {
  final Future<void> Function() warmUp;
  final bool Function() isOnboardingCompleted;
  final String Function()? nextRoute;
  final ValueChanged<String>? onRouteSelected;
  final Duration minimumDuration;
  final Duration timeout;

  const StartupScreen({
    super.key,
    required this.warmUp,
    required this.isOnboardingCompleted,
    this.nextRoute,
    this.onRouteSelected,
    this.minimumDuration = Duration.zero,
    this.timeout = const Duration(seconds: 6),
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _startupProgress = ValueNotifier<double>(0);
  String? _recoverableError;
  int _startupRun = 0;
  Completer<DateTime> _loaderVisible = Completer<DateTime>();
  bool _loggedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    HydrionStartupTrace.log('StartupScreen.initState');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loggedFirstFrame) {
        return;
      }
      _loggedFirstFrame = true;
      HydrionStartupTrace.log('first Flutter frame painted');
    });
    unawaited(_start());
  }

  @override
  void dispose() {
    _controller.dispose();
    _startupProgress.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final run = _startupRun + 1;
    _startupRun = run;
    _loaderVisible = Completer<DateTime>();
    setState(() {
      _recoverableError = null;
    });
    _startupProgress.value = 0;
    _setStartupProgress(0.08, run);
    _controller.forward(from: 0);
    try {
      _setStartupProgress(0.16, run);
      await _warmUp().timeout(widget.timeout).then((_) {
        _setStartupProgress(0.72, run);
      });
      if (!mounted) {
        return;
      }
      final visibleAt = await _waitForLoaderVisible(run);
      await _waitForMinimumDuration(visibleAt);
      if (!mounted || _startupRun != run) {
        return;
      }
      _setStartupProgress(1, run);
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 120),
        onTimeout: () {},
      );
      if (!mounted || _startupRun != run) {
        return;
      }
      _goNext();
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      _controller.stop();
      setState(() {
        _recoverableError =
            'Hydrion took longer than expected to finish startup checks.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _controller.stop();
      setState(() {
        _recoverableError =
            'Hydrion could not finish startup checks, but your local data is preserved.';
      });
    }
  }

  Future<void> _warmUp() async {
    await widget.warmUp();
  }

  Future<DateTime> _waitForLoaderVisible(int run) async {
    if (!_loaderVisible.isCompleted) {
      HydrionStartupTrace.log('waiting for loader/fallback visible frame');
    }
    final visibleAt = await _loaderVisible.future;
    HydrionStartupTrace.log(
      'loader/fallback visible gate satisfied',
      data: {'run': run},
    );
    return visibleAt;
  }

  void _handleLoaderVisualState(HydrionLoaderVisualState state) {
    final event = switch (state) {
      HydrionLoaderVisualState.fallbackShown => 'loader fallback shown',
      HydrionLoaderVisualState.lottieLoaded => 'loader asset loaded',
    };
    HydrionStartupTrace.log(event);
    if (!_loaderVisible.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _loaderVisible.isCompleted) {
          return;
        }
        final now = DateTime.now();
        _loaderVisible.complete(now);
        HydrionStartupTrace.log(
          'loader/fallback visible gate started',
          data: {'source': state.name},
        );
      });
    }
  }

  void _setStartupProgress(double progress, int run) {
    if (!mounted || _startupRun != run || _recoverableError != null) {
      return;
    }
    final clamped = HydrionDropletLoader.clampProgress(progress);
    _startupProgress.value = math.max(_startupProgress.value, clamped);
  }

  void _retryStartup() {
    unawaited(_start());
  }

  Future<void> _waitForMinimumDuration(DateTime startedAt) async {
    if (widget.minimumDuration <= Duration.zero) {
      return;
    }
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = widget.minimumDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  void _goNext() {
    final route = widget.nextRoute?.call() ??
        (widget.isOnboardingCompleted() ? '/home' : '/onboarding');
    HydrionStartupTrace.log('StartupScreen.route handoff',
        data: {'route': route});
    final onRouteSelected = widget.onRouteSelected;
    if (onRouteSelected != null) {
      onRouteSelected(route);
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final error = _recoverableError;

    return Scaffold(
      body: _StartupBackdrop(
        reducedMotion: disableAnimations,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: _startupProgress,
                              builder: (context, progress, _) {
                                return _StartupScene(
                                  controller: _controller,
                                  progress: progress,
                                  reducedMotion: disableAnimations,
                                  hasError: error != null,
                                  onLoaderVisualState: _handleLoaderVisualState,
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              HydrionReleaseMetadata.productName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<double>(
                              valueListenable: _startupProgress,
                              builder: (context, progress, _) {
                                return Text(
                                  error ??
                                      'Preparing local-first hydration tracking '
                                          '${(progress * 100).round()}%',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            if (error != null)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('startup-retry'),
                                    onPressed: _retryStartup,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                  FilledButton.icon(
                                    key: const Key('startup-continue'),
                                    onPressed: _goNext,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Continue'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StartupBackdrop extends StatelessWidget {
  final Widget child;
  final bool reducedMotion;

  const _StartupBackdrop({
    required this.child,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF04243A),
            Color(0xFF005792),
            Color(0xFFE9FBFF),
          ],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CausticRaysPainter(reducedMotion: reducedMotion),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StartupScene extends StatelessWidget {
  final AnimationController controller;
  final double progress;
  final bool reducedMotion;
  final bool hasError;
  final ValueChanged<HydrionLoaderVisualState> onLoaderVisualState;

  const _StartupScene({
    required this.controller,
    required this.progress,
    required this.reducedMotion,
    required this.hasError,
    required this.onLoaderVisualState,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = HydrionDropletLoader.clampProgress(progress);

    return SizedBox(
      height: 284,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final rawScene = reducedMotion ? 1.0 : controller.value;
          final eased = Curves.easeOutCubic.transform(rawScene);
          final bob = reducedMotion || hasError
              ? 0.0
              : math.sin(eased * math.pi * 2) * 7;
          final handoff = ((clampedProgress - 0.92) / 0.08).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              if (!reducedMotion) _BubbleField(progress: eased),
              Positioned(
                top: 8,
                child: Transform.translate(
                  offset: reducedMotion
                      ? Offset.zero
                      : Offset(-64 * (1 - eased), 34 * (1 - eased) + bob),
                  child: Transform.rotate(
                    angle: reducedMotion || hasError ? 0 : (1 - eased) * -0.1,
                    child: Transform.scale(
                      scale: 0.88 + eased * 0.12,
                      child: Opacity(
                        opacity: reducedMotion ? 1 : eased.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: handoff,
                      child: CustomPaint(
                        key: const Key('startup-completion-ring'),
                        size: const Size.square(132),
                        painter: _CompletionRingPainter(progress: handoff),
                      ),
                    ),
                    Transform.scale(
                      scale: 1 + handoff * 0.08,
                      child: Opacity(
                        opacity: hasError ? 0.78 : 1 - handoff * 0.35,
                        child: HydrionDropletLoader(
                          key: const Key('startup-droplet-loader'),
                          progress: clampedProgress,
                          size: 112,
                          reducedMotion: reducedMotion || hasError,
                          onVisualStateChanged: onLoaderVisualState,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        child: const _StaticMascot(),
      ),
    );
  }
}

class _StaticMascot extends StatelessWidget {
  const _StaticMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const Key('startup-mascot'),
      dimension: 118,
      child: ClipOval(
        child: Image.asset(
          HydrionAvatarManifest.mascotAssetPath,
          semanticLabel: 'Hydrion mascot',
          fit: BoxFit.cover,
        ),
      ),
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

class _CausticRaysPainter extends CustomPainter {
  final bool reducedMotion;

  const _CausticRaysPainter({required this.reducedMotion});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: reducedMotion ? 0.08 : 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.7));

    for (var index = 0; index < 4; index += 1) {
      final left = size.width * (0.08 + index * 0.23);
      final ray = Path()
        ..moveTo(left, 0)
        ..lineTo(left + size.width * 0.15, 0)
        ..lineTo(left + size.width * (0.26 + index * 0.02), size.height)
        ..lineTo(left - size.width * 0.08, size.height)
        ..close();
      canvas.drawPath(ray, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CausticRaysPainter oldDelegate) {
    return oldDelegate.reducedMotion != reducedMotion;
  }
}

class _CompletionRingPainter extends CustomPainter {
  final double progress;

  const _CompletionRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) * 0.42,
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.2 * progress);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.75 * progress);
    canvas
      ..drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, glow)
      ..drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, ring);
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
