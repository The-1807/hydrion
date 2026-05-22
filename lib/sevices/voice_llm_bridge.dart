import 'dart:async';

import 'llm_service.dart';
import 'voice_client.dart';

/// VoiceLLMBridge — routes voice input through the LLM parser and returns a
/// typed command map. No private-field hacks; uses LLMService API.
class VoiceLLMBridge {
  final LLMService _llm;
  final VoiceService _voice;

  VoiceLLMBridge({
    required LLMService llmService,
    required VoiceService voiceService,
  })  : _llm = llmService,
        _voice = voiceService;

  /// Returns {"intent": "...", "entities": {...}}
  Future<Map<String, dynamic>> parseVoiceCommand(String speech) async {
    try {
      final parsed = await _llm.parseCommandToJson(speech);
      // Minimum validation
      final intent = (parsed['intent'] ?? '').toString().trim();
      final ents = parsed['entities'];
      if (intent.isEmpty || ents is! Map) {
        throw const FormatException('Missing intent or entities');
      }
      return {
        'intent': intent,
        'entities': Map<String, dynamic>.from(ents),
      };
    } catch (e) {
      throw VoiceLLMException('Failed to parse voice command: $e');
    }
  }

  /// Full pipeline: listen -> parse -> return command map
  Future<Map<String, dynamic>> processVoiceCommand() async {
    try {
      final speech = await _voice.listen();
      return await parseVoiceCommand(speech);
    } catch (e) {
      throw VoiceLLMException('Voice command processing failed: $e');
    }
  }
}

class VoiceLLMException implements Exception {
  final String message;
  const VoiceLLMException(this.message);
  @override
  String toString() => 'VoiceLLMException: $message';
}
