import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
  bool _failed = false;

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
      _failed = false;
      _startupText = StartupScreen.welcomeText;
    });
    if (_loggedFirstFrame) {
      // Retry: the first-frame gate already fired for the previous run.
      _markBufferVisible('retry');
    }

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
      // Owner decision O2: never leave the user on the splash. The app
      // could not be composed, so show a recoverable error with Retry.
      setState(() {
        _failed = true;
      });
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
    final warmUp = widget.warmUp();
    try {
      await warmUp.timeout(widget.timeout);
      return const _WarmUpResult.succeeded();
    } on TimeoutException {
      HydrionStartupTrace.log(
        'StartupScreen.warmup exceeded advisory timeout',
      );
      try {
        await warmUp;
        return const _WarmUpResult.succeeded();
      } catch (error) {
        return _WarmUpResult.failed(error.runtimeType.toString());
      }
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

  void _retry() {
    HydrionStartupTrace.log('StartupScreen.retry requested');
    unawaited(_start());
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _StartupErrorView(onRetry: _retry);
    }
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

AppLocalizations _startupL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

/// Class (a) startup failure: services could not be composed, so the app is
/// unusable. Shows a localized explanation and a Retry action.
class _StartupErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = _startupL10n(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('startup-error'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.startupFailedTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.startupFailedMessage,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('startup-retry'),
                  onPressed: onRetry,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed outcome of one non-essential post-composition startup step.
enum HydrionStartupStepOutcome {
  /// The step has not run yet.
  pending,
  succeeded,
  failed,

  /// The step did not run because a step it depends on did not succeed.
  skippedDependencyFailed,
}

/// One non-essential post-composition startup step (class (b)). Each step is
/// contained on its own so later independent steps still run.
class HydrionStartupStep {
  final String id;
  final Future<void> Function() run;
  final Set<String> dependsOn;

  const HydrionStartupStep(
    this.id,
    this.run, {
    this.dependsOn = const <String>{},
  });
}

class HydrionStartupStepResult {
  final String id;
  final HydrionStartupStepOutcome outcome;

  /// Runtime type of the failure only; payloads are never recorded.
  final String? errorType;

  const HydrionStartupStepResult(this.id, this.outcome, {this.errorType});
}

/// Records which non-essential startup steps did not complete so the app can
/// route in a degraded state with a visible notice and Retry (owner decision
/// O2). Minimal Wave 0 contract; the lifecycle coordinator (K8) replaces it.
class HydrionStartupHealth extends ChangeNotifier {
  final List<HydrionStartupStep> _steps = <HydrionStartupStep>[];
  final Map<String, HydrionStartupStepResult> _results =
      <String, HydrionStartupStepResult>{};
  bool _running = false;

  bool get isRunning => _running;

  List<HydrionStartupStepResult> get results => [
        for (final step in _steps)
          _results[step.id] ??
              HydrionStartupStepResult(
                step.id,
                HydrionStartupStepOutcome.pending,
              ),
      ];

  HydrionStartupStepOutcome outcomeFor(String id) =>
      _results[id]?.outcome ?? HydrionStartupStepOutcome.pending;

  /// Steps that ran and did not succeed (failed or skipped).
  List<String> get incompleteStepIds => [
        for (final result in results)
          if (result.outcome == HydrionStartupStepOutcome.failed ||
              result.outcome ==
                  HydrionStartupStepOutcome.skippedDependencyFailed)
            result.id,
      ];

  bool get isDegraded => incompleteStepIds.isNotEmpty;

  /// Registers [steps] (replacing any with the same id) and runs them in
  /// order. Never throws because of a step failure.
  Future<void> run(List<HydrionStartupStep> steps) async {
    for (final step in steps) {
      _steps.removeWhere((existing) => existing.id == step.id);
      _steps.add(step);
    }
    await _runSteps(steps);
  }

  /// Re-runs every registered step that did not succeed, in order.
  Future<void> retry() async {
    if (_running) return;
    await _runSteps([
      for (final step in _steps)
        if (outcomeFor(step.id) != HydrionStartupStepOutcome.succeeded) step,
    ]);
  }

  Future<void> _runSteps(List<HydrionStartupStep> steps) async {
    _running = true;
    notifyListeners();
    try {
      for (final step in steps) {
        _results[step.id] = await _runStep(step);
      }
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<HydrionStartupStepResult> _runStep(HydrionStartupStep step) async {
    final blocked = step.dependsOn.where(
      (id) => outcomeFor(id) != HydrionStartupStepOutcome.succeeded,
    );
    if (blocked.isNotEmpty) {
      HydrionStartupTrace.log(
        'HydrionStartupHealth gate=${step.id} status=skipped',
        data: {'blockedBy': blocked.join(',')},
      );
      return HydrionStartupStepResult(
        step.id,
        HydrionStartupStepOutcome.skippedDependencyFailed,
      );
    }
    HydrionStartupTrace.log(
      'HydrionStartupHealth gate=${step.id} status=start',
    );
    try {
      await step.run();
    } catch (error) {
      // Step boundary containment: the step is recorded as failed (type only,
      // never the payload), surfaced to the user, and offered for retry.
      final errorType = error.runtimeType.toString();
      HydrionStartupTrace.log(
        'HydrionStartupHealth gate=${step.id} status=failed',
        data: {'error': errorType},
      );
      return HydrionStartupStepResult(
        step.id,
        HydrionStartupStepOutcome.failed,
        errorType: errorType,
      );
    }
    HydrionStartupTrace.log(
      'HydrionStartupHealth gate=${step.id} status=done',
    );
    return HydrionStartupStepResult(
      step.id,
      HydrionStartupStepOutcome.succeeded,
    );
  }
}

/// Visible, localized notice shown above the app when non-essential startup
/// steps did not complete. Offers Retry and a session-only dismissal.
class StartupDegradedNotice extends StatefulWidget {
  final HydrionStartupHealth health;
  final Widget child;

  const StartupDegradedNotice({
    super.key,
    required this.health,
    required this.child,
  });

  @override
  State<StartupDegradedNotice> createState() => _StartupDegradedNoticeState();
}

class _StartupDegradedNoticeState extends State<StartupDegradedNotice> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.health,
      builder: (context, child) {
        final health = widget.health;
        final visible = health.isDegraded && !_dismissed;
        if (!visible) {
          return child!;
        }
        final l10n = _startupL10n(context);
        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            Material(
              key: const Key('startup-degraded-notice'),
              color: colors.secondaryContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.startupDegradedNotice(
                                count: health.incompleteStepIds.length,
                              ),
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Above the Navigator there is no Overlay, so no
                      // tooltips here; both actions are labelled buttons.
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            key: const Key('startup-degraded-dismiss'),
                            onPressed: () => setState(() => _dismissed = true),
                            child: Text(l10n.startupDegradedDismiss),
                          ),
                          TextButton(
                            key: const Key('startup-degraded-retry'),
                            onPressed: health.isRunning
                                ? null
                                : () => unawaited(health.retry()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child!,
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
