import 'package:flutter/widgets.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';
import '../../repositories/challenge_repository.dart';

String challengeEditMessage(
  AppLocalizations l10n,
  ChallengeEditMessageCode code,
) =>
    l10n.challengeText(switch (code) {
      ChallengeEditMessageCode.invalidChange =>
        'That change could not be saved.',
      ChallengeEditMessageCode.applied => 'Change applied.',
      ChallengeEditMessageCode.startsTomorrow =>
        'This change starts tomorrow. Today’s progress will stay the same.',
      ChallengeEditMessageCode.restartConfirmationRequired =>
        'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge’s progress will begin again.',
      ChallengeEditMessageCode.restartFailed =>
        'The challenge could not be restarted.',
      ChallengeEditMessageCode.restarted =>
        'A new challenge attempt has started.',
      ChallengeEditMessageCode.notEditableWhileActive =>
        'This setting cannot be changed while the challenge is active.',
    });

class ChallengeCopy {
  final String title;
  final String description;

  const ChallengeCopy(this.title, this.description);

  static ChallengeCopy forChallenge(
    BuildContext context,
    HydrationChallenge challenge,
  ) {
    final copy = AppLocalizations.of(context).challengeCopy(challenge.id);
    return ChallengeCopy(copy.title, copy.description);
  }
}
