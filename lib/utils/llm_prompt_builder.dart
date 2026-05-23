import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class LLMPromptBuilder {
  Map<String, dynamic>? _prompts;

  Future<void> initialize(
      {String path = 'config/prompt_templates.yaml'}) async {
    final yamlString = await rootBundle.loadString(path);
    final yaml = loadYaml(yamlString);
    if (yaml is! YamlMap || yaml['prompts'] == null) {
      throw PromptBuilderException('Invalid prompt templates: missing prompts');
    }
    _prompts = jsonDecode(jsonEncode(yaml))['prompts'] as Map<String, dynamic>;
  }

  Future<String> buildPrompt({
    required String digestKey,
    required String userQuery,
    required String dataDigestJson,
  }) async {
    final template = _template(digestKey);
    return _interpolate(template, {
      'user_query': userQuery,
      'data_digest': dataDigestJson,
    });
  }

  String buildHydrationCoachPrompt({
    required double hydrationPercent,
    required int activityMinutes,
    required double temperatureC,
  }) {
    final template = _template('hydration_coach');
    return _interpolate(template, {
      'hydration': hydrationPercent.toStringAsFixed(1),
      'activity_min': activityMinutes.toString(),
      'temp_c': temperatureC.toStringAsFixed(1),
    });
  }

  String buildReminderNudgePrompt({
    required int shortfallMl,
    required double hoursAgo,
  }) {
    final template = _template('reminder_nudge');
    return _interpolate(template, {
      'shortfall_ml': shortfallMl.toString(),
      'hours_ago': hoursAgo.toStringAsFixed(1),
    });
  }

  String buildSentimentResponsePrompt({
    required String mood,
    required double hydrationPercent,
  }) {
    final template = _template('sentiment_response');
    return _interpolate(template, {
      'mood': mood,
      'hydration': hydrationPercent.toStringAsFixed(1),
    });
  }

  String buildCommandParsingPrompt(String command) {
    return 'Parse this hydration voice command as JSON: $command';
  }

  String _template(String key) {
    final map = _prompts;
    if (map == null) {
      throw PromptBuilderException('LLMPromptBuilder not initialized');
    }
    final entry = map[key];
    if (entry is! Map || entry['template'] is! String) {
      throw PromptBuilderException('Template "$key" not found');
    }
    final template = (entry['template'] as String).trim();
    if (template.isEmpty) {
      throw PromptBuilderException('Template "$key" is empty');
    }
    return template;
  }

  String _interpolate(String template, Map<String, String> variables) {
    var output = template;
    for (final entry in variables.entries) {
      output = output.replaceAll('%${entry.key}%', entry.value);
    }
    return output.trim();
  }
}

class PromptBuilderException implements Exception {
  final String message;

  PromptBuilderException(this.message);

  @override
  String toString() => 'PromptBuilderException: $message';
}
