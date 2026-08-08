import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';

String aiExecutionMessage(
  AppLocalizations l10n,
  HydrationAiExecutionMessageCode code,
) =>
    l10n.challengeText(switch (code) {
      HydrationAiExecutionMessageCode.validationRejected =>
        'Hydrion rejected an unsafe or invalid suggestion.',
      HydrationAiExecutionMessageCode.confirmationRequired =>
        'Your confirmation is required before Hydrion changes anything.',
      HydrationAiExecutionMessageCode.generatedContent =>
        'Generated guidance is ready.',
      HydrationAiExecutionMessageCode.hydrationLogRejected =>
        'The suggested hydration log was not applied.',
      HydrationAiExecutionMessageCode.hydrationLogApplied =>
        'Hydration log applied.',
      HydrationAiExecutionMessageCode.reminderApplied =>
        'Local reminder applied.',
      HydrationAiExecutionMessageCode.challengeApplied =>
        'Local challenge applied.',
      HydrationAiExecutionMessageCode.unsupportedAction =>
        'Hydrion cannot apply this suggestion.',
    });
