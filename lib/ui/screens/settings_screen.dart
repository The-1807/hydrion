import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/app_locale_repository.dart';
import '../../domain/locale_registry.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/local_profile_reset_service.dart';
import '../components/hydrion_logo.dart';
import '../components/hydrion_viewport.dart';
import '../components/personalized_goal_override_confirmation.dart';
import '../components/intake_ring.dart';
import 'mission_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<UserSettingsRepository>().settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListView(
        key: const Key('settings-scroll-view'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: HydrionViewport.scrollPadding(context),
        children: [
          const _SettingsHeader(),
          const SizedBox(height: 12),
          _ProfileSummaryCard(settings: settings),
          const SizedBox(height: 12),
          const _BodyMetricsCard(),
          const SizedBox(height: 12),
          const _LanguageCard(),
          const SizedBox(height: 12),
          _ThemeCard(settings: settings),
          const SizedBox(height: 12),
          _DailyGoalCard(settings: settings),
          const SizedBox(height: 12),
          _ReusableContainerCard(settings: settings),
          const SizedBox(height: 12),
          const _PermissionsCard(),
          const SizedBox(height: 12),
          const _HelpCard(),
          const SizedBox(height: 12),
          const _LegalAboutCard(),
          const SizedBox(height: 12),
          const _MissionCard(),
          const SizedBox(height: 12),
          const _DeleteProfileCard(),
        ],
      ),
    );
  }
}

class _BodyMetricsCard extends StatelessWidget {
  const _BodyMetricsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-body-metrics-card'),
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text(l10n.bodyMetricsTitle),
        subtitle: Text(l10n.bodyMetricsOptional),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/body-metrics'),
      ),
    );
  }
}

class _DeleteProfileCard extends StatefulWidget {
  const _DeleteProfileCard();

  @override
  State<_DeleteProfileCard> createState() => _DeleteProfileCardState();
}

class _DeleteProfileCardState extends State<_DeleteProfileCard> {
  bool _deleting = false;
  bool _removeDevicePermissions = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-delete-profile-card'),
        leading: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.deleteLocalProfile),
        subtitle: Text(l10n.deleteLocalProfileSummary),
        trailing: _deleting
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _deleting ? null : () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Consumer<AppLocaleRepository>(
          builder: (context, localeRepository, _) {
            final l10n = lookupAppLocalizations(localeRepository.locale);
            return AlertDialog(
              title: Text(l10n.deleteLocalProfileQuestion),
              content: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profileDeletionPersonalizationDisclosure),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        key: const Key('delete-remove-device-permissions'),
                        contentPadding: EdgeInsets.zero,
                        value: _removeDevicePermissions,
                        title: Text(l10n.removeDevicePermissions),
                        subtitle: Text(l10n.removeDevicePermissionsHelp),
                        onChanged: (value) => setDialogState(
                          () => _removeDevicePermissions = value ?? true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('delete-review-permissions'),
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                    Navigator.of(context).pushNamed('/permissions');
                  },
                  child: Text(l10n.reviewPermissions),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  key: const Key('confirm-delete-profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.deleteAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final resetService = context.read<LocalProfileResetService>();
    setState(() => _deleting = true);
    final result = await resetService.resetLocalProfile();
    if (!context.mounted) return;
    setState(() => _deleting = false);
    if (!result.isCompleted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileDeletionFailed),
        ),
      );
      return;
    }
    if (result.hasPendingNotificationCleanup) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileDeletionCleanupPending),
        ),
      );
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ProfileDeletionFarewellScreen(
          removeDevicePermissions: _removeDevicePermissions,
        ),
      ),
      (route) => false,
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-hydrion-mission'),
        leading: const Icon(Icons.water_drop_outlined),
        title: Text(l10n.whyHydrionExists),
        subtitle: Text(l10n.missionAndCommunity),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MissionScreen()),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-replay-app-tour'),
        leading: const Icon(Icons.help_outline),
        title: Text(l10n.help),
        subtitle: Text(l10n.replayAppTour),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.read<GuidedTourRepository>().replayCoreTour();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final UserSettings settings;

  const _ThemeCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<HydrionThemePreference>(
          key: const Key('settings-theme-picker'),
          initialValue: settings.themePreference,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.appearance,
            prefixIcon: const Icon(Icons.brightness_6_outlined),
          ),
          items: [
            DropdownMenuItem(
              value: HydrionThemePreference.system,
              child: Text(l10n.useDeviceSetting),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.automatic,
              child: Text(l10n.automaticDayNight),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.light,
              child: Text(l10n.dayTheme),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.dark,
              child: Text(l10n.nightTheme),
            ),
          ],
          selectedItemBuilder: (context) => [
            Text(l10n.deviceSetting, overflow: TextOverflow.ellipsis),
            Text(l10n.autoDayNight, overflow: TextOverflow.ellipsis),
            Text(l10n.dayTheme, overflow: TextOverflow.ellipsis),
            Text(l10n.nightTheme, overflow: TextOverflow.ellipsis),
          ],
          onChanged: (preference) async {
            if (preference == null) return;
            await context
                .read<UserSettingsRepository>()
                .setThemePreference(preference);
          },
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HydrionLogo(size: 56, semanticLabel: l10n.hydrionLogoSemantics),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final UserSettings settings;
  const _ProfileSummaryCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(avatar.assetPath,
              width: 52, height: 52, fit: BoxFit.cover),
        ),
        title: Text(settings.nickname?.trim().isNotEmpty == true
            ? settings.nickname!.trim()
            : l10n.profileTitle),
        subtitle: Text(l10n.dailyGoalPerDay(amount: settings.dailyGoalMl)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/profile'),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-locale-picker'),
        leading: const Icon(Icons.language),
        title: Text(l10n.appLanguageLabel),
        subtitle: Text(
          HydrionLocaleRegistry.definitionFor(
            context.watch<AppLocaleRepository>().locale,
          ).nativeName,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LanguageSelectionScreen(fromSettings: true),
          ),
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatefulWidget {
  final UserSettings settings;
  const _DailyGoalCard({required this.settings});
  @override
  State<_DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<_DailyGoalCard> {
  late final TextEditingController controller =
      TextEditingController(text: widget.settings.dailyGoalMl.toString());
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.dailyGoalTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final field = TextField(
                key: const Key('settings-daily-goal-field'),
                controller: controller,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.dailyGoalFieldLabel),
              );
              final save = FilledButton(
                key: const Key('settings-daily-goal-save'),
                onPressed: () async {
                  final value = int.tryParse(controller.text.trim());
                  final repository = context.read<UserSettingsRepository>();
                  if (value != null &&
                      !await confirmPersonalizedGoalOverride(
                        context,
                        settings: repository.settings,
                        proposedGoalMl: value,
                      )) {
                    return;
                  }
                  final saved = value != null &&
                      await repository.setDailyGoalMl(
                        value,
                        updateBaseline: repository.settings.baselineSource !=
                            HydrionBaselineSource.personalized,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        saved ? l10n.dailyGoalUpdated : l10n.dailyGoalInvalid),
                  ));
                },
                child: Text(l10n.save),
              );
              if (HydrionViewport.stackActions(
                context,
                availableWidth: constraints.maxWidth,
                widthBreakpoint: 380,
              )) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 12),
                    save,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 8),
                  save,
                ],
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _ReusableContainerCard extends StatelessWidget {
  final UserSettings settings;
  const _ReusableContainerCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_drink_outlined),
        title: Text(l10n.reusableContainerTitle),
        subtitle: Text(
          settings.usableContainerSizeMl == null
              ? l10n.notSet
              : HydrationVolumeFormatter.format(
                  settings.containerSizeMl,
                  settings.volumeUnit,
                ),
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _editContainer(context),
      ),
    );
  }

  Future<void> _editContainer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final repository = context.read<UserSettingsRepository>();
    final unit = settings.volumeUnit;
    final initial = HydrationVolumeFormatter.fromMilliliters(
      settings.containerSizeMl,
      unit,
    );
    final controller = TextEditingController(
      text: unit == HydrionVolumeUnit.ounces
          ? initial.toStringAsFixed(1)
          : initial.round().toString(),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext).reusableContainerTitle),
        content: TextField(
          key: const Key('reusable-container-input'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: unit == HydrionVolumeUnit.ounces
                ? AppLocalizations.of(dialogContext).amountInOz
                : AppLocalizations.of(dialogContext).amountInMl,
            helperText: AppLocalizations.of(dialogContext).containerSharedHelp,
          ),
        ),
        actions: [
          if (settings.usableContainerSizeMl != null)
            TextButton(
              key: const Key('clear-reusable-container'),
              onPressed: () => Navigator.pop(dialogContext, -1.0),
              child: Text(AppLocalizations.of(dialogContext).clear),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext).cancel),
          ),
          FilledButton(
            key: const Key('save-reusable-container'),
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.trim()),
            ),
            child: Text(AppLocalizations.of(dialogContext).save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    if (value < 0) {
      await repository.clearContainerSize();
      return;
    }
    final ml = HydrationVolumeFormatter.toMilliliters(value, unit);
    final saved = await repository.setContainerSizeMl(ml);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerAmountInvalid)),
      );
    }
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: const Key('settings-permission-center'),
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(l10n.permissions),
        subtitle: Text(l10n.permissionsSummary),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/permissions'),
      ),
    );
  }
}

class _LegalAboutCard extends StatelessWidget {
  const _LegalAboutCard();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.gavel_outlined),
        title: Text(l10n.legalPrivacySupport),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/legal-about'),
      ),
    );
  }
}
