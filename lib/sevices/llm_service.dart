// app/lib/services/llm_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

// Import the Rust FFI Bridge (Generated in Phase 1)
import 'core_bridge.dart'; // Assumed to be available as the 'skipped' service
import '../utils/llm_prompt_builder.dart'; // Utility to fetch prompt templates
import '../utils/logging.dart'; // Project's logging utility
import '.../packs/edge_llm/bindings/lib/edge_llm_client.dart';

// Pack Clients (Needed for optional cloud integrations)
import 'package:hydrion/pack/byok_llm/client/lib/byok_client.dart';
import 'package:hydrion/packs/gemini_connector/client/lib/gemini_client.dart';
import 'package:hydrion/packs/edge_llm/client/lib/edge_llm_client.dart'; // Adjusted path/name for Edge client

// Enum and Types defined by the project architecture
enum LlmMode { localEdge, byok, gemini, fallback }
enum DigestKey {
  weeklyDigest, // Used for ChatCoachScreen
  reminderNudge, // Used for ReminderTile
  sentimentAnalysis, // Used for VoiceService integration
  commandParsing // Used for VoiceService command input
}

class LlmService {
  // Dependencies are the core FFI bridge and the individual pack clients
  final CoreBridge _core;
  late final ByokClient _byokClient;
  late final GeminiClient _geminiClient;
  late final EdgeLlmClient _edgeLlmClient;

  late final LLMPromptBuilder _promptBuilder;
  late YamlMap _llmPacksConfig;
  bool _initialized = false;

  LlmService(this._core) {
    _promptBuilder = LLMPromptBuilder();
  }

  /// Initializes all LLM clients and loads the packs configuration.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Load the PACKS MANIFEST (config/llm_packs.yaml)
      final yamlString = await rootBundle.loadString('config/llm_packs.yaml');
      _llmPacksConfig = loadYaml(yamlString) as YamlMap;

      // 2. Initialize Core Bridge (assumed complete here, but good practice to check)
      // await _core.initialize(); 

      // 3. Initialize Clients (They will self-check for API keys/model existence)
      _byokClient = ByokClient(
        config: _llmPacksConfig['byok'],
        coreBridge: _core,
      );
      _geminiClient = GeminiClient(
        config: _llmPacksConfig['gemini'],
        coreBridge: _core,
      );
      _edgeLlmClient = EdgeLlmClient(
        config: _llmPacksConfig['edge_llm'],
      );

      await _promptBuilder.initialize(); // Load prompt templates

      _initialized = true;
      Log.i('LLMService initialized. Packs loaded.');
    } catch (e) {
      Log.e('Failed to initialize LLM service, operating in FALLBACK mode: $e');
      _initialized = true; // Mark as initialized to prevent re-attempts, but with caution
      // Initialize clients to non-operational state if needed, but for now we rely on try/catch
      // in the main methods.
    }
  }

  // ---------------------- Public Service Endpoints ----------------------

  /// The unified method for generating all LLM responses (advice, nudges, sentiment).
  /// Replaces the three template-specific methods in the original script.
  Future<String> getCoachingAdvice({
    required String userQuery,
    required DigestKey digestKey,
    LlmMode mode = LlmMode.localEdge, // Default to Local-First
  }) async {
    await initialize();

    try {
      // 1. Fetch the MINIMIZED DIGEST from Rust Core.
      // This is the CRITICAL PRIVACY GATE. Rust logic ensures no raw PII.
      final String digestJson = await _core.coreGetDigest(digestKey.name);
      
      // 2. Build the final prompt using the template and the digest.
      final String finalPrompt = await _promptBuilder.buildPrompt(
        digestKey: digestKey,
        userQuery: userQuery,
        dataDigestJson: digestJson,
      );

      // 3. Route and execute the request based on the selected mode.
      final response = await _routeAndQuery(mode, finalPrompt);
      
      // 4. Validate the response (Layer 7 policy) - Ensure no clinical claims, etc.
      final validatedText = await _core.coreValidateLlmResponse(response);

      return _oneLine(validatedText).ifEmpty(_defaultFallbackResponse(digestKey));

    } on LlmServiceException catch (e) {
      Log.w('LLM query failed for $digestKey in $mode: ${e.message}');
      return _defaultFallbackResponse(digestKey);
    } catch (e) {
      Log.e('Unexpected error during LLM request for $digestKey: $e');
      return _defaultFallbackResponse(digestKey);
    }
  }

  /// Command parsing is handled separately as it requires strict JSON output and a 
  /// lower temperature/different system prompt. This supports the Voice Service (L6).
  Future<Map<String, dynamic>> parseCommandToJson(
    String command, {
    LlmMode mode = LlmMode.localEdge, // Command parsing can be local or cloud
  }) async {
    await initialize();

    final prompt = _promptBuilder.buildCommandParsingPrompt(command);
    
    try {
      final raw = await _routeAndQuery(mode, prompt, isJson: true);
      
      // Sanitization: Strip markdown fences (```json)
      final clean = _stripFences(raw).trim();
      
      final decoded = json.decode(clean);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw LlmServiceException('LLM returned invalid structure.');

    } on LlmServiceException catch (e) {
      Log.e('Command parsing failed: ${e.message}');
      // Return a default, non-functional intent for safety
      return {"intent": "unknown_command", "entities": {"command": command}};
    }
  }

  // ---------------------- Internal Router Logic ----------------------

  Future<String> _routeAndQuery(LlmMode mode, String prompt, {bool isJson = false}) async {
    switch (mode) {
      case LlmMode.localEdge:
        // Attempt local/edge inference first (highest privacy)
        final result = await _edgeLlmClient.query(prompt, isJson: isJson);
        if (result.isNotEmpty) return result;
        // Fallthrough if edge model is not loaded or failed
        Log.w('Edge LLM failed or empty response, attempting BYOK if enabled.');
        // FALLTHROUGH INTENTIONAL (See project's self-healing principle)
        
      case LlmMode.byok:
        if (await _byokClient.isActive) {
          Log.i('Routing to BYOK cloud service.');
          // The BYOK client must ensure redaction/prompt minimization before network call.
          return _byokClient.query(prompt, isJson: isJson);
        }
        // Fallthrough if BYOK is disabled/unconfigured
        
      case LlmMode.gemini:
        if (await _geminiClient.isActive) {
          Log.i('Routing to Gemini cloud service.');
          return _geminiClient.query(prompt, isJson: isJson);
        }
        
      case LlmMode.fallback:
        // If all modes fail, log and return empty string for fallback response.
        throw LlmServiceException('All configured LLM packs failed to respond.');
    }
    // Final check for the path where edge/byok/gemini mode fails or is disabled
    throw LlmServiceException('Specified LLM mode ($mode) is not available or failed.');
  }


  // ---------------------- Utils ----------------------

  String _stripFences(String s) {
    final re = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
    );
    final m = re.firstMatch(s.trim());
    return m != null ? m.group(1)!.trim() : s;
  }

  String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _defaultFallbackResponse(DigestKey key) {
    // Provide safe, non-LLM generated responses for different contexts
    switch (key) {
      case DigestKey.weeklyDigest:
        return 'Check your hydration score and stay on track!';
      case DigestKey.reminderNudge:
        return 'Time to sip! Your reminder system is running locally.';
      case DigestKey.sentimentAnalysis:
        return 'A well-hydrated body supports a clear mind.';
      case DigestKey.commandParsing:
        return 'Sorry, I missed that command. Please try again.';
    }
  }
}

class LlmServiceException implements Exception {
  final String message;
  LlmServiceException(this.message);
  @override
  String toString() => 'LlmServiceException: $message';