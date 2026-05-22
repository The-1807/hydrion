// lib/services/voice_service.dart
import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// VoiceService — wraps speech_to_text with a simple promise-style API.
/// - Call [initialize] once at app start.
/// - [listenOnce] listens up to [maxSeconds] or until final result.
/// - Returns the recognized text (empty on failure).
class VoiceService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    try {
      return await _speech.initialize();
    } catch (_) {
      return false;
    }
  }

  Future<String> listenOnce({int maxSeconds = 8}) async {
    try {
      final ok = await _speech.initialize();
      if (!ok) return '';

      final c = Completer<String>();
      String lastText = '';

      await _speech.listen(
        listenFor: Duration(seconds: maxSeconds),
        pauseFor: const Duration(seconds: 2),
        onResult: (res) {
          lastText = res.recognizedWords;
          if (res.finalResult && !c.isCompleted) c.complete(lastText);
        },
      );

      // Time cap
      final text = await c.future.timeout(
        Duration(seconds: maxSeconds + 2),
        onTimeout: () => lastText,
      );

      await _speech.stop();
      return text;
    } catch (_) {
      try {
        await _speech.stop();
      } catch (_) {}
      return '';
    }
  }

  Future listen() async {}
}
