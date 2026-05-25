import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/main.dart';

void main() {
  const validator = HydrationAiActionValidator();

  test('Phase 3.3 typed context and action contract remains intact', () {
    final context = _standaloneContext();
    const actions = <HydrationAiAction>[
      CoachMessageAction(message: 'Drink steadily.'),
      SuggestReminderAction(
        message: 'Consider a local reminder.',
        delay: Duration(minutes: 30),
      ),
      SuggestHydrationLogAction(
        message: 'Consider logging 250 ml.',
        volumeMl: 250,
      ),
      ExplainTrendAction(message: 'Your trend is local.'),
      SuggestChallengeAction(
        message: 'Try a local challenge.',
        challengeId: 'test',
        name: 'Test',
        description: 'Test challenge',
        targetMl: 2000,
        durationDays: 7,
      ),
      UnsupportedCapabilityNoticeAction(message: 'Unavailable.'),
    ];

    expect(context.dailySummary.consumedMl, 0);
    expect(context.reminder.savedReminderCount, 0);
    expect(context.challenge.hasActiveChallenge, isFalse);
    expect(context.capabilities.geminiConfigured, isFalse);
    expect(
      actions.map((action) => action.type),
      containsAll(HydrationAiActionType.values),
    );
  });

  test('valid text-only coach messages can pass validation', () {
    const action = CoachMessageAction(
      message: 'Hydrion is running locally. Take a steady sip.',
    );

    final result = validator.validate(
      action,
      const CapabilityContext.standalone(),
    );

    expect(result.isAllowed, isTrue);
    expect(result.canExecute(userConfirmed: false), isTrue);
    expect(result.action.changesAppState, isFalse);
  });

  test('provider output is only trusted after validation', () async {
    const provider = _FakeAiProvider([
      CoachMessageAction(
        message: 'Gemini is connected and voice input is working.',
      ),
    ]);

    final actions = await provider.proposeActions(
      context: _standaloneContext(),
      userQuery: 'what can you do?',
    );
    final rawAction = actions.single;
    final result = validator.validate(
      rawAction,
      const CapabilityContext.standalone(),
    );

    expect(rawAction.message, contains('Gemini is connected'));
    expect(result.isAllowed, isFalse);
    expect(
      result.action.type,
      HydrationAiActionType.unsupportedCapabilityNotice,
    );
    expect(result.canExecute(userConfirmed: true), isFalse);
  });

  test('invalid suggested hydration logs are rejected', () {
    const tooSmall = SuggestHydrationLogAction(
      message: 'Log nothing.',
      volumeMl: 0,
    );
    const tooLarge = SuggestHydrationLogAction(
      message: 'Log too much.',
      volumeMl: 6000,
    );

    final smallResult = validator.validate(
      tooSmall,
      const CapabilityContext.standalone(),
    );
    final largeResult = validator.validate(
      tooLarge,
      const CapabilityContext.standalone(),
    );

    expect(smallResult.isAllowed, isFalse);
    expect(largeResult.isAllowed, isFalse);
    expect(smallResult.reason, contains('1 to 5000 ml'));
    expect(smallResult.canExecute(userConfirmed: true), isFalse);
  });

  test('invalid reminders are rejected', () {
    const action = SuggestReminderAction(
      message: 'Remind me in the past.',
      delay: Duration(minutes: -5),
    );

    final result = validator.validate(
      action,
      const CapabilityContext.standalone(),
    );

    expect(result.isAllowed, isFalse);
    expect(result.reason, contains('negative'));
    expect(result.canExecute(userConfirmed: true), isFalse);
  });

  test('unavailable capability claims are rejected', () {
    const action = ExplainTrendAction(
      message:
          'Voice input is enabled, BLE sync is active, and cloud sync is connected.',
    );

    final result = validator.validate(
      action,
      const CapabilityContext.standalone(),
    );

    expect(result.isAllowed, isFalse);
    expect(result.blockedCapabilities, contains(HydrionCapability.voiceInput));
    expect(result.blockedCapabilities, contains(HydrionCapability.bleSync));
    expect(result.blockedCapabilities, contains(HydrionCapability.cloudSync));
  });

  test('state-changing actions require user confirmation after validation', () {
    const action = SuggestHydrationLogAction(
      message: 'Suggest logging 250 ml.',
      volumeMl: 250,
    );

    final result = validator.validate(
      action,
      const CapabilityContext.standalone(),
    );

    expect(result.isAllowed, isTrue);
    expect(result.action.changesAppState, isTrue);
    expect(result.action.requiresUserConfirmation, isTrue);
    expect(result.canExecute(userConfirmed: false), isFalse);
    expect(result.canExecute(userConfirmed: true), isTrue);
  });

  test('state-changing provider actions are not automatically applied',
      () async {
    final services = HydrionServices.memory();
    const provider = _FakeAiProvider([
      SuggestHydrationLogAction(
        message: 'Suggest logging 750 ml.',
        volumeMl: 750,
      ),
      SuggestReminderAction(
        message: 'Suggest a local reminder definition.',
        delay: Duration(minutes: 45),
      ),
      SuggestChallengeAction(
        message: 'Suggest a challenge.',
        challengeId: 'provider-suggested',
        name: 'Provider Suggested',
        description: 'A suggestion only.',
        targetMl: 2000,
        durationDays: 7,
      ),
    ]);

    final context =
        await services.hydrationContextProvider.getHydrationContext();
    final actions = await provider.proposeActions(
      context: context,
      userQuery: 'make changes',
    );
    final results = validator.validateAll(actions, context.capabilities);

    expect(results.map((result) => result.isAllowed), everyElement(isTrue));
    expect(
      results.map((result) => result.canExecute(userConfirmed: false)),
      everyElement(isFalse),
    );
    expect(services.hydrationRepository.logs, isEmpty);
    expect(services.reminderRepository.reminders, isEmpty);
    expect(services.challengeRepository.activeChallenge, isNull);
  });
}

HydrationContext _standaloneContext() {
  return HydrationContext(
    dailySummary: DailyHydrationSummary(
      date: DateTime(2026, 5, 25),
      consumedMl: 0,
      targetMl: 2200,
      entryCount: 0,
    ),
    lifetimeMl: 0,
    eventCount: 0,
    reminder: const ReminderContext.empty(),
    challenge: const ChallengeContext.none(),
    capabilities: const CapabilityContext.standalone(),
  );
}

class _FakeAiProvider implements HydrationAiProvider {
  final List<HydrationAiAction> actions;

  const _FakeAiProvider(this.actions);

  @override
  Future<List<HydrationAiAction>> proposeActions({
    required HydrationContext context,
    required String userQuery,
  }) async {
    return actions;
  }
}
