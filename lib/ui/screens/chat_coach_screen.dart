import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/hydrion_design.dart';

/// V1 keeps Coach visible as a clearly non-interactive preview.
class ChatCoachScreen extends StatelessWidget {
  final bool embedded;

  const ChatCoachScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HydrionSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            key: const Key('coach-coming-soon'),
            child: Padding(
              padding: const EdgeInsets.all(HydrionSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop_outlined, size: 72),
                  const SizedBox(height: HydrionSpacing.lg),
                  Text(l10n.coachPreviewTitle,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: HydrionSpacing.sm),
                  Text(
                    l10n.coachPreviewComingSoon,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: HydrionSpacing.sm),
                  Text(
                    l10n.coachPreviewGuidance,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachPreviewTitle)),
      body: content,
    );
  }
}
