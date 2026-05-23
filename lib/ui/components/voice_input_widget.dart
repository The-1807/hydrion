import 'package:flutter/material.dart';

class VoiceInputWidget extends StatelessWidget {
  final void Function(Map<String, dynamic> command) onCommandParsed;

  const VoiceInputWidget({super.key, required this.onCommandParsed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: false,
      label: 'Voice input disabled',
      child: FloatingActionButton(
        heroTag: 'voice_fab',
        onPressed: null,
        tooltip: 'Voice commands are a future local feature',
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(Icons.mic_off, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
