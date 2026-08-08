import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';
import '../../services/app_refresh_controller.dart';

Future<void> refreshHydrionData(BuildContext context) async {
  final result = await context.read<AppRefreshController>().refresh();
  if (result != AppRefreshResult.failed || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.challengeText(
        "Couldn't refresh everything. Your saved hydration data is still available.",
      )),
    ),
  );
}
