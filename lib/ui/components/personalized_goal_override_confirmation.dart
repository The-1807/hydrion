import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';

Future<bool> confirmPersonalizedGoalOverride(
  BuildContext context, {
  required UserSettings settings,
  required int proposedGoalMl,
}) async {
  if (settings.baselineSource != HydrionBaselineSource.personalized ||
      proposedGoalMl == settings.dailyGoalMl) {
    return true;
  }
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.manualGoalOverrideQuestion),
          content: Text(l10n.manualGoalOverrideConfirmation),
          actions: [
            TextButton(
              key: const Key('manual-goal-override-cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('manual-goal-override-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.confirmApply),
            ),
          ],
        ),
      ) ??
      false;
}
