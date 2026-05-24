import 'voice_llm_bridge.dart';

class VoiceService {
  final VoiceLLMBridge _voiceLLMBridge;

  VoiceService({required VoiceLLMBridge voiceLLMBridge})
      : _voiceLLMBridge = voiceLLMBridge;

  bool get isAvailable => false;

  Future<bool> initialize() async {
    return false;
  }

  Future<String> listenOnce({int maxSeconds = 8}) async {
    return '';
  }

  Future<Map<String, dynamic>> processVoiceCommand({String? transcript}) {
    return _voiceLLMBridge.parseVoiceCommand(transcript ?? '');
  }
}
