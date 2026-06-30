import '../domain/hydration_contracts.dart';
import 'ai_provider_config.dart';

class LocalProviderHealthReporter extends ProviderHealthReporter {
  ProviderHealthSnapshot _snapshot;

  LocalProviderHealthReporter._(this._snapshot);

  factory LocalProviderHealthReporter.fromConfig(
    HydrionAiRuntimeConfig config, {
    bool privacyConsentGranted = false,
  }) {
    final selectedProvider = switch (config.provider) {
      HydrionAiProviderSelection.gemini => HydrionAiProviderKind.gemini,
      HydrionAiProviderSelection.localRules => HydrionAiProviderKind.localRules,
    };
    final geminiConfigured = config.gemini.isConfigured;
    final geminiSelected = config.provider == HydrionAiProviderSelection.gemini;
    final geminiActivation = ExternalIntegrationActivation(
      configured: geminiConfigured,
      enabledByUser: geminiSelected,
      disclosureVisible: geminiSelected,
      consentGranted: privacyConsentGranted,
    );
    final geminiActive = geminiActivation.canReportActive;
    final keyDiagnostic = config.gemini.keyDiagnostics;
    final requestDiagnostic = config.gemini.requestDiagnostics;
    final fallbackReason = geminiSelected && !geminiConfigured
        ? 'no_api_key: Gemini is selected but no API key is configured. '
            'Hydrion is using local_rules.'
        : geminiSelected && !privacyConsentGranted
            ? 'provider_consent_required: Gemini is configured but disabled '
                'until provider privacy consent is enabled. Hydrion is using '
                'local_rules.'
            : null;
    final diagnostic = ProviderDiagnosticSnapshot(
      selectedProvider: selectedProvider,
      activeProvider: geminiActive
          ? HydrionAiProviderKind.gemini
          : HydrionAiProviderKind.localRules,
      configured: geminiConfigured,
      modelId: geminiSelected ? config.gemini.model : null,
      endpointHost: geminiSelected ? requestDiagnostic.endpointHost : null,
      modelPath: geminiSelected ? requestDiagnostic.modelPath : null,
      apiKeyPresent: geminiSelected ? keyDiagnostic.present : null,
      apiKeyLength: geminiSelected ? keyDiagnostic.length : null,
      apiKeyFingerprint: geminiSelected ? keyDiagnostic.fingerprint : null,
      apiKeyContainsWhitespace:
          geminiSelected ? keyDiagnostic.containsWhitespace : null,
      apiKeyWasTrimmed: geminiSelected ? keyDiagnostic.wasTrimmed : null,
      apiKeyStartsWithExpectedGooglePrefix: geminiSelected
          ? keyDiagnostic.startsWithExpectedGoogleApiKeyPrefix
          : null,
      authHeaderPresent:
          geminiSelected ? requestDiagnostic.authHeaderPresent : null,
      authHeaderValueLength:
          geminiSelected ? requestDiagnostic.authHeaderValueLength : null,
      responseEnvelopePhase: fallbackReason == null
          ? ProviderDiagnosticCodes.notAttempted
          : !geminiConfigured
              ? ProviderDiagnosticCodes.noApiKey
              : ProviderDiagnosticCodes.providerConsentRequired,
      fallbackReason: fallbackReason,
    );

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
        fallbackReason: fallbackReason,
        privacyDisclosureRequired: geminiSelected && geminiConfigured,
        privacyConsentRecorded: !geminiSelected || privacyConsentGranted,
        diagnostic: diagnostic,
      ),
    );
  }

  @override
  ProviderHealthSnapshot get providerHealth => _snapshot;

  @override
  void updatePrivacyConsent(bool consentGranted) {
    final geminiSelected =
        _snapshot.selectedProvider == HydrionAiProviderKind.gemini;
    final geminiActive =
        geminiSelected && _snapshot.geminiConfigured && consentGranted;
    final fallbackReason = geminiSelected && !_snapshot.geminiConfigured
        ? 'no_api_key: Gemini is selected but no API key is configured. '
            'Hydrion is using local_rules.'
        : geminiSelected && !consentGranted
            ? 'provider_consent_required: Gemini is configured but disabled '
                'until provider privacy consent is enabled. Hydrion is using '
                'local_rules.'
            : null;
    final diagnostic = _snapshot.diagnostic.copyWith(
      activeProvider: geminiActive
          ? HydrionAiProviderKind.gemini
          : HydrionAiProviderKind.localRules,
      responseEnvelopePhase: fallbackReason == null
          ? ProviderDiagnosticCodes.notAttempted
          : !_snapshot.geminiConfigured
              ? ProviderDiagnosticCodes.noApiKey
              : ProviderDiagnosticCodes.providerConsentRequired,
      requestAttempted: false,
      fallbackReason: fallbackReason,
      lastSuccessAt: null,
      lastFailureAt: null,
    );
    _snapshot = _snapshot.copyWith(
      activeProvider: geminiActive
          ? HydrionAiProviderKind.gemini
          : HydrionAiProviderKind.localRules,
      geminiAvailable: geminiActive,
      lastProviderFailure: null,
      fallbackReason: fallbackReason,
      privacyDisclosureRequired: geminiSelected && _snapshot.geminiConfigured,
      privacyConsentRecorded: !geminiSelected || consentGranted,
      diagnostic: diagnostic,
    );
    notifyListeners();
  }

  void recordProviderAttempt(HydrionAiProviderKind provider) {
    final diagnostic = _snapshot.diagnostic.copyWith(
      activeProvider: provider,
      requestAttempted: provider != HydrionAiProviderKind.localRules,
      responseEnvelopePhase: ProviderDiagnosticCodes.requestAttempted,
      parserRejectionCode: null,
      validatorRejectionCode: null,
      blockedCapabilityLabels: const <String>[],
      providerErrorStatus: null,
      providerErrorMessage: null,
      providerErrorDetailTypes: const <String>[],
      fallbackReason: null,
      httpStatusClass: null,
      timedOut: false,
    );
    _snapshot = _snapshot.copyWith(diagnostic: diagnostic);
    notifyListeners();
  }

  void recordProviderSuccess(HydrionAiProviderKind provider) {
    final now = DateTime.now();
    if (provider == HydrionAiProviderKind.localRules &&
        _snapshot.selectedProvider != HydrionAiProviderKind.localRules) {
      _snapshot = _snapshot.copyWith(
        activeProvider: HydrionAiProviderKind.localRules,
        diagnostic: _snapshot.diagnostic.copyWith(
          activeProvider: HydrionAiProviderKind.localRules,
          responseEnvelopePhase: ProviderDiagnosticCodes.localRulesActive,
        ),
      );
      notifyListeners();
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
      diagnostic: _snapshot.diagnostic.copyWith(
        activeProvider: provider,
        requestAttempted: provider != HydrionAiProviderKind.localRules ||
            _snapshot.diagnostic.requestAttempted,
        responseEnvelopePhase: ProviderDiagnosticCodes.success,
        parserRejectionCode: null,
        validatorRejectionCode: null,
        blockedCapabilityLabels: const <String>[],
        providerErrorStatus: null,
        providerErrorMessage: null,
        providerErrorDetailTypes: const <String>[],
        fallbackReason: null,
        httpStatusClass: null,
        timedOut: false,
        lastSuccessAt: now,
      ),
    );
    notifyListeners();
  }

  void recordProviderFallback({
    required HydrionAiProviderKind failedProvider,
    required String reason,
    ProviderDiagnosticSnapshot? diagnostic,
  }) {
    final now = DateTime.now();
    final incomingDiagnostic = diagnostic ?? _snapshot.diagnostic;
    final requestAttempted = incomingDiagnostic.responseEnvelopePhase ==
            ProviderDiagnosticCodes.noApiKey
        ? false
        : failedProvider != HydrionAiProviderKind.localRules ||
            _snapshot.diagnostic.requestAttempted;
    final safeDiagnostic = incomingDiagnostic.copyWith(
      selectedProvider: _snapshot.selectedProvider,
      activeProvider: HydrionAiProviderKind.localRules,
      configured: _snapshot.geminiConfigured,
      modelId: incomingDiagnostic.modelId ?? _snapshot.diagnostic.modelId,
      endpointHost:
          incomingDiagnostic.endpointHost ?? _snapshot.diagnostic.endpointHost,
      modelPath: incomingDiagnostic.modelPath ?? _snapshot.diagnostic.modelPath,
      apiKeyPresent: incomingDiagnostic.apiKeyPresent ??
          _snapshot.diagnostic.apiKeyPresent,
      apiKeyLength:
          incomingDiagnostic.apiKeyLength ?? _snapshot.diagnostic.apiKeyLength,
      apiKeyFingerprint: incomingDiagnostic.apiKeyFingerprint ??
          _snapshot.diagnostic.apiKeyFingerprint,
      apiKeyContainsWhitespace: incomingDiagnostic.apiKeyContainsWhitespace ??
          _snapshot.diagnostic.apiKeyContainsWhitespace,
      apiKeyWasTrimmed: incomingDiagnostic.apiKeyWasTrimmed ??
          _snapshot.diagnostic.apiKeyWasTrimmed,
      apiKeyStartsWithExpectedGooglePrefix:
          incomingDiagnostic.apiKeyStartsWithExpectedGooglePrefix ??
              _snapshot.diagnostic.apiKeyStartsWithExpectedGooglePrefix,
      authHeaderPresent: incomingDiagnostic.authHeaderPresent ??
          _snapshot.diagnostic.authHeaderPresent,
      authHeaderValueLength: incomingDiagnostic.authHeaderValueLength ??
          _snapshot.diagnostic.authHeaderValueLength,
      requestAttempted: requestAttempted,
      fallbackReason: reason,
      lastFailureAt: now,
    );
    _snapshot = _snapshot.copyWith(
      activeProvider: HydrionAiProviderKind.localRules,
      lastProviderFailure: '${_providerLabel(failedProvider)}: $reason',
      fallbackReason: reason,
      privacyDisclosureRequired:
          _snapshot.selectedProvider != HydrionAiProviderKind.localRules,
      diagnostic: safeDiagnostic,
    );
    notifyListeners();
  }

  static String _providerLabel(HydrionAiProviderKind provider) {
    return switch (provider) {
      HydrionAiProviderKind.localRules => 'local_rules',
      HydrionAiProviderKind.gemini => 'Gemini',
      HydrionAiProviderKind.elka => 'ELKA',
    };
  }
}
