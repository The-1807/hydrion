import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final uiFiles = Directory('lib/ui')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final adapterFiles = Directory('lib/adapters')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('UI does not import forbidden adapters, packs, SDKs, or wrappers', () {
    final forbiddenImports = <Pattern>[
      RegExp(r'''import\s+['"].*adapters/(elka|local)/'''),
      RegExp(r'''import\s+['"].*packs/'''),
      RegExp(r'''import\s+['"].*services/(ai_bridge|llm_service)\.dart'''),
      RegExp(r'''import\s+['"].*services/hydration_context_builder\.dart'''),
      RegExp(r'''import\s+['"].*services/hydration_ai_action_executor\.dart'''),
      RegExp(r'''import\s+['"].*services/provider_health\.dart'''),
      RegExp(r'''import\s+['"].*dart_openai'''),
      RegExp(r'''import\s+['"].*google_generative_ai'''),
      RegExp(r'''import\s+['"].*openai'''),
      RegExp(r'''import\s+['"].*gemini'''),
      RegExp(r'''import\s+['"].*byok'''),
      RegExp(r'''import\s+['"].*edge_llm'''),
    ];

    final violations = <String>[];

    for (final file in uiFiles) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index].trim();
        if (!line.startsWith('import ')) {
          continue;
        }
        for (final pattern in forbiddenImports) {
          if (line.contains(pattern)) {
            violations.add('${file.path}:${index + 1}: $line');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('UI does not reference deprecated AI compatibility wrappers', () {
    final forbiddenTokens = <Pattern>[
      RegExp(r'\bAIBridge\b'),
      RegExp(r'\bLLMService\b'),
      RegExp(r'\bDigestKey\.'),
      RegExp(r'\bLlmMode\b'),
      RegExp(r'\bHydrationAiProvider\b'),
      RegExp(r'\bHydrationAiAction\b'),
      RegExp(r'\bCoachMessageAction\b'),
      RegExp(r'\bSuggestReminderAction\b'),
      RegExp(r'\bSuggestHydrationLogAction\b'),
      RegExp(r'\bExplainTrendAction\b'),
      RegExp(r'\bSuggestChallengeAction\b'),
      RegExp(r'\bUnsupportedCapabilityNoticeAction\b'),
      RegExp(r'\bHydrationAiActionValidator\b'),
      RegExp(r'\bHydrationAiActionExecutionService\b'),
      RegExp(r'\bLocalHydrationAiActionExecutor\b'),
      RegExp(r'\bproposeActions\s*\('),
    ];
    final violations = <String>[];

    for (final file in uiFiles) {
      final content = file.readAsStringSync();
      for (final token in forbiddenTokens) {
        if (content.contains(token)) {
          violations.add('${file.path}: $token');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('deprecated compatibility wrapper files are removed', () {
    expect(File('lib/services/ai_bridge.dart').existsSync(), isFalse);
    expect(File('lib/services/llm_service.dart').existsSync(), isFalse);
  });

  test('provider adapter shells do not import mutable app state layers', () {
    final forbiddenImports = <Pattern>[
      RegExp(r'''import\s+['"].*repositories/'''),
      RegExp(r'''import\s+['"].*storage/'''),
      RegExp(r'''import\s+['"].*shared_preferences'''),
      RegExp(
          r'''import\s+['"].*services/(notifications|wearable_service|ble_service)\.dart'''),
    ];
    final violations = <String>[];

    for (final file in adapterFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (normalizedPath.contains('/adapters/local/')) {
        continue;
      }
      final content = file.readAsStringSync();
      if (!content.contains('HydrationAiProvider') &&
          !content.contains('AdapterShell')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index].trim();
        if (!line.startsWith('import ')) {
          continue;
        }
        for (final pattern in forbiddenImports) {
          if (line.contains(pattern)) {
            violations.add('${file.path}:${index + 1}: $line');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('pubspec does not add provider SDK dependencies', () {
    final content = File('pubspec.yaml').readAsStringSync();
    final forbiddenDependencies = <Pattern>[
      RegExp(r'^\s*google_generative_ai\s*:', multiLine: true),
      RegExp(r'^\s*dart_openai\s*:', multiLine: true),
      RegExp(r'^\s*openai_dart\s*:', multiLine: true),
      RegExp(r'^\s*langchain_google\s*:', multiLine: true),
      RegExp(r'^\s*firebase_ai\s*:', multiLine: true),
      RegExp(r'^\s*byok\s*:', multiLine: true),
      RegExp(r'^\s*edge_llm\s*:', multiLine: true),
    ];

    final violations = [
      for (final pattern in forbiddenDependencies)
        if (content.contains(pattern)) pattern.toString(),
    ];

    expect(violations, isEmpty);
  });

  test('I18nResolver remains a locale controller without UI string maps', () {
    final content = File('lib/utils/i18n_resolver.dart').readAsStringSync();

    expect(content, isNot(contains('_localizedText')));
    expect(content, isNot(contains('getText(')));
    expect(content, isNot(contains('Map<String, Map<String, String>>')));
  });
}
