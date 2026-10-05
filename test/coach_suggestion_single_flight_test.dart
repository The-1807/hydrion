import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/coach_suggestion_service.dart';

/// Wave 0 D4: confirming one AI suggestion twice must execute it once.
void main() {
  Future<String> askForLog(LocalCoachSuggestionService service) async {
    final turn = await service.ask(
      userQuery: 'log it',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );
    return turn.suggestions
        .singleWhere((card) => card.kind == CoachSuggestionKind.hydrationLog)
        .id;
  }

  test('two quick confirms log water once through the real executor', () async {
    final services = HydrionServices.memory();
    final service = _service(services, services.aiActionExecutor);
    final id = await askForLog(service);

    final first = service.confirm(id);
    final second = service.confirm(id);
    final views = await Future.wait([first, second]);

    expect(services.hydrationRepository.logs, hasLength(1));
    expect(services.hydrationRepository.logs.single.volumeMl, 250);
    for (final view in views) {
      expect(view.status, CoachSuggestionStatus.applied);
      expect(view.appliedEntityId, services.hydrationRepository.logs.single.id);
    }
    // Once applied, the suggestion is consumed.
    expect((await service.confirm(id)).status, CoachSuggestionStatus.rejected);
    expect(services.hydrationRepository.logs, hasLength(1));
  });

  test('a confirm during a pending execution joins it', () async {
    final services = HydrionServices.memory();
    final executor = _GatedExecutor();
    final service = _service(services, executor);
    final id = await askForLog(service);

    final first = service.confirm(id);
    final second = service.confirm(id);
    await Future<void>.delayed(Duration.zero);
    expect(executor.calls, 1);
    executor.complete(HydrationAiActionExecutionStatus.applied);
    expect((await first).status, CoachSuggestionStatus.applied);
    expect((await second).status, CoachSuggestionStatus.applied);
    expect(executor.calls, 1);
  });

  test('a non-applied result restores the suggestion for retry', () async {
    final services = HydrionServices.memory();
    final executor = _GatedExecutor();
    final service = _service(services, executor);
    final id = await askForLog(service);

    final rejected = service.confirm(id);
    executor.complete(HydrationAiActionExecutionStatus.rejected);
    expect((await rejected).status, CoachSuggestionStatus.rejected);

    final retry = service.confirm(id);
    await Future<void>.delayed(Duration.zero);
    expect(executor.calls, 2);
    executor.complete(HydrationAiActionExecutionStatus.applied);
    expect((await retry).status, CoachSuggestionStatus.applied);
  });

  test('a failed execution restores the suggestion for retry', () async {
    final services = HydrionServices.memory();
    final executor = _GatedExecutor();
    final service = _service(services, executor);
    final id = await askForLog(service);

    final failing = service.confirm(id);
    executor.fail(StateError('synthetic'));
    await expectLater(failing, throwsStateError);

    final retry = service.confirm(id);
    executor.complete(HydrationAiActionExecutionStatus.applied);
    expect((await retry).status, CoachSuggestionStatus.applied);
    expect(executor.calls, 2);
  });

  test('dismiss during execution is not undone by a non-applied result',
      () async {
    final services = HydrionServices.memory();
    final executor = _GatedExecutor();
    final service = _service(services, executor);
    final id = await askForLog(service);

    final pending = service.confirm(id);
    service.dismiss(id);
    executor.complete(HydrationAiActionExecutionStatus.rejected);
    await pending;
    expect((await service.confirm(id)).status, CoachSuggestionStatus.rejected);
    expect(executor.calls, 1);
  });
}

LocalCoachSuggestionService _service(
  HydrionServices services,
  HydrationAiActionExecutionService executor,
) {
  return LocalCoachSuggestionService(
    provider: const _FakeProvider([
      SuggestHydrationLogAction(
        message: 'Log the bottle you just finished.',
        volumeMl: 250,
      ),
    ]),
    contextProvider: services.hydrationContextProvider,
    validator: services.aiActionValidator,
    executor: executor,
    providerHealth: services.providerHealthReporter,
  );
}

class _GatedExecutor implements HydrationAiActionExecutionService {
  int calls = 0;
  Completer<HydrationAiActionExecutionResult>? _gate;
  HydrationAiAction? _action;

  @override
  Future<HydrationAiActionExecutionResult> execute(
    HydrationAiAction action, {
    required bool userConfirmed,
    DateTime? now,
  }) {
    calls += 1;
    _action = action;
    return (_gate = Completer<HydrationAiActionExecutionResult>()).future;
  }

  void complete(HydrationAiActionExecutionStatus status) {
    final action = _action!;
    _gate!.complete(HydrationAiActionExecutionResult(
      originalAction: action,
      validationResult: HydrationAiActionValidationResult(
        originalAction: action,
        action: action,
        isAllowed: true,
        blockedCapabilities: const [],
        reason: 'synthetic',
      ),
      status: status,
      messageCode: status == HydrationAiActionExecutionStatus.applied
          ? HydrationAiExecutionMessageCode.hydrationLogApplied
          : HydrationAiExecutionMessageCode.hydrationLogRejected,
      appliedEntityId: status == HydrationAiActionExecutionStatus.applied
          ? 'synthetic-log'
          : null,
    ));
  }

  void fail(Object error) => _gate!.completeError(error);
}

class _FakeProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;

  const _FakeProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return actions;
  }
}
