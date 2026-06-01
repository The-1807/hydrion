import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/coach_suggestion_service.dart';

void main() {
  test('suggestion service turns valid proposals into pending cards', () async {
    final services = HydrionServices.memory();
    final service = _serviceFor(
      services,
      const _FakeProvider([
        CoachMessageAction(message: 'Steady guidance.'),
        SuggestHydrationLogAction(
          message: 'Log the bottle you just finished.',
          volumeMl: 250,
        ),
        SuggestReminderAction(
          message: 'Check in again soon.',
          delay: Duration(minutes: 30),
          priority: 2,
        ),
        SuggestChallengeAction(
          message: 'Try a steady week.',
          challengeId: 'steady-week',
          name: 'Steady Week',
          description: 'Reach target for seven days.',
          targetMl: 2200,
          durationDays: 7,
        ),
      ]),
    );

    final turn = await service.ask(
      userQuery: 'what should I do?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(turn.message, 'Steady guidance.');
    expect(
      turn.suggestions.map((card) => card.kind),
      containsAll([
        CoachSuggestionKind.hydrationLog,
        CoachSuggestionKind.reminder,
        CoachSuggestionKind.challenge,
      ]),
    );
    expect(services.hydrationRepository.logs, isEmpty);
    expect(services.reminderRepository.reminders, isEmpty);
    expect(services.challengeRepository.activeChallenge, isNull);

    final log = turn.suggestions.singleWhere(
      (card) => card.kind == CoachSuggestionKind.hydrationLog,
    );
    final reminder = turn.suggestions.singleWhere(
      (card) => card.kind == CoachSuggestionKind.reminder,
    );
    final challenge = turn.suggestions.singleWhere(
      (card) => card.kind == CoachSuggestionKind.challenge,
    );

    expect(
        (await service.confirm(log.id)).status, CoachSuggestionStatus.applied);
    expect((await service.confirm(reminder.id)).status,
        CoachSuggestionStatus.applied);
    expect((await service.confirm(challenge.id)).status,
        CoachSuggestionStatus.applied);

    expect(services.hydrationRepository.logs.single.volumeMl, 250);
    expect(services.reminderRepository.reminders.single.priority, 2);
    expect(services.challengeRepository.activeChallenge?.id, 'steady-week');
  });

  test('text-only coach messages pass without mutating local state', () async {
    final services = HydrionServices.memory();
    final service = _serviceFor(
      services,
      const _FakeProvider([
        CoachMessageAction(message: 'Take steady sips.'),
      ]),
    );

    final turn = await service.ask(
      userQuery: 'how am I doing?',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    expect(turn.message, 'Take steady sips.');
    expect(turn.suggestions, isEmpty);
    expect(services.hydrationRepository.logs, isEmpty);
    expect(services.reminderRepository.reminders, isEmpty);
    expect(services.challengeRepository.activeChallenge, isNull);
  });

  test('invalid suggested hydration logs are rejected safely', () async {
    final services = HydrionServices.memory();
    final service = _serviceFor(
      services,
      const _FakeProvider([
        SuggestHydrationLogAction(
          message: 'Log an unsafe amount.',
          volumeMl: 6000,
        ),
      ]),
    );

    final turn = await service.ask(
      userQuery: 'log it',
      digestKey: HydrationCoachDigestKey.weeklyDigest,
    );

    final card = turn.suggestions.single;
    expect(card.kind, CoachSuggestionKind.unsupportedCapability);
    expect(card.status, CoachSuggestionStatus.rejected);
    expect((await service.confirm(card.id)).status,
        CoachSuggestionStatus.rejected);
    expect(services.hydrationRepository.logs, isEmpty);
  });
}

LocalCoachSuggestionService _serviceFor(
  HydrionServices services,
  HydrationAiProvider provider,
) {
  return LocalCoachSuggestionService(
    provider: provider,
    contextProvider: services.hydrationContextProvider,
    validator: services.aiActionValidator,
    executor: services.aiActionExecutor,
    providerHealth: services.providerHealthReporter,
  );
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
