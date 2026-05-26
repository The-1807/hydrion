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
    try {
      final actions = await provider
          .proposeActions(
            context: context,
            userQuery: userQuery,
          )
          .timeout(providerTimeout);
      final allowed = _allowedActions(actions, context.capabilities);
      if (allowed.isEmpty && actions.isNotEmpty) {
        providerHealth?.recordProviderFallback(
          failedProvider: _providerKind(provider),
          reason: 'Provider returned no safe actions after validation.',
        );
      } else if (allowed.isNotEmpty) {
        providerHealth?.recordProviderSuccess(_providerKind(provider));
      }
      return allowed;
    } catch (_) {
      providerHealth?.recordProviderFallback(
        failedProvider: _providerKind(provider),
        reason: 'Provider failed or timed out; local_rules is active.',
      );
      if (fallbackToEmpty) {
        return const <HydrationAiAction>[];
      }
      rethrow;
    }
  }

  List<HydrationAiAction> _allowedActions(
    Iterable<HydrationAiAction> actions,
    CapabilityContext capabilities,
  ) {
    return [
      for (final result in actionValidator.validateAll(actions, capabilities))
        if (result.isAllowed) result.action,
    ];
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
