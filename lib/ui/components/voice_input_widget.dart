import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';

class VoiceInputWidget extends StatelessWidget {
  final void Function(Map<String, dynamic> command) onCommandParsed;

  const VoiceInputWidget({super.key, required this.onCommandParsed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final voiceEnabled = capabilities.voiceInput;

    return Semantics(
      button: true,
      enabled: voiceEnabled,
      label: voiceEnabled ? 'Voice input available' : 'Voice input disabled',
      child: FloatingActionButton(
        heroTag: 'voice_fab',
        onPressed: null,
        tooltip: voiceEnabled
            ? 'Voice capability reported, but no voice adapter is wired'
            : 'Voice input disabled by app capabilities',
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(
          voiceEnabled ? Icons.mic_none : Icons.mic_off,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
