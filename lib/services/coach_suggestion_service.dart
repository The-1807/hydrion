import '../domain/hydration_contracts.dart';

class LocalCoachSuggestionService implements CoachSuggestionService {
  final HydrationAiProvider _provider;
  final HydrationContextProvider _contextProvider;
  final HydrationAiActionValidator _validator;
  final HydrationAiActionExecutionService _executor;
  final ProviderHealthReporter _providerHealth;
  final Map<String, HydrationAiAction> _pending = <String, HydrationAiAction>{};
  // Single-flight confirmation: a suggestion is claimed (removed from
  // [_pending]) before it executes, so a repeated confirm joins the running
  // execution instead of applying the action twice.
  final Map<String, Future<CoachSuggestionExecutionView>> _inFlight =
      <String, Future<CoachSuggestionExecutionView>>{};
  final Set<String> _dismissedInFlight = <String>{};
  int _nextId = 0;

  LocalCoachSuggestionService({
    required HydrationAiProvider provider,
    required HydrationContextProvider contextProvider,
    required HydrationAiActionValidator validator,
    required HydrationAiActionExecutionService executor,
    required ProviderHealthReporter providerHealth,
  })  : _provider = provider,
        _contextProvider = contextProvider,
        _validator = validator,
        _executor = executor,
        _providerHealth = providerHealth;

  @override
  Future<CoachTurn> ask({
    required String userQuery,
    required HydrationCoachDigestKey digestKey,
  }) async {
    final context = await _contextProvider.getHydrationContext(
      digestKey: digestKey,
    );
    final actions = await _provider.proposeActions(
      context: context,
      userQuery: userQuery,
    );
    final health = _providerHealth.providerHealth;
    final providerSource = health.activeProvider;
    final suggestions = <CoachSuggestionCard>[];
    final messages = <String>[];

    for (final action in actions) {
      final validation = _validator.validate(action, context.capabilities);
      final safeAction = validation.action;
      if (validation.isAllowed && safeAction is CoachMessageAction) {
        messages.add(safeAction.message);
        continue;
      }

      final card = _cardFromAction(
        action: safeAction,
        providerSource: providerSource,
        status: validation.isAllowed
            ? CoachSuggestionStatus.validated
            : CoachSuggestionStatus.rejected,
      );
      if (card == null) {
        if (validation.isAllowed && safeAction.message.trim().isNotEmpty) {
          messages.add(safeAction.message);
        }
        continue;
      }

      suggestions.add(card);
      if (validation.isAllowed && card.requiresConfirmation) {
        _pending[card.id] = safeAction;
      }
    }

    return CoachTurn(
      message: messages.join('\n\n').trim(),
      suggestions: suggestions,
      usedFallback: health.fallbackReason != null &&
          health.selectedProvider != HydrionAiProviderKind.localRules &&
          health.activeProvider == HydrionAiProviderKind.localRules,
    );
  }

  @override
  Future<CoachSuggestionExecutionView> confirm(String suggestionId) {
    final running = _inFlight[suggestionId];
    if (running != null) return running;

    final action = _pending.remove(suggestionId);
    if (action == null) {
      return Future.value(CoachSuggestionExecutionView(
        suggestionId: suggestionId,
        status: CoachSuggestionStatus.rejected,
      ));
    }

    final execution = _execute(suggestionId, action);
    _inFlight[suggestionId] = execution;
    return execution;
  }

  Future<CoachSuggestionExecutionView> _execute(
    String suggestionId,
    HydrationAiAction action,
  ) async {
    var restore = true;
    try {
      final result = await _executor.execute(
        action,
        userConfirmed: true,
      );
      restore = !result.isApplied;
      return CoachSuggestionExecutionView(
        suggestionId: suggestionId,
        status: switch (result.status) {
          HydrationAiActionExecutionStatus.applied =>
            CoachSuggestionStatus.applied,
          HydrationAiActionExecutionStatus.displayOnly =>
            CoachSuggestionStatus.displayOnly,
          HydrationAiActionExecutionStatus.rejected =>
            CoachSuggestionStatus.rejected,
        },
        appliedEntityId: result.appliedEntityId,
      );
    } finally {
      _inFlight.remove(suggestionId);
      final dismissed = _dismissedInFlight.remove(suggestionId);
      // A non-applied (or failed) execution returns the claim so the user
      // can retry, unless the suggestion was dismissed meanwhile.
      if (restore && !dismissed) _pending[suggestionId] = action;
    }
  }

  @override
  void dismiss(String suggestionId) {
    _pending.remove(suggestionId);
    if (_inFlight.containsKey(suggestionId)) {
      _dismissedInFlight.add(suggestionId);
    }
  }

  CoachSuggestionCard? _cardFromAction({
    required HydrationAiAction action,
    required HydrionAiProviderKind providerSource,
    required CoachSuggestionStatus status,
  }) {
    final id = _newSuggestionId();
    if (action is SuggestHydrationLogAction) {
      return CoachSuggestionCard(
        id: id,
        kind: CoachSuggestionKind.hydrationLog,
        providerSource: providerSource,
        message: action.message,
        details: [
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.volumeMl,
            intValue: action.volumeMl,
          ),
        ],
        changesAppState: action.changesAppState,
        requiresConfirmation: action.requiresUserConfirmation,
        status: status,
      );
    }

    if (action is SuggestReminderAction) {
      return CoachSuggestionCard(
        id: id,
        kind: CoachSuggestionKind.reminder,
        providerSource: providerSource,
        message: action.message,
        details: [
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.delayMinutes,
            intValue: action.delay.inMinutes,
          ),
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.priority,
            intValue: action.priority,
          ),
        ],
        changesAppState: action.changesAppState,
        requiresConfirmation: action.requiresUserConfirmation,
        status: status,
      );
    }

    if (action is SuggestChallengeAction) {
      return CoachSuggestionCard(
        id: id,
        kind: CoachSuggestionKind.challenge,
        providerSource: providerSource,
        message: action.message,
        details: [
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.challengeName,
            textValue: action.name,
          ),
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.targetMl,
            intValue: action.targetMl,
          ),
          CoachSuggestionDetail(
            kind: CoachSuggestionDetailKind.durationDays,
            intValue: action.durationDays,
          ),
        ],
        changesAppState: action.changesAppState,
        requiresConfirmation: action.requiresUserConfirmation,
        status: status,
      );
    }

    if (action is ExplainTrendAction) {
      return CoachSuggestionCard(
        id: id,
        kind: CoachSuggestionKind.trendInsight,
        providerSource: providerSource,
        message: action.message,
        changesAppState: action.changesAppState,
        requiresConfirmation: action.requiresUserConfirmation,
        status: status,
      );
    }

    if (action is UnsupportedCapabilityNoticeAction) {
      return CoachSuggestionCard(
        id: id,
        kind: CoachSuggestionKind.unsupportedCapability,
        providerSource: providerSource,
        message: action.message,
        details: [
          if (action.capability != null)
            CoachSuggestionDetail(
              kind: CoachSuggestionDetailKind.capability,
              capability: action.capability,
            ),
        ],
        changesAppState: false,
        requiresConfirmation: false,
        status: status == CoachSuggestionStatus.rejected
            ? CoachSuggestionStatus.rejected
            : CoachSuggestionStatus.displayOnly,
      );
    }

    return null;
  }

  String _newSuggestionId() {
    _nextId += 1;
    return 'coach-suggestion-$_nextId';
  }
}
