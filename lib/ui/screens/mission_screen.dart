import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/android_permission_revocation_service.dart';
import '../../utils/permissions.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';

class MissionScreen extends StatelessWidget {
  final bool fromOnboarding;

  const MissionScreen({super.key, this.fromOnboarding = false});

  Future<void> _finish(BuildContext context) async {
    await context
        .read<UserSettingsRepository>()
        .setMissionIntroductionHandled(true);
    if (!context.mounted) return;
    if (fromOnboarding) {
      context.read<GuidedTourRepository>().replayCoreTour();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.missionTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: l10n.missionSemanticLabel,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.missionHeadline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.learnMore),
              children: [
                Text(l10n.missionDetails),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('mission-join-community'),
              onPressed: null,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(l10n.communityComingLater),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('mission-continue'),
              onPressed: () => _finish(context),
              icon: Icon(fromOnboarding ? Icons.arrow_forward : Icons.check),
              label: Text(
                fromOnboarding ? l10n.continueToTutorial : l10n.done,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDeletionFarewellScreen extends StatelessWidget {
  final bool removeDevicePermissions;

  const ProfileDeletionFarewellScreen({
    super.key,
    this.removeDevicePermissions = false,
  });

  Future<void> _finish(BuildContext context) async {
    if (!removeDevicePermissions) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/onboarding', (route) => false);
      return;
    }
    final result = await const AndroidPermissionRevocationService()
        .revokeOnProfileDeletion();
    if (!context.mounted) return;
    if (result == HydrionPermissionRevocationResult.settingsRequired) {
      await context.read<Permissions>().openAppSettings();
      if (!context.mounted) return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.profileDeletedTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 56,
              semanticLabel: l10n.profileDeletionCompletedSemanticLabel,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.profileDeletedHeadline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(l10n.profileDeletedFarewell),
            const SizedBox(height: 24),
            OutlinedButton(
              key: const Key('farewell-mission'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MissionScreen(),
                ),
              ),
              child: Text(l10n.learnAboutMission),
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('farewell-finish'),
              onPressed: () => _finish(context),
              child: Text(l10n.finish),
            ),
          ],
        ),
      ),
    );
  }
}
