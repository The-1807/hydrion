import '../domain/hydration_contracts.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/reminder_repository.dart';

class LocalHydrationAiActionExecutor
    implements HydrationAiActionExecutionService {
  final HydrationRepository _hydrationRepository;
  final ReminderRepository _reminderRepository;
  final ChallengeRepository _challengeRepository;
  final AppCapabilityReporter _capabilityReporter;
  final HydrationAiActionValidator _validator;

  const LocalHydrationAiActionExecutor({
    required HydrationRepository hydrationRepository,
    required ReminderRepository reminderRepository,
    required ChallengeRepository challengeRepository,
    required AppCapabilityReporter capabilityReporter,
    HydrationAiActionValidator validator = const HydrationAiActionValidator(),
  })  : _hydrationRepository = hydrationRepository,
        _reminderRepository = reminderRepository,
        _challengeRepository = challengeRepository,
        _capabilityReporter = capabilityReporter,
        _validator = validator;

  @override
  Future<HydrationAiActionExecutionResult> execute(
    HydrationAiAction action, {
    required bool userConfirmed,
    DateTime? now,
  }) async {
    final capabilities = CapabilityContext.fromAppCapabilities(
      _capabilityReporter.capabilities,
    );
    final validation = _validator.validate(action, capabilities);
    if (!validation.isAllowed) {
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.rejected,
        message: validation.reason,
      );
    }

    if (!validation.canExecute(userConfirmed: userConfirmed)) {
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.rejected,
        message: 'User confirmation is required before Hydrion changes state.',
      );
    }

    final safeAction = validation.action;
    if (!safeAction.changesAppState) {
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.displayOnly,
        message: safeAction.message,
      );
    }

    final current = now ?? DateTime.now();
    if (safeAction is SuggestHydrationLogAction) {
      final log = await _hydrationRepository.addLog(
        volumeMl: safeAction.volumeMl,
        timestamp: current,
        source: safeAction.source,
      );
      if (log == null) {
        return HydrationAiActionExecutionResult(
          originalAction: action,
          validationResult: validation,
          status: HydrationAiActionExecutionStatus.rejected,
          message: 'Hydrion rejected the suggested hydration log.',
        );
      }
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.applied,
        message: 'Hydration log applied.',
        appliedEntityId: log.id,
      );
    }

    if (safeAction is SuggestReminderAction) {
      final reminder = await _reminderRepository.save(
        triggerTime: current.add(safeAction.delay),
        message: safeAction.message,
        priority: safeAction.priority,
      );
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.applied,
        message: 'Local reminder definition applied.',
        appliedEntityId: reminder.id,
      );
    }

    if (safeAction is SuggestChallengeAction) {
      await _challengeRepository.join(
        id: safeAction.challengeId,
        name: safeAction.name,
        description: safeAction.description,
        targetMl: safeAction.targetMl,
        durationDays: safeAction.durationDays,
        joinedAt: current,
      );
      return HydrationAiActionExecutionResult(
        originalAction: action,
        validationResult: validation,
        status: HydrationAiActionExecutionStatus.applied,
        message: 'Local challenge applied.',
        appliedEntityId: safeAction.challengeId,
      );
    }

    return HydrationAiActionExecutionResult(
      originalAction: action,
      validationResult: validation,
      status: HydrationAiActionExecutionStatus.rejected,
      message: 'Hydrion does not execute this action type.',
    );
  }
}
