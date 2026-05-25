import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';

class LLMAdviceCard extends StatefulWidget {
  final double hydrationPercent;
  final int entryCount;
  final double temperatureC;

  const LLMAdviceCard({
    super.key,
    required this.hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required this.temperatureC,
  }) : entryCount = entryCount ?? activityMinutes ?? 0;

  @override
  State<LLMAdviceCard> createState() => _LLMAdviceCardState();
}

class _LLMAdviceCardState extends State<LLMAdviceCard> {
  Future<String>? _future;
  String? _cached;
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale != locale) {
      _locale = locale;
      _cached = null;
      _future = _fetch();
    }
  }

  @override
  void didUpdateWidget(covariant LLMAdviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hydrationPercent != widget.hydrationPercent ||
        oldWidget.entryCount != widget.entryCount ||
        oldWidget.temperatureC != widget.temperatureC) {
      _cached = null;
      _future = _fetch();
    }
  }

  Future<String> _fetch() async {
    final coach = context.read<HydrationCoach>();
    final message = await coach.getHydrationCoachResponse(
      hydrationPercent: widget.hydrationPercent,
      entryCount: widget.entryCount,
      temperatureC: widget.temperatureC,
    );
    _cached = message;
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.hydrationAdviceCardSemantics,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _cached == null) {
                return const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: LinearProgressIndicator()),
                  ],
                );
              }

              if (snapshot.hasError) {
                return _AdviceError(
                  onRetry: () {
                    setState(() {
                      _future = _fetch();
                    });
                  },
                );
              }

              final text =
                  (snapshot.data ?? _cached ?? l10n.stayHydratedFallback)
                      .trim();
              return Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, color: scheme.error, size: 20),
        const SizedBox(height: 8),
        Text(
          l10n.failedToLoadAdvice,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ],
    );
  }
}
