import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/i18n_resolver.dart';
import '../../utils/permissions.dart';
import '../components/hydrion_logo.dart';

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
        padding: const EdgeInsets.all(16),
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
          _DailyGoalCard(settings: settings),
          const SizedBox(height: 12),
          _ReusableContainerCard(settings: settings),
          const SizedBox(height: 12),
          const _PermissionsCard(),
          const SizedBox(height: 12),
          const _LegalAboutCard(),
        ],
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
            Text(l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall),
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
          Row(children: [
            Expanded(
                child: TextField(
              key: const Key('settings-daily-goal-field'),
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.dailyGoalFieldLabel),
            )),
            const SizedBox(width: 8),
            FilledButton(
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
            ),
          ]),
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
        subtitle: Text('${settings.containerSizeMl} ml'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/profile'),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(l10n.permissions),
        subtitle: const Text('Review permissions used for reminders.'),
        trailing: TextButton(
          onPressed: () async {
            await context.read<Permissions>().requestPermissions();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.noPlatformPermissionsRequested)),
            );
          },
          child: Text(l10n.check),
        ),
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
