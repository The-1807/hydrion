import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';

class ChallengeStorageNotice extends StatefulWidget {
  const ChallengeStorageNotice({super.key});
  @override
  State<ChallengeStorageNotice> createState() => _ChallengeStorageNoticeState();
}

class _ChallengeStorageNoticeState extends State<ChallengeStorageNotice> {
  bool _retrying = false;
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ChallengeRepository>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(repository.storageStatus == ChallengeStorageStatus.cleanupPending
              ? l10n.dailyContextCleanupPending
              : repository.storageStatus ==
                      ChallengeStorageStatus.deletionPending
                  ? l10n.challengeDeletionPending
                  : l10n.challengeStorageUnavailable),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            onPressed: _retrying
                ? null
                : () async {
                    setState(() => _retrying = true);
                    try {
                      await repository.refreshFromStore();
                    } on ChallengeStorageUnavailable {
                      // Repository state remains the authority; no raw error display.
                    } finally {
                      if (mounted) setState(() => _retrying = false);
                    }
                  },
          ),
        ]),
      )),
    );
  }
}
