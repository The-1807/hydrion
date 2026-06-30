import 'secret_redaction.dart';

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
  static const String expectedGoogleApiKeyPrefix = 'AIza';

  final String apiKey;
  final String model;
  final String apiBaseUrl;
  final Duration timeout;
  final bool useResponseSchema;

  const GeminiProviderConfig({
    this.apiKey = '',
    this.model = 'gemini-2.5-flash',
    this.apiBaseUrl = 'https://generativelanguage.googleapis.com',
    this.timeout = const Duration(seconds: 12),
    this.useResponseSchema = false,
  });

  String get trimmedApiKey => apiKey.trim();

  bool get isConfigured => trimmedApiKey.isNotEmpty;

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

  GeminiKeyDiagnostics get keyDiagnostics {
    final trimmed = trimmedApiKey;
    return GeminiKeyDiagnostics(
      present: trimmed.isNotEmpty,
      length: trimmed.length,
      fingerprint: SecretRedactor.fingerprint(trimmed),
      containsWhitespace: RegExp(r'\s').hasMatch(apiKey),
      wasTrimmed: apiKey != trimmed,
      startsWithExpectedGoogleApiKeyPrefix:
          trimmed.startsWith(expectedGoogleApiKeyPrefix),
    );
  }

  GeminiRequestDiagnostics get requestDiagnostics {
    final key = trimmedApiKey;
    return GeminiRequestDiagnostics(
      endpointHost: generateContentUri.host,
      modelId: model.trim(),
      modelPath: modelPath,
      authHeaderPresent: key.isNotEmpty,
      authHeaderValueLength: key.length,
    );
  }
}

class GeminiKeyDiagnostics {
  final bool present;
  final int length;
  final String? fingerprint;
  final bool containsWhitespace;
  final bool wasTrimmed;
  final bool startsWithExpectedGoogleApiKeyPrefix;

  const GeminiKeyDiagnostics({
    required this.present,
    required this.length,
    required this.fingerprint,
    required this.containsWhitespace,
    required this.wasTrimmed,
    required this.startsWithExpectedGoogleApiKeyPrefix,
  });
}

class GeminiRequestDiagnostics {
  final String endpointHost;
  final String modelId;
  final String modelPath;
  final bool authHeaderPresent;
  final int authHeaderValueLength;

  const GeminiRequestDiagnostics({
    required this.endpointHost,
    required this.modelId,
    required this.modelPath,
    required this.authHeaderPresent,
    required this.authHeaderValueLength,
  });
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
