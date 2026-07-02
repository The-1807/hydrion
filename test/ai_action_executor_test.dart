import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/hydration_ai_action_executor.dart';

void main() {
  late HydrationRepository hydrationRepository;
  late ReminderRepository reminderRepository;
  late ChallengeRepository challengeRepository;
  late LocalHydrationAiActionExecutor executor;

  setUp(() {
    hydrationRepository = HydrationRepository.memory();
    reminderRepository = ReminderRepository.memory();
    challengeRepository = ChallengeRepository.memory();
    executor = LocalHydrationAiActionExecutor(
      hydrationRepository: hydrationRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      capabilityReporter: LocalAppCapabilityReporter(),
    );
  });

  test('executor rejects unconfirmed state-changing actions', () async {
    const action = SuggestHydrationLogAction(
      message: 'Suggest logging 250 ml.',
      volumeMl: 250,
    );

    final result = await executor.execute(
      action,
      userConfirmed: false,
      now: DateTime(2026, 5, 26, 10),
    );

    expect(result.status, HydrationAiActionExecutionStatus.rejected);
    expect(result.message, contains('confirmation'));
    expect(hydrationRepository.logs, isEmpty);
  });

  test('executor applies valid confirmed hydration logs through repository',
      () async {
    const action = SuggestHydrationLogAction(
      message: 'Suggest logging 300 ml.',
      volumeMl: 300,
    );

    final result = await executor.execute(
      action,
      userConfirmed: true,
      now: DateTime(2026, 5, 26, 10),
    );

    expect(result.status, HydrationAiActionExecutionStatus.applied);
    expect(result.appliedEntityId, isNotEmpty);
    expect(hydrationRepository.logs.single.volumeMl, 300);
    expect(hydrationRepository.logs.single.source, 'provider_suggestion');
  });

  test('executor applies valid confirmed reminder definitions locally',
      () async {
    const action = SuggestReminderAction(
      message: 'Take a sip in 20 minutes.',
      delay: Duration(minutes: 20),
      priority: 2,
    );

    final result = await executor.execute(
      action,
      userConfirmed: true,
      now: DateTime(2026, 5, 26, 10),
    );

    expect(result.status, HydrationAiActionExecutionStatus.applied);
    expect(reminderRepository.reminders.single.message, action.message);
    expect(reminderRepository.reminders.single.priority, 2);
  });

  test('executor applies valid confirmed challenges through repository',
      () async {
    const action = SuggestChallengeAction(
      message: 'Try a steady week.',
      challengeId: 'steady-week',
      name: 'Steady Week',
      description: 'Hit your target for a week.',
      targetMl: 2200,
      durationDays: 7,
    );

    final result = await executor.execute(
      action,
      userConfirmed: true,
      now: DateTime(2026, 5, 26, 10),
    );

    expect(result.status, HydrationAiActionExecutionStatus.applied);
    expect(challengeRepository.activeChallenge?.id, 'steady-week');
  });

  test('executor displays text-only coach messages without changing state',
      () async {
    const action = CoachMessageAction(message: 'Take steady sips.');

    final result = await executor.execute(action, userConfirmed: false);

    expect(result.status, HydrationAiActionExecutionStatus.displayOnly);
    expect(result.message, 'Take steady sips.');
    expect(hydrationRepository.logs, isEmpty);
    expect(reminderRepository.reminders, isEmpty);
    expect(challengeRepository.activeChallenge, isNull);
  });

  test('executor rejects unsafe or invalid actions', () async {
    const action = SuggestHydrationLogAction(
      message: 'Log too much.',
      volumeMl: 6000,
    );

    final result = await executor.execute(action, userConfirmed: true);

    expect(result.status, HydrationAiActionExecutionStatus.rejected);
    expect(result.message, contains('1 to 5000 ml'));
    expect(hydrationRepository.logs, isEmpty);
  });
}
