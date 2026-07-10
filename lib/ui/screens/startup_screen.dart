import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/startup_trace.dart';
import '../components/hydrion_startup_shark.dart';

class StartupScreen extends StatefulWidget {
  static const welcomeText = 'Welcome';
  static const preparingText = 'Preparing your hydration space...';

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

class _StartupScreenState extends State<StartupScreen> {
  static const _maxWelcomeDuration = Duration(milliseconds: 850);

  int _startupRun = 0;
  String _startupText = StartupScreen.welcomeText;
  Completer<DateTime> _bufferVisible = Completer<DateTime>();
  bool _loggedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    HydrionStartupTrace.log('StartupScreen.initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loggedFirstFrame) {
        return;
      }
      _loggedFirstFrame = true;
      HydrionStartupTrace.log('first Flutter frame painted');
      _markBufferVisible('first-frame');
    });
    unawaited(_start());
  }

  Future<void> _start() async {
    final run = _startupRun + 1;
    _startupRun = run;
    _bufferVisible = Completer<DateTime>();
    setState(() {
      _startupText = StartupScreen.welcomeText;
    });

    final warmUp = _runWarmUp();

    final visibleAt = await _waitForBufferVisible(run);
    await _waitForWelcomeText(visibleAt);
    if (!mounted || _startupRun != run) {
      return;
    }
    setState(() {
      _startupText = StartupScreen.preparingText;
    });

    final warmUpResult = await warmUp;
    if (!mounted || _startupRun != run) {
      return;
    }
    if (!warmUpResult.succeeded) {
      HydrionStartupTrace.log(
        'StartupScreen.warmup failed',
        data: {'error': warmUpResult.errorType ?? 'unknown'},
      );
      return;
    }

    await _waitForMinimumDuration(visibleAt);
    if (!mounted || _startupRun != run) {
      return;
    }
    await WidgetsBinding.instance.endOfFrame.timeout(
      const Duration(milliseconds: 120),
      onTimeout: () {},
    );
    if (!mounted || _startupRun != run) {
      return;
    }
    _goNext();
  }

  Future<_WarmUpResult> _runWarmUp() async {
    try {
      await widget.warmUp().timeout(widget.timeout);
      return const _WarmUpResult.succeeded();
    } on TimeoutException {
      return const _WarmUpResult.failed('TimeoutException');
    } catch (error) {
      return _WarmUpResult.failed(error.runtimeType.toString());
    }
  }

  Future<DateTime> _waitForBufferVisible(int run) async {
    if (!_bufferVisible.isCompleted) {
      HydrionStartupTrace.log('waiting for startup buffer visible frame');
    }
    final visibleAt = await _bufferVisible.future;
    HydrionStartupTrace.log(
      'startup buffer visible gate satisfied',
      data: {'run': run},
    );
    return visibleAt;
  }

  void _markBufferVisible(String source) {
    if (_bufferVisible.isCompleted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bufferVisible.isCompleted) {
        return;
      }
      final now = DateTime.now();
      _bufferVisible.complete(now);
      HydrionStartupTrace.log(
        'startup buffer visible gate started',
        data: {'source': source},
      );
    });
  }

  void _handleSharkLoaded() {
    HydrionStartupTrace.log('startup shark lottie loaded');
    _markBufferVisible('lottie-loaded');
  }

  Future<void> _waitForWelcomeText(DateTime startedAt) async {
    final welcomeDuration = _welcomeDuration;
    if (welcomeDuration <= Duration.zero) {
      return;
    }
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = welcomeDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Duration get _welcomeDuration {
    if (widget.minimumDuration <= Duration.zero) {
      return Duration.zero;
    }
    final bounded = math.min(
      _maxWelcomeDuration.inMilliseconds,
      math.max(0, widget.minimumDuration.inMilliseconds ~/ 3),
    );
    return Duration(milliseconds: bounded);
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
    HydrionStartupTrace.log(
      'StartupScreen.route handoff',
      data: {'route': route},
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFEAFBFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HydrionStartupShark(
                  animate: !disableAnimations,
                  onLoaded: _handleSharkLoaded,
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Text(
                    _startupText,
                    key: ValueKey<String>(_startupText),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmUpResult {
  final bool succeeded;
  final String? errorType;

  const _WarmUpResult.succeeded()
      : succeeded = true,
        errorType = null;

  const _WarmUpResult.failed(this.errorType) : succeeded = false;
}
