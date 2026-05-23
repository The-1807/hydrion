import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/voice_client.dart';

class VoiceInputWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> command) onCommandParsed;

  const VoiceInputWidget({super.key, required this.onCommandParsed});

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  bool _busy = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    final ready = await context.read<VoiceService>().initialize();
    if (mounted) {
      setState(() => _ready = ready);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (!_ready || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final voice = context.read<VoiceService>();
      final command = await voice.processVoiceCommand();
      if (!mounted) {
        return;
      }
      widget.onCommandParsed(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command: ${command['intent']}')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice processing failed')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Voice input',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _busy ? 0.98 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_busy)
              FadeTransition(
                opacity: _pulse.drive(Tween<double>(begin: 0.3, end: 0.8)),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            FloatingActionButton(
              heroTag: 'voice_fab',
              onPressed: _ready ? _handlePress : null,
              backgroundColor: _ready
                  ? (_busy ? scheme.error : scheme.primary)
                  : scheme.surfaceContainerHighest,
              child: Icon(
                _busy ? Icons.mic : Icons.mic_none,
                color: _ready ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
