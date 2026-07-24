import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/local_profile_reset_service.dart';
import '../../utils/i18n_resolver.dart';
import '../components/hydrion_logo.dart';
import '../components/hydrion_viewport.dart';
import '../components/intake_ring.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= context.read<I18nResolver>().locale;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18nResolver>();
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
          _LanguageCard(
            selected: _selected ?? i18n.locale,
            onChanged: (locale) async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _selected = locale);
              await i18n.loadLocale(locale);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                    content:
                        Text(lookupAppLocalizations(locale).languageUpdated)),
              );
            },
          ),
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
          const _DeleteProfileCard(),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: const Key('settings-delete-profile-card'),
        leading: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Delete local profile'),
        subtitle: const Text(
          'Removes local Hydrion data. Android notification and location permissions remain controlled by device settings.',
        ),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete local profile?'),
        content: const Text(
          'This clears your local profile, hydration history, reminders, challenges, and weather cache on this device. Android notification and location permissions are not revoked and remain controlled in device settings.',
        ),
        actions: [
          TextButton(
            key: const Key('delete-review-permissions'),
            onPressed: () {
              Navigator.pop(dialogContext, false);
              Navigator.of(context).pushNamed('/permissions');
            },
            child: const Text('Review permissions'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-profile'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final resetService = context.read<LocalProfileResetService>();
    setState(() => _deleting = true);
    final result = await resetService.resetLocalProfile();
    if (!context.mounted) return;
    setState(() => _deleting = false);
    if (!result.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile could not be deleted. Close Hydrion, reopen it, and try again.',
          ),
        ),
      );
      return;
    }
    if (result.hasPendingNotificationCleanup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile deleted. Android reminder cleanup will retry automatically.',
          ),
        ),
      );
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: const Key('settings-replay-app-tour'),
        leading: const Icon(Icons.help_outline),
        title: const Text('Help'),
        subtitle: const Text('App tour \u00b7 Replay the quick guide'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<HydrionThemePreference>(
          key: const Key('settings-theme-picker'),
          initialValue: settings.themePreference,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Appearance',
            prefixIcon: Icon(Icons.brightness_6_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: HydrionThemePreference.system,
              child: Text('Use device setting'),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.automatic,
              child: Text('Automatic day/night'),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.light,
              child: Text('Day'),
            ),
            DropdownMenuItem(
              value: HydrionThemePreference.dark,
              child: Text('Night'),
            ),
          ],
          selectedItemBuilder: (context) => const [
            Text('Device setting', overflow: TextOverflow.ellipsis),
            Text('Auto day/night', overflow: TextOverflow.ellipsis),
            Text('Day', overflow: TextOverflow.ellipsis),
            Text('Night', overflow: TextOverflow.ellipsis),
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
            : 'Profile'),
        subtitle: Text('${settings.dailyGoalMl} ml/day'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/profile'),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Locale selected;
  final ValueChanged<Locale> onChanged;
  const _LanguageCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<Locale>(
          key: const Key('settings-locale-picker'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.appLanguageLabel),
          items: I18nResolver.supportedLocales
              .map((locale) => DropdownMenuItem(
                    value: locale,
                    child: Text(switch (locale.languageCode) {
                      'es' => l10n.localeNameSpanish,
                      'fr' => l10n.localeNameFrench,
                      _ => l10n.localeNameEnglish,
                    }),
                  ))
              .toList(),
          onChanged: (locale) {
            if (locale != null) onChanged(locale);
          },
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
                  final saved = value != null &&
                      await context
                          .read<UserSettingsRepository>()
                          .setDailyGoalMl(value);
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_drink_outlined),
        title: const Text('Reusable container'),
        subtitle: Text(
          settings.usableContainerSizeMl == null
              ? 'Not set'
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
        title: const Text('Reusable container'),
        content: TextField(
          key: const Key('reusable-container-input'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: unit == HydrionVolumeUnit.ounces
                ? 'Amount in oz'
                : 'Amount in ml',
            helperText: 'One saved amount is used by Home and Bottle Bingo.',
          ),
        ),
        actions: [
          if (settings.usableContainerSizeMl != null)
            TextButton(
              key: const Key('clear-reusable-container'),
              onPressed: () => Navigator.pop(dialogContext, -1.0),
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-reusable-container'),
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.trim()),
            ),
            child: const Text('Save'),
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
        const SnackBar(content: Text('Enter an amount from 100 to 2000 ml.')),
      );
    }
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: const Key('settings-permission-center'),
        leading: const Icon(Icons.verified_user_outlined),
        title: const Text('Permissions'),
        subtitle: const Text(
          'Review reminders, weather location, and Android alarm access.',
        ),
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.gavel_outlined),
        title: const Text('Legal, privacy, and support'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/legal-about'),
      ),
    );
  }
}
