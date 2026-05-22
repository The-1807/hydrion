import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../hydrion/app/lib/services/llm_service.dart';
import '../../utils/i18n_resolver.dart';

/// LLMAdviceCard — pulls a short, personalized hydration nudge from LLMService.
/// - Caches the call so rebuilds don’t spam the API
/// - Graceful loading/error states
/// - Accessible semantics + RTL aware
class LLMAdviceCard extends StatefulWidget {
  final double hydrationPercent;
  final int activityMinutes;
  final double temperatureC;

  const LLMAdviceCard({
    super.key,
    required this.hydrationPercent,
    required this.activityMinutes,
    required this.temperatureC,
  });

  @override
  State<LLMAdviceCard> createState() => _LLMAdviceCardState();
}

class _LLMAdviceCardState extends State<LLMAdviceCard> {
  Future<String>? _future;
  String? _cached;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant LLMAdviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute only when inputs change meaningfully
    if (oldWidget.hydrationPercent != widget.hydrationPercent ||
        oldWidget.activityMinutes != widget.activityMinutes ||
        oldWidget.temperatureC != widget.temperatureC) {
      _future = _fetch();
    }
  }

  Future<String> _fetch() async {
    final llm = context.read<LLMService>();
    final msg = await llm.getHydrationCoachResponse(
      hydrationPercent: widget.hydrationPercent,
      activityMinutes: widget.activityMinutes,
      temperatureC: widget.temperatureC,
    );
    _cached = msg;
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);

    return Semantics(
      label: 'Hydration advice card',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && _cached == null) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snap.hasError) {
                return _AdviceError(onRetry: () {
                  setState(() {
                    _future = _fetch();
                  });
                });
              }

              final text = (snap.data ?? _cached ?? 'Stay hydrated!').trim();
              return Text(
                text,
                textAlign: TextAlign.center,
                textDirection: dir,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdviceError extends StatelessWidget {
  final VoidCallback onRetry;
  const _AdviceError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, color: c.error, size: 20),
        const SizedBox(height: 8),
        Text(
          'Failed to load advice',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
