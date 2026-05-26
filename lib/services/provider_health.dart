import '../domain/hydration_contracts.dart';
import 'ai_provider_config.dart';

class LocalProviderHealthReporter implements ProviderHealthReporter {
  ProviderHealthSnapshot _snapshot;

  LocalProviderHealthReporter._(this._snapshot);

  factory LocalProviderHealthReporter.fromConfig(
    HydrionAiRuntimeConfig config,
  ) {
    final selectedProvider = switch (config.provider) {
      HydrionAiProviderSelection.gemini => HydrionAiProviderKind.gemini,
      HydrionAiProviderSelection.localRules => HydrionAiProviderKind.localRules,
    };
    final geminiConfigured = config.gemini.isConfigured;
    final geminiActive = config.provider == HydrionAiProviderSelection.gemini &&
        geminiConfigured;

    return LocalProviderHealthReporter._(
      ProviderHealthSnapshot(
        selectedProvider: selectedProvider,
        activeProvider: geminiActive
            ? HydrionAiProviderKind.gemini
            : HydrionAiProviderKind.localRules,
        localRulesAvailable: true,
        geminiConfigured: geminiConfigured,
        geminiAvailable: geminiActive,
        elkaAvailable: false,
        fallbackReason: config.provider == HydrionAiProviderSelection.gemini &&
                !geminiConfigured
            ? 'Gemini is selected but no API key is configured. Hydrion is using local_rules.'
            : null,
        privacyDisclosureRequired: geminiActive,
        privacyConsentRecorded: !geminiActive,
      ),
    );
  }

  @override
  ProviderHealthSnapshot get providerHealth => _snapshot;

  void recordProviderSuccess(HydrionAiProviderKind provider) {
    if (provider == HydrionAiProviderKind.localRules &&
        _snapshot.selectedProvider != HydrionAiProviderKind.localRules) {
      _snapshot = _snapshot.copyWith(
        activeProvider: HydrionAiProviderKind.localRules,
      );
      return;
    }

    _snapshot = _snapshot.copyWith(
      activeProvider: provider,
      lastProviderFailure: null,
      fallbackReason: null,
      privacyDisclosureRequired: provider != HydrionAiProviderKind.localRules,
      privacyConsentRecorded: provider == HydrionAiProviderKind.localRules
          ? true
          : _snapshot.privacyConsentRecorded,
    );
  }

  void recordProviderFallback({
    required HydrionAiProviderKind failedProvider,
    required String reason,
  }) {
    _snapshot = _snapshot.copyWith(
      activeProvider: HydrionAiProviderKind.localRules,
      lastProviderFailure: '${_providerLabel(failedProvider)}: $reason',
      fallbackReason: reason,
      privacyDisclosureRequired:
          _snapshot.selectedProvider != HydrionAiProviderKind.localRules,
    );
  }

  static String _providerLabel(HydrionAiProviderKind provider) {
    return switch (provider) {
      HydrionAiProviderKind.localRules => 'local_rules',
      HydrionAiProviderKind.gemini => 'Gemini',
      HydrionAiProviderKind.elka => 'ELKA',
    };
  }
}
