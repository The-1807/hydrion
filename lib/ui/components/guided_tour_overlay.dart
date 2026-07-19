import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/guided_tour_repository.dart';
import '../theme/hydrion_design.dart';

class GuidedTourStep {
  final GlobalKey targetKey;
  final String title;
  final String body;

  const GuidedTourStep({
    required this.targetKey,
    required this.title,
    required this.body,
  });
}

class GuidedTourOverlay extends StatelessWidget {
  final List<GuidedTourStep> steps;
  final Widget child;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GuidedTourRepository>(
      builder: (context, repository, _) {
        final show = repository.shouldShowCoreTour && steps.isNotEmpty;
        final index = repository.currentStep.clamp(0, steps.length - 1).toInt();
        return Stack(
          children: [
            child,
            if (show)
              _TourStepOverlay(
                tourLabel: 'Hydrion app tour',
                step: steps[index],
                index: index,
                total: steps.length,
                onBack: index == 0
                    ? null
                    : () => repository.setCurrentStep(index - 1),
                onNext: index == steps.length - 1
                    ? repository.completeCoreTour
                    : () => repository.setCurrentStep(index + 1),
                onSkip: repository.skipCoreTour,
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
            child,
            if (show)
              _TourStepOverlay(
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
              ),
          ],
        );
      },
    );
  }
}

class _TourStepOverlay extends StatelessWidget {
  final String tourLabel;
  final GuidedTourStep step;
  final int index;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TourStepOverlay({
    required this.tourLabel,
    required this.step,
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final target = _targetRect(context, step.targetKey);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final cardWidth = size.width >= 600 ? 420.0 : size.width - 32;
    final targetCenter = target?.center ?? Offset(size.width / 2, padding.top);
    final cardTop = target == null
        ? padding.top + 72
        : target.bottom + 18 + 170 < size.height
            ? target.bottom + 18
            : (target.top - 188).clamp(padding.top + 12, size.height - 220);
    final cardLeft = (targetCenter.dx - cardWidth / 2)
        .clamp(16.0, (size.width - cardWidth - 16).clamp(16.0, size.width));

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: '$tourLabel step ${index + 1} of $total',
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.56),
              ),
            ),
            if (target != null)
              Positioned.fromRect(
                rect: target.inflate(8),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: HydrionColors.glow, width: 3),
                      borderRadius: BorderRadius.circular(HydrionRadii.md),
                    ),
                  ),
                ),
              ),
            if (target != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PointerPainter(
                      from: Offset(cardLeft + 36, cardTop + 24),
                      to: target.center,
                      color: HydrionColors.glow,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: cardLeft,
              top: cardTop.toDouble(),
              width: cardWidth,
              child: SafeArea(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1} of $total',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(step.body),
                        const SizedBox(height: 12),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          overflowAlignment: OverflowBarAlignment.end,
                          spacing: 4,
                          overflowSpacing: 4,
                          children: [
                            TextButton(
                              key: const Key('tour-skip'),
                              onPressed: onSkip,
                              child: const Text('Skip'),
                            ),
                            TextButton(
                              key: const Key('tour-back'),
                              onPressed: onBack,
                              child: const Text('Back'),
                            ),
                            FilledButton(
                              key: const Key('tour-next'),
                              onPressed: onNext,
                              child: Text(
                                index == total - 1 ? 'Finish' : 'Next',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Rect? _targetRect(BuildContext context, GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (renderObject is! RenderBox || overlay is! RenderBox) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: overlay);
    return topLeft & renderObject.size;
  }
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
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(from.dx, to.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color;
  }
}
