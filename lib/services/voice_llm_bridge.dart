import 'llm_service.dart';

class VoiceLLMBridge {
  final LLMService _llm;

  VoiceLLMBridge({required LLMService llmService}) : _llm = llmService;

  Future<Map<String, dynamic>> parseVoiceCommand(String speech) async {
    final parsed = await _llm.parseCommandToJson(speech);
    final intent = (parsed['intent'] ?? '').toString().trim();
    final entities = parsed['entities'];

    if (intent.isEmpty || entities is! Map) {
      return {
        'intent': 'unknown_command',
        'entities': {'command': speech},
      };
    }

    return {
      'intent': intent,
      'entities': Map<String, dynamic>.from(entities),
    };
  }
}
