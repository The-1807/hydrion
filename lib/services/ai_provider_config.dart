enum HydrionAiProviderSelection {
  localRules('local_rules'),
  gemini('gemini');

  final String configValue;

  const HydrionAiProviderSelection(this.configValue);

  static HydrionAiProviderSelection parse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'gemini' => HydrionAiProviderSelection.gemini,
      _ => HydrionAiProviderSelection.localRules,
    };
  }
}

class GeminiProviderConfig {
  final String apiKey;
  final String model;
  final String apiBaseUrl;
  final Duration timeout;

  const GeminiProviderConfig({
    this.apiKey = '',
    this.model = 'gemini-2.5-flash',
    this.apiBaseUrl = 'https://generativelanguage.googleapis.com',
    this.timeout = const Duration(seconds: 12),
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  String get modelPath {
    final trimmedModel = model.trim();
    if (trimmedModel.startsWith('models/')) {
      return trimmedModel;
    }
    return 'models/$trimmedModel';
  }

  Uri get generateContentUri {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return Uri.parse('$base/v1beta/$modelPath:generateContent');
  }
}

class HydrionAiRuntimeConfig {
  final HydrionAiProviderSelection provider;
  final GeminiProviderConfig gemini;

  const HydrionAiRuntimeConfig({
    this.provider = HydrionAiProviderSelection.localRules,
    this.gemini = const GeminiProviderConfig(),
  });

  factory HydrionAiRuntimeConfig.fromEnvironment() {
    const providerValue = String.fromEnvironment(
      'HYDRION_AI_PROVIDER',
      defaultValue: 'local_rules',
    );
    const apiKey = String.fromEnvironment('HYDRION_GEMINI_API_KEY');
    const model = String.fromEnvironment(
      'HYDRION_GEMINI_MODEL',
      defaultValue: 'gemini-2.5-flash',
    );

    return HydrionAiRuntimeConfig(
      provider: HydrionAiProviderSelection.parse(providerValue),
      gemini: const GeminiProviderConfig(
        apiKey: apiKey,
        model: model,
      ),
    );
  }

  bool get shouldUseGemini =>
      provider == HydrionAiProviderSelection.gemini && gemini.isConfigured;
}
