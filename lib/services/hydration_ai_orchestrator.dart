import 'dart:async';

import '../domain/hydration_contracts.dart';
import 'ai_provider_config.dart';
import 'provider_health.dart';

class ProviderBackedHydrationCoach
    implements HydrationCoach, HydrationAiProvider {
  final HydrionAiProviderSelection selectedProvider;
  final HydrationAiProvider primaryProvider;
  final HydrationAiProvider localRulesProvider;
  final HydrationContextProvider contextProvider;
  final HydrationAiActionValidator actionValidator;
  final LocalProviderHealthReporter? providerHealth;
  final Duration providerTimeout;

  const ProviderBackedHydrationCoach({
    required this.selectedProvider,
    required this.primaryProvider,
    required this.localRulesProvider,
    required this.contextProvider,
    this.actionValidator = const HydrationAiActionValidator(),
    this.providerHealth,
    this.providerTimeout = const Duration(seconds: 14),
  });

  @override
  Future<String> getHydrationCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) async {
    if (selectedProvider != HydrionAiProviderSelection.gemini) {
      return _localCoachResponse(
        hydrationPercent: hydrationPercent,
        entryCount: entryCount,
        activityMinutes: activityMinutes,
        temperatureC: temperatureC,
      );
    }

    final context = await contextProvider.getHydrationContext();
    final actions = await _trustedProviderActions(
      provider: primaryProvider,
      context: context,
      userQuery:
          'Give a short hydration coaching message. Hydration is ${hydrationPercent.toStringAsFixed(1)} percent, entries are ${entryCount ?? activityMinutes ?? 0}, and temperature is ${temperatureC.toStringAsFixed(1)} Celsius.',
    );
    if (actions.isNotEmpty) {
      return actions.first.message;
    }

    return _localCoachResponse(
      hydrationPercent: hydrationPercent,
      entryCount: entryCount,
      activityMinutes: activityMinutes,
      temperatureC: temperatureC,
    );
  }

  @override
  Future<String> getCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    if (selectedProvider != HydrionAiProviderSelection.gemini) {
      return _localCoachingAdvice(
        userQuery: userQuery,
        digestKey: digestKey,
      );
    }

    final context = await contextProvider.getHydrationContext(
      digestKey: digestKey,
    );
    final actions = await _trustedProviderActions(
      provider: primaryProvider,
      context: context,
      userQuery: userQuery,
    );
    if (actions.isNotEmpty) {
      return actions.first.message;
    }

    return _localCoachingAdvice(
      userQuery: userQuery,
      digestKey: digestKey,
    );
  }

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    if (selectedProvider == HydrionAiProviderSelection.gemini) {
      final primaryActions = await _trustedProviderActions(
        provider: primaryProvider,
        context: context,
        userQuery: userQuery,
      );
      if (primaryActions.isNotEmpty) {
        return primaryActions;
      }
    }

    return _trustedProviderActions(
      provider: localRulesProvider,
      context: context,
      userQuery: userQuery,
      fallbackToEmpty: false,
    );
  }

  Future<List<HydrationAiAction>> _trustedProviderActions({
    required HydrationAiProvider provider,
    required HydrationContext context,
    required String userQuery,
    bool fallbackToEmpty = true,
  }) async {
    final providerKind = _providerKind(provider);
    try {
      providerHealth?.recordProviderAttempt(providerKind);
      final actions = await provider
          .proposeActions(
            context: context,
            userQuery: userQuery,
          )
          .timeout(providerTimeout);
      final validationResults =
          actionValidator.validateAll(actions, context.capabilities);
      final allowed = _allowedActions(validationResults);
      if (allowed.isEmpty && actions.isNotEmpty) {
        final blocked = validationResults.firstWhere(
          (result) => !result.isAllowed,
          orElse: () => validationResults.first,
        );
        final diagnostic = _validatorDiagnostic(
          providerKind: providerKind,
          context: context,
          result: blocked,
        );
        providerHealth?.recordProviderFallback(
          failedProvider: providerKind,
          reason: 'validator_rejected: Provider returned no safe actions after '
              'validation. local_rules is active.',
          diagnostic: diagnostic,
        );
      } else if (allowed.isNotEmpty) {
        providerHealth?.recordProviderSuccess(providerKind);
      }
      return allowed;
    } on TimeoutException {
      providerHealth?.recordProviderFallback(
        failedProvider: providerKind,
        reason: 'timeout: Provider timed out. local_rules is active.',
        diagnostic: _failureDiagnostic(
          providerKind: providerKind,
          context: context,
          failure: const _TimeoutDiagnosticFailure(),
        ),
      );
      if (fallbackToEmpty) {
        return const <HydrationAiAction>[];
      }
      rethrow;
    } catch (error) {
      final diagnostic = _failureDiagnostic(
        providerKind: providerKind,
        context: context,
        failure: error is ProviderDiagnosticFailure ? error : null,
      );
      providerHealth?.recordProviderFallback(
        failedProvider: providerKind,
        reason: _failureReason(error),
        diagnostic: diagnostic,
      );
      if (fallbackToEmpty) {
        return const <HydrationAiAction>[];
      }
      rethrow;
    }
  }

  List<HydrationAiAction> _allowedActions(
    Iterable<HydrationAiActionValidationResult> results,
  ) {
    return [
      for (final result in results)
        if (result.isAllowed) result.action,
    ];
  }

  ProviderDiagnosticSnapshot _failureDiagnostic({
    required HydrionAiProviderKind providerKind,
    required HydrationContext context,
    ProviderDiagnosticFailure? failure,
  }) {
    final httpStatus = failure?.httpStatusCode;
    final base = providerHealth?.providerHealth.diagnostic;
    return ProviderDiagnosticSnapshot(
      selectedProvider: selectedProvider == HydrionAiProviderSelection.gemini
          ? HydrionAiProviderKind.gemini
          : HydrionAiProviderKind.localRules,
      activeProvider: HydrionAiProviderKind.localRules,
      configured: context.capabilities.geminiConfigured,
      modelId: base?.modelId,
      endpointHost: base?.endpointHost,
      modelPath: base?.modelPath,
      apiKeyPresent: base?.apiKeyPresent,
      apiKeyLength: base?.apiKeyLength,
      apiKeyFingerprint: base?.apiKeyFingerprint,
      apiKeyContainsWhitespace: base?.apiKeyContainsWhitespace,
      apiKeyWasTrimmed: base?.apiKeyWasTrimmed,
      apiKeyStartsWithExpectedGooglePrefix:
          base?.apiKeyStartsWithExpectedGooglePrefix,
      authHeaderPresent: base?.authHeaderPresent,
      authHeaderValueLength: base?.authHeaderValueLength,
      requestAttempted: providerKind != HydrionAiProviderKind.localRules &&
          failure?.diagnosticCode != ProviderDiagnosticCodes.noApiKey,
      httpStatusClass: httpStatus == null ? null : '${httpStatus ~/ 100}xx',
      timedOut: failure?.timedOut ?? false,
      responseEnvelopePhase: failure?.responseEnvelopePhase ??
          failure?.diagnosticCode ??
          ProviderDiagnosticCodes.providerFailure,
      parserRejectionCode: failure?.parserRejectionCode,
      validatorRejectionCode: failure?.validatorRejectionCode,
      blockedCapabilityLabels:
          failure?.blockedCapabilityLabels ?? const <String>[],
      providerErrorStatus: failure?.providerErrorStatus,
      providerErrorMessage: failure?.providerErrorMessage,
      providerErrorDetailTypes:
          failure?.providerErrorDetailTypes ?? const <String>[],
    );
  }

  ProviderDiagnosticSnapshot _validatorDiagnostic({
    required HydrionAiProviderKind providerKind,
    required HydrationContext context,
    required HydrationAiActionValidationResult result,
  }) {
    final base = providerHealth?.providerHealth.diagnostic;
    return ProviderDiagnosticSnapshot(
      selectedProvider: selectedProvider == HydrionAiProviderSelection.gemini
          ? HydrionAiProviderKind.gemini
          : HydrionAiProviderKind.localRules,
      activeProvider: HydrionAiProviderKind.localRules,
      configured: context.capabilities.geminiConfigured,
      modelId: base?.modelId,
      endpointHost: base?.endpointHost,
      modelPath: base?.modelPath,
      apiKeyPresent: base?.apiKeyPresent,
      apiKeyLength: base?.apiKeyLength,
      apiKeyFingerprint: base?.apiKeyFingerprint,
      apiKeyContainsWhitespace: base?.apiKeyContainsWhitespace,
      apiKeyWasTrimmed: base?.apiKeyWasTrimmed,
      apiKeyStartsWithExpectedGooglePrefix:
          base?.apiKeyStartsWithExpectedGooglePrefix,
      authHeaderPresent: base?.authHeaderPresent,
      authHeaderValueLength: base?.authHeaderValueLength,
      requestAttempted: providerKind != HydrionAiProviderKind.localRules,
      responseEnvelopePhase: ProviderDiagnosticCodes.responseDecoded,
      validatorRejectionCode: result.blockedCapabilities.isEmpty
          ? ProviderDiagnosticCodes.validatorRejected
          : ProviderDiagnosticCodes.unsafeCapabilityClaim,
      blockedCapabilityLabels: [
        for (final capability in result.blockedCapabilities)
          _capabilityLabel(capability),
      ],
    );
  }

  String _failureReason(Object error) {
    if (error is ProviderDiagnosticFailure) {
      return switch (error.diagnosticCode) {
        ProviderDiagnosticCodes.noApiKey =>
          'no_api_key: Gemini is not configured. local_rules is active.',
        ProviderDiagnosticCodes.httpFailure =>
          'http_failure: Gemini returned ${_statusClass(error.httpStatusCode)}. '
              'local_rules is active.',
        ProviderDiagnosticCodes.timeout =>
          'timeout: Gemini request timed out. local_rules is active.',
        ProviderDiagnosticCodes.noCandidates ||
        ProviderDiagnosticCodes.noContent ||
        ProviderDiagnosticCodes.noParts ||
        ProviderDiagnosticCodes.emptyText ||
        ProviderDiagnosticCodes.responseJsonDecodeFailed =>
          '${error.diagnosticCode}: Gemini response envelope was invalid. '
              'local_rules is active.',
        ProviderDiagnosticCodes.jsonDecodeFailed ||
        ProviderDiagnosticCodes.outputNotJson ||
        ProviderDiagnosticCodes.missingActions ||
        ProviderDiagnosticCodes.emptyActions ||
        ProviderDiagnosticCodes.tooManyActions ||
        ProviderDiagnosticCodes.invalidActionSchema ||
        ProviderDiagnosticCodes.unknownActionType ||
        ProviderDiagnosticCodes.missingRequiredField ||
        ProviderDiagnosticCodes.oversizedMessage ||
        ProviderDiagnosticCodes.invalidHydrationAmount ||
        ProviderDiagnosticCodes.invalidReminderDelay ||
        ProviderDiagnosticCodes.invalidChallengeShape ||
        ProviderDiagnosticCodes.unknownCapability =>
          '${error.diagnosticCode}: Gemini output did not match Hydrion '
              'action schema. local_rules is active.',
        _ => '${error.diagnosticCode}: Provider failed. local_rules is active.',
      };
    }
    return 'provider_failure: Provider failed. local_rules is active.';
  }

  String _statusClass(int? statusCode) {
    if (statusCode == null) {
      return 'unknown status';
    }
    return '${statusCode ~/ 100}xx';
  }

  String _capabilityLabel(HydrionCapability capability) {
    return switch (capability) {
      HydrionCapability.localPersistence => 'local persistence',
      HydrionCapability.elka => 'ELKA',
      HydrionCapability.gemini => 'Gemini',
      HydrionCapability.cloudAi => 'cloud AI',
      HydrionCapability.cloudSync => 'cloud sync',
      HydrionCapability.voiceInput => 'voice input',
      HydrionCapability.bleSync => 'BLE sync',
      HydrionCapability.healthSync => 'Health sync',
      HydrionCapability.osNotifications => 'OS notifications',
      HydrionCapability.arVisualization => 'AR visualization',
      HydrionCapability.socialSync => 'social sync',
    };
  }

  Future<String> _localCoachResponse({
    required double hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required double temperatureC,
  }) {
    final localCoach = localRulesProvider as HydrationCoach;
    return localCoach.getHydrationCoachResponse(
      hydrationPercent: hydrationPercent,
      entryCount: entryCount,
      activityMinutes: activityMinutes,
      temperatureC: temperatureC,
    );
  }

  Future<String> _localCoachingAdvice({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) {
    final localCoach = localRulesProvider as HydrationCoach;
    return localCoach.getCoachingAdvice(
      userQuery: userQuery,
      digestKey: digestKey,
    );
  }

  HydrionAiProviderKind _providerKind(HydrationAiProvider provider) {
    if (identical(provider, localRulesProvider)) {
      return HydrionAiProviderKind.localRules;
    }
    if (selectedProvider == HydrionAiProviderSelection.gemini) {
      return HydrionAiProviderKind.gemini;
    }
    return HydrionAiProviderKind.localRules;
  }
}

class _TimeoutDiagnosticFailure implements ProviderDiagnosticFailure {
  const _TimeoutDiagnosticFailure();

  @override
  List<String> get blockedCapabilityLabels => const <String>[];

  @override
  String get diagnosticCode => ProviderDiagnosticCodes.timeout;

  @override
  int? get httpStatusCode => null;

  @override
  String? get parserRejectionCode => null;

  @override
  List<String> get providerErrorDetailTypes => const <String>[];

  @override
  String? get providerErrorMessage => null;

  @override
  String? get providerErrorStatus => null;

  @override
  String? get responseEnvelopePhase => ProviderDiagnosticCodes.timeout;

  @override
  bool get timedOut => true;

  @override
  String? get validatorRejectionCode => null;
}
