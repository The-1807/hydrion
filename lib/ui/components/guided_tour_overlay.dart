import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../repositories/guided_tour_repository.dart';
import '../theme/hydrion_design.dart';

class GuidedTourStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final int? destinationIndex;
  final bool demonstratesPullToRefresh;

  const GuidedTourStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.destinationIndex,
    this.demonstratesPullToRefresh = false,
  });
}

enum TourCardPlacement { above, below, left, right, centered }

@immutable
class TourOverlayGeometry {
  final Rect cardRect;
  final Rect? spotlightRect;
  final Offset? pointerStart;
  final Offset? pointerEnd;
  final TourCardPlacement placement;

  const TourOverlayGeometry({
    required this.cardRect,
    required this.spotlightRect,
    required this.pointerStart,
    required this.pointerEnd,
    required this.placement,
  });
}

class GuidedTourLayout {
  static const double _gap = 18;

  static TourOverlayGeometry calculate({
    required Size viewport,
    required EdgeInsets safePadding,
    required EdgeInsets viewInsets,
    required Size cardSize,
    required Rect? targetRect,
    Rect? obstructionRect,
    bool expanded = false,
  }) {
    final unobstructedBottom = obstructionRect != null &&
            obstructionRect.top > safePadding.top &&
            obstructionRect.top < viewport.height
        ? obstructionRect.top - 12
        : viewport.height -
            math.max(safePadding.bottom, viewInsets.bottom) -
            12;
    final safeRect = Rect.fromLTRB(
      safePadding.left + 12,
      safePadding.top + 12,
      viewport.width - safePadding.right - 12,
      math.min(
        unobstructedBottom,
        viewport.height - math.max(safePadding.bottom, viewInsets.bottom) - 12,
      ),
    );
    final safeCardSize = Size(
      math.min(cardSize.width, safeRect.width),
      math.min(cardSize.height, safeRect.height),
    );
    if (targetRect == null) {
      final card = Rect.fromLTWH(
        safeRect.center.dx - safeCardSize.width / 2,
        safeRect.center.dy - safeCardSize.height / 2,
        safeCardSize.width,
        safeCardSize.height,
      );
      return TourOverlayGeometry(
        cardRect: card,
        spotlightRect: null,
        pointerStart: null,
        pointerEnd: null,
        placement: TourCardPlacement.centered,
      );
    }

    final spotlight = targetRect.inflate(7).intersect(
          Offset.zero & viewport,
        );
    final aboveSpace = targetRect.top - safeRect.top - _gap;
    final belowSpace = safeRect.bottom - targetRect.bottom - _gap;
    final preferredVertical =
        targetRect.center.dy < safeRect.top + safeRect.height / 3
            ? TourCardPlacement.below
            : targetRect.center.dy > safeRect.top + safeRect.height * 2 / 3
                ? TourCardPlacement.above
                : belowSpace >= aboveSpace
                    ? TourCardPlacement.below
                    : TourCardPlacement.above;
    final candidates = <TourCardPlacement>[
      if (expanded && targetRect.center.dx <= safeRect.center.dx)
        TourCardPlacement.right,
      if (expanded && targetRect.center.dx > safeRect.center.dx)
        TourCardPlacement.left,
      if (expanded && targetRect.center.dx <= safeRect.center.dx)
        TourCardPlacement.left,
      if (expanded && targetRect.center.dx > safeRect.center.dx)
        TourCardPlacement.right,
      preferredVertical,
      preferredVertical == TourCardPlacement.above
          ? TourCardPlacement.below
          : TourCardPlacement.above,
    ];
    Rect rectFor(TourCardPlacement placement) {
      return switch (placement) {
        TourCardPlacement.below => () {
            final height =
                math.min(safeCardSize.height, math.max(0.0, belowSpace));
            return Rect.fromLTWH(
              targetRect.center.dx - safeCardSize.width / 2,
              targetRect.bottom + _gap,
              safeCardSize.width,
              height,
            );
          }(),
        TourCardPlacement.above => () {
            final height =
                math.min(safeCardSize.height, math.max(0.0, aboveSpace));
            return Rect.fromLTWH(
              targetRect.center.dx - safeCardSize.width / 2,
              targetRect.top - _gap - height,
              safeCardSize.width,
              height,
            );
          }(),
        TourCardPlacement.right => Rect.fromLTWH(
            targetRect.right + _gap,
            targetRect.center.dy - safeCardSize.height / 2,
            safeCardSize.width,
            safeCardSize.height,
          ),
        TourCardPlacement.left => Rect.fromLTWH(
            targetRect.left - _gap - safeCardSize.width,
            targetRect.center.dy - safeCardSize.height / 2,
            safeCardSize.width,
            safeCardSize.height,
          ),
        TourCardPlacement.centered => Rect.fromLTWH(
            safeRect.center.dx - safeCardSize.width / 2,
            safeRect.center.dy - safeCardSize.height / 2,
            safeCardSize.width,
            safeCardSize.height,
          ),
      };
    }

    final minimumUsableHeight = math.min(160.0, safeRect.height);
    bool valid(TourCardPlacement candidate) {
      final rect = rectFor(candidate);
      return rect.width > 0 &&
          rect.height >= minimumUsableHeight &&
          safeRect.contains(rect.topLeft) &&
          safeRect.contains(rect.bottomRight) &&
          !rect.overlaps(spotlight);
    }

    var placement = candidates.firstWhere(
      valid,
      orElse: () => aboveSpace >= belowSpace
          ? TourCardPlacement.above
          : TourCardPlacement.below,
    );
    var cardRect = _clampRect(rectFor(placement), safeRect);
    if (cardRect.height <= 0 || cardRect.overlaps(spotlight)) {
      final fallback = Rect.fromLTWH(
        safeRect.center.dx - safeCardSize.width / 2,
        safeRect.center.dy - safeCardSize.height / 2,
        safeCardSize.width,
        safeCardSize.height,
      );
      cardRect = _clampRect(fallback, safeRect);
      placement = TourCardPlacement.centered;
    }

    final pointer = _pointerFor(
      cardRect: cardRect,
      targetRect: spotlight,
      placement: placement,
    );
    return TourOverlayGeometry(
      cardRect: cardRect,
      spotlightRect: spotlight,
      pointerStart: pointer?.$1,
      pointerEnd: pointer?.$2,
      placement: placement,
    );
  }

  static Rect _clampRect(Rect rect, Rect bounds) {
    final width = math.min(rect.width, bounds.width);
    final height = math.min(rect.height, bounds.height);
    final left = rect.left.clamp(bounds.left, bounds.right - width);
    final top = rect.top.clamp(bounds.top, bounds.bottom - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  static (Offset, Offset)? _pointerFor({
    required Rect cardRect,
    required Rect targetRect,
    required TourCardPlacement placement,
  }) {
    final (start, end) = switch (placement) {
      TourCardPlacement.above => (
          Offset(
            targetRect.center.dx.clamp(cardRect.left + 24, cardRect.right - 24),
            cardRect.bottom,
          ),
          Offset(targetRect.center.dx, targetRect.top),
        ),
      TourCardPlacement.below => (
          Offset(
            targetRect.center.dx.clamp(cardRect.left + 24, cardRect.right - 24),
            cardRect.top,
          ),
          Offset(targetRect.center.dx, targetRect.bottom),
        ),
      TourCardPlacement.left => (
          Offset(
            cardRect.right,
            targetRect.center.dy.clamp(cardRect.top + 24, cardRect.bottom - 24),
          ),
          Offset(targetRect.left, targetRect.center.dy),
        ),
      TourCardPlacement.right => (
          Offset(
            cardRect.left,
            targetRect.center.dy.clamp(cardRect.top + 24, cardRect.bottom - 24),
          ),
          Offset(targetRect.right, targetRect.center.dy),
        ),
      TourCardPlacement.centered => (Offset.zero, Offset.zero),
    };
    final distance = (end - start).distance;
    if (placement == TourCardPlacement.centered ||
        distance < 10 ||
        distance > 220) {
      return null;
    }
    return (start, end);
  }
}

class GuidedTourOverlay extends StatefulWidget {
  final List<GuidedTourStep> steps;
  final Widget child;
  final GlobalKey? obstructionKey;
  final ValueChanged<int>? onDestinationRequested;
  final VoidCallback? onFinished;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.child,
    this.obstructionKey,
    this.onDestinationRequested,
    this.onFinished,
  });

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GuidedTourRepository>(
      builder: (context, repository, _) {
        final show = repository.shouldShowCoreTour && widget.steps.isNotEmpty;
        final index =
            repository.currentStep.clamp(0, widget.steps.length - 1).toInt();
        return Stack(
          children: [
            ExcludeFocus(
              excluding: show,
              child: ExcludeSemantics(
                excluding: show,
                child: AbsorbPointer(absorbing: show, child: widget.child),
              ),
            ),
            if (show)
              _TourStepOverlay(
                key: ValueKey('core-tour-step-$index'),
                tourLabel: 'Hydrion app tour',
                step: widget.steps[index],
                index: index,
                total: widget.steps.length,
                obstructionKey: widget.obstructionKey,
                onDestinationRequested: widget.onDestinationRequested,
                onBack: index == 0
                    ? null
                    : () => repository.setCurrentStep(index - 1),
                onNext: index == widget.steps.length - 1
                    ? () async {
                        await repository.completeCoreTour();
                        widget.onFinished?.call();
                      }
                    : () => repository.setCurrentStep(index + 1),
                onSkip: repository.skipCoreTour,
                onTargetMissing: index == widget.steps.length - 1
                    ? repository.completeCoreTour
                    : () => repository.setCurrentStep(index + 1),
              ),
          ],
        );
      },
    );
  }
}

class ContextualGuidedTourOverlay extends StatelessWidget {
  final String tourId;
  final String semanticsLabel;
  final List<GuidedTourStep> steps;
  final Widget child;

  const ContextualGuidedTourOverlay({
    super.key,
    required this.tourId,
    required this.semanticsLabel,
    required this.steps,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GuidedTourRepository>(
      builder: (context, repository, _) {
        final show =
            steps.isNotEmpty && repository.shouldShowContextualTour(tourId);
        final index = repository
            .contextualCurrentStep(tourId)
            .clamp(0, steps.length - 1)
            .toInt();
        return Stack(
          children: [
            ExcludeFocus(
              excluding: show,
              child: ExcludeSemantics(
                excluding: show,
                child: AbsorbPointer(absorbing: show, child: child),
              ),
            ),
            if (show)
              _TourStepOverlay(
                key: ValueKey('$tourId-step-$index'),
                tourLabel: semanticsLabel,
                step: steps[index],
                index: index,
                total: steps.length,
                onBack: index == 0
                    ? null
                    : () => repository.setContextualCurrentStep(
                          tourId,
                          index - 1,
                        ),
                onNext: index == steps.length - 1
                    ? () => repository.completeContextualTour(tourId)
                    : () => repository.setContextualCurrentStep(
                          tourId,
                          index + 1,
                        ),
                onSkip: () => repository.skipContextualTour(tourId),
                onTargetMissing: index == steps.length - 1
                    ? () => repository.completeContextualTour(tourId)
                    : () => repository.setContextualCurrentStep(
                          tourId,
                          index + 1,
                        ),
              ),
          ],
        );
      },
    );
  }
}

class _TourStepOverlay extends StatefulWidget {
  final String tourLabel;
  final GuidedTourStep step;
  final int index;
  final int total;
  final FutureOr<void> Function()? onBack;
  final FutureOr<void> Function() onNext;
  final FutureOr<void> Function() onSkip;
  final FutureOr<void> Function() onTargetMissing;
  final ValueChanged<int>? onDestinationRequested;
  final GlobalKey? obstructionKey;

  const _TourStepOverlay({
    super.key,
    required this.tourLabel,
    required this.step,
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onTargetMissing,
    this.onDestinationRequested,
    this.obstructionKey,
  });

  @override
  State<_TourStepOverlay> createState() => _TourStepOverlayState();
}

class _TourStepOverlayState extends State<_TourStepOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _cardKey = GlobalKey();
  final _cardFocusNode = FocusNode(debugLabel: 'Hydrion tour card');
  late final AnimationController _gestureController;
  Rect? _target;
  Size? _cardSize;
  Rect? _obstruction;
  int _missingRecoveryAttempts = 0;
  bool _gestureStopped = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gestureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStep());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gestureController.dispose();
    _cardFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshMeasurements();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshMeasurements();
    });
  }

  Future<void> _prepareStep() async {
    if (!mounted) return;
    final destination = widget.step.destinationIndex;
    if (destination != null) {
      widget.onDestinationRequested?.call(destination);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    final targetContext = widget.step.targetKey.currentContext;
    if (targetContext == null) {
      _retryMissingTarget();
      return;
    }
    if (!targetContext.mounted) {
      _retryMissingTarget();
      return;
    }
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final textDirection = Directionality.of(context);
    await Scrollable.ensureVisible(
      targetContext,
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _refreshMeasurements();
    _cardFocusNode.requestFocus();
    SemanticsService.announce(
      '${widget.step.title}. ${widget.step.body}. '
      'Step ${widget.index + 1} of ${widget.total}.',
      textDirection,
    );
    if (widget.step.demonstratesPullToRefresh && !reducedMotion) {
      _runBriefGesture();
    }
  }

  Future<void> _runBriefGesture() async {
    for (var cycle = 0; cycle < 2 && mounted && !_gestureStopped; cycle += 1) {
      await _gestureController.forward(from: 0);
      if (!mounted || _gestureStopped) return;
      await _gestureController.reverse();
    }
  }

  void _retryMissingTarget() {
    if (_missingRecoveryAttempts >= 1) {
      scheduleMicrotask(widget.onTargetMissing);
      return;
    }
    _missingRecoveryAttempts += 1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final targetContext = widget.step.targetKey.currentContext;
      if (targetContext == null || !targetContext.mounted) {
        await widget.onTargetMissing();
        return;
      }
      await _prepareStep();
    });
  }

  void _refreshMeasurements() {
    final target = _rectForKey(widget.step.targetKey);
    final obstruction = widget.obstructionKey == null
        ? null
        : _rectForKey(widget.obstructionKey!);
    final card = _cardKey.currentContext?.findRenderObject();
    final nextCardSize = card is RenderBox && card.hasSize ? card.size : null;
    if (target != _target ||
        obstruction != _obstruction ||
        (nextCardSize != null && nextCardSize != _cardSize)) {
      setState(() {
        _target = target;
        _obstruction = obstruction;
        if (nextCardSize != null) _cardSize = nextCardSize;
      });
    }
  }

  Rect? _rectForKey(GlobalKey key) {
    final targetRender = key.currentContext?.findRenderObject();
    final rootRender = context.findRenderObject();
    if (targetRender is! RenderBox || rootRender is! RenderBox) return null;
    final targetGlobal = targetRender.localToGlobal(Offset.zero);
    final rootGlobal = rootRender.localToGlobal(Offset.zero);
    return (targetGlobal - rootGlobal) & targetRender.size;
  }

  void _stopGesture() {
    if (_gestureStopped) return;
    _gestureStopped = true;
    _gestureController.stop();
  }

  Future<void> _runAction(FutureOr<void> Function()? action) async {
    if (action == null || _actionInProgress) return;
    _stopGesture();
    setState(() => _actionInProgress = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildOverlay(context, constraints.biggest),
    );
  }

  Widget _buildOverlay(BuildContext context, Size constrainedSize) {
    final media = MediaQuery.of(context);
    final size = Size(
      math.min(media.size.width, constrainedSize.width),
      math.min(media.size.height, constrainedSize.height),
    );
    final width =
        size.width >= 600 ? 400.0 : math.max(240, size.width - 32).toDouble();
    final measurementTop = media.padding.top + 12;
    final measurementBottom =
        math.max(media.padding.bottom, media.viewInsets.bottom) + 12;
    final measurementMaxHeight =
        math.max(1.0, size.height - measurementTop - measurementBottom);
    final geometry = GuidedTourLayout.calculate(
      viewport: size,
      safePadding: media.padding,
      viewInsets: media.viewInsets,
      cardSize: _cardSize ?? Size(width, measurementMaxHeight),
      targetRect: _target,
      obstructionRect: _obstruction,
      expanded: size.width >= 700,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshMeasurements();
    });
    final scheme = Theme.of(context).colorScheme;
    final reducedMotion = media.disableAnimations;
    final tourCard = Focus(
      focusNode: _cardFocusNode,
      child: Card(
        key: _cardKey,
        elevation: 10,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HydrionRadii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: measurementMaxHeight),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius:
                                BorderRadius.circular(HydrionRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              'Step ${widget.index + 1} of ${widget.total}',
                              key: const Key('tour-progress'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.step.title,
                          key: const Key('tour-title'),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.step.body,
                          key: const Key('tour-body'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 6,
                  overflowSpacing: 8,
                  children: [
                    TextButton(
                      key: const Key('tour-skip'),
                      onPressed: _actionInProgress
                          ? null
                          : () => _runAction(widget.onSkip),
                      child: const Text('Skip'),
                    ),
                    if (widget.onBack != null)
                      OutlinedButton(
                        key: const Key('tour-back'),
                        onPressed: _actionInProgress
                            ? null
                            : () => _runAction(widget.onBack),
                        child: const Text('Back'),
                      ),
                    FilledButton(
                      key: const Key('tour-next'),
                      onPressed: _actionInProgress
                          ? null
                          : () => _runAction(widget.onNext),
                      child: Text(
                        widget.index == widget.total - 1 ? 'Finish' : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _runAction(widget.onSkip);
      },
      child: Listener(
        onPointerDown: (_) => _stopGesture(),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          label:
              '${widget.tourLabel} step ${widget.index + 1} of ${widget.total}',
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const Key('tour-spotlight'),
                      painter: _SpotlightPainter(
                        target: geometry.spotlightRect,
                        overlayColor: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Colors.black.withValues(alpha: 0.48)
                            : const Color(0xFF062B3B).withValues(alpha: 0.46),
                        glowColor: scheme.primary,
                      ),
                    ),
                  ),
                ),
                if (geometry.pointerStart != null &&
                    geometry.pointerEnd != null)
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: const Key('tour-pointer'),
                          painter: _PointerPainter(
                            from: geometry.pointerStart!,
                            to: geometry.pointerEnd!,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.step.demonstratesPullToRefresh)
                  Positioned(
                    key: const Key('tour-pull-gesture'),
                    top: media.padding.top + 12,
                    left: size.width / 2 - 72,
                    width: 144,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: AnimatedBuilder(
                          animation: _gestureController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              reducedMotion ? 0 : _gestureController.value * 18,
                            ),
                            child: child,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius:
                                  BorderRadius.circular(HydrionRadii.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward,
                                      color: scheme.primary),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                      child: Text('Pull to refresh')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_cardSize == null)
                  Positioned(
                    left: math.max(12, (size.width - width) / 2),
                    top: measurementTop,
                    width: width,
                    child: Opacity(
                      opacity: 0,
                      child: tourCard,
                    ),
                  )
                else
                  Positioned.fromRect(
                    rect: geometry.cardRect,
                    child: tourCard,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? target;
  final Color overlayColor;
  final Color glowColor;

  const _SpotlightPainter({
    required this.target,
    required this.overlayColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = overlayColor);
    if (target != null) {
      final cutout =
          RRect.fromRectAndRadius(target!, const Radius.circular(16));
      canvas.drawRRect(cutout, Paint()..blendMode = BlendMode.clear);
      canvas.drawRRect(
        cutout,
        Paint()
          ..color = glowColor.withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.target != target ||
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.glowColor != glowColor;
}

class _PointerPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  const _PointerPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final delta = to - from;
    final normal = Offset(-delta.dy, delta.dx);
    final normalLength = normal.distance;
    final bend = normalLength == 0 ? Offset.zero : normal / normalLength * 8;
    final control = Offset.lerp(from, to, 0.5)! + bend;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);

    final angle = math.atan2(delta.dy, delta.dx);
    const arrowLength = 9.0;
    const arrowSpread = 0.62;
    final arrow = Path()
      ..moveTo(
        to.dx - arrowLength * math.cos(angle - arrowSpread),
        to.dy - arrowLength * math.sin(angle - arrowSpread),
      )
      ..lineTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowLength * math.cos(angle + arrowSpread),
        to.dy - arrowLength * math.sin(angle + arrowSpread),
      );
    canvas.drawPath(arrow, paint);
    canvas.drawCircle(to, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.color != color;
}
