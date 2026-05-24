import '../domain/hydration_contracts.dart';

class VoiceLLMBridge {
  final HydrationCommandParser _commandParser;

  VoiceLLMBridge({required HydrationCommandParser commandParser})
      : _commandParser = commandParser;

  Future<Map<String, dynamic>> parseVoiceCommand(String speech) async {
    final parsed = await _commandParser.parseCommandToJson(speech);
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
