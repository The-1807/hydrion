// lib/utils/llm_prompt_builder.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class LLMPromptBuilder {
  Map<String, dynamic>? _prompts;

  Future<void> initialize({String path = 'hydrion/config/prompt_templates.yaml'}) async {
    final yamlString = await rootBundle.loadString(path);
    final yaml = loadYaml(yamlString);
    if (yaml is! YamlMap || yaml['prompts'] == null) {
      throw PromptBuilderException('Invalid prompt templates: missing "prompts"');
    }
    // Deep convert YamlMap -> Map
    _prompts = jsonDecode(jsonEncode(yaml))['prompts'] as Map<String, dynamic>;
  }

  String buildHydrationCoachPrompt({
    required double hydrationPercent,
    required int activityMinutes,
    required double temperatureC,
  }) {
    final t = _template('hydration_coach');
    return _interpolate(t, {
      'hydration': hydrationPercent.toStringAsFixed(1),
      'activity_min': activityMinutes.toString(),
      'temp_c': temperatureC.toStringAsFixed(1),
    });
  }

  String buildReminderNudgePrompt({
    required int shortfallMl,
    required double hoursAgo,
  }) {
    final t = _template('reminder_nudge');
    return _interpolate(t, {
      'shortfall_ml': shortfallMl.toString(),
      'hours_ago': hoursAgo.toStringAsFixed(1),
    });
  }

  String buildSentimentResponsePrompt({
    required String mood,
    required double hydrationPercent,
  }) {
    final t = _template('sentiment_response');
    return _interpolate(t, {
      'mood': mood,
      'hydration': hydrationPercent.toStringAsFixed(1),
    });
  }

  String _template(String key) {
    final map = _prompts;
    if (map == null) {
      throw PromptBuilderException('LLMPromptBuilder not initialized');
    }
    final entry = map[key];
    if (entry == null || entry['template'] is! String) {
      throw PromptBuilderException('Template "$key" not found');
    }
    final s = (entry['template'] as String).trim();
    if (s.isEmpty) {
      throw PromptBuilderException('Template "$key" is empty');
    }
    return s;
  }

  String _interpolate(String template, Map<String, String> vars) {
    var out = template;
    vars.forEach((k, v) {
      out = out.replaceAll('%$k%', v);
    });
    return out.trim();
  }
}

class PromptBuilderException implements Exception {
  final String message;
  PromptBuilderException(this.message);
  @override
  String toString() => 'PromptBuilderException: $message';
}
