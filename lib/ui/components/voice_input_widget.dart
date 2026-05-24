import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';

class VoiceInputWidget extends StatelessWidget {
  final void Function(Map<String, dynamic> command) onCommandParsed;

  const VoiceInputWidget({super.key, required this.onCommandParsed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final voiceEnabled = capabilities.voiceInput;

    return Semantics(
      button: true,
      enabled: voiceEnabled,
      label: voiceEnabled
          ? l10n.voiceInputAvailableSemantics
          : l10n.voiceInputDisabledSemantics,
      child: FloatingActionButton(
        heroTag: 'voice_fab',
        onPressed: null,
        tooltip: voiceEnabled
            ? l10n.voiceCapabilityReportedNoAdapter
            : l10n.voiceInputDisabledTooltip,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(
          voiceEnabled ? Icons.mic_none : Icons.mic_off,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
