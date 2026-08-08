import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';

class RecognitionMoment {
  const RecognitionMoment._();

  static Future<bool> showOnce(
    BuildContext context, {
    required UserSettingsRepository repository,
    required String eventId,
    required String message,
  }) async {
    if (!await repository.claimRecognition(eventId) || !context.mounted) {
      return false;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: reduceMotion ? 1600 : 2600),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(
              Icons.water_drop_outlined,
              color: Colors.white,
              semanticLabel: l10n.achievementSemantics,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
    return true;
  }
}
