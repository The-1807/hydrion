import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
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
    final permissions = context.read<Permissions>();
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsHeader(capabilities: capabilities),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 12),
                      Text(
                        l10n.language,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Locale>(
                    key: const Key('settings-locale-picker'),
                    initialValue: _selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.appLanguageLabel,
                    ),
                    items: I18nResolver.supportedLocales.map((locale) {
                      return DropdownMenuItem(
                        value: locale,
                        child: Text(_localeLabel(locale, l10n)),
                      );
                    }).toList(),
                    onChanged: (locale) async {
                      if (locale == null) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _selected = locale);
                      await i18n.loadLocale(locale);
                      if (!mounted) {
                        return;
                      }
                      final selectedL10n = lookupAppLocalizations(i18n.locale);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(selectedL10n.languageUpdated),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _localeCoverage(_selected ?? i18n.locale, l10n),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    l10n.languageChoiceSaved,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.futureLanguagesNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.permissions,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.standalonePermissionsExplanation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('settings-permissions-check'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await permissions.requestPermissions();
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.noPlatformPermissionsRequested,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(l10n.check),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CapabilityStatusCard(capabilities: capabilities),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale, AppLocalizations l10n) {
    return switch (locale.languageCode) {
      'en' => l10n.localeNameEnglish,
      'es' => l10n.localeNameSpanish,
      'fr' => l10n.localeNameFrench,
      _ => locale.toLanguageTag(),
    };
  }

  String _localeCoverage(Locale locale, AppLocalizations l10n) {
    return switch (locale.languageCode) {
      'en' || 'es' || 'fr' => l10n.localeCoverageComplete,
      _ => l10n.futureLanguagesNote,
    };
  }
}

class _SettingsHeader extends StatelessWidget {
  final AppCapabilities capabilities;

  const _SettingsHeader({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HydrionLogo(
              size: 56,
              imageKey: const Key('settings-logo'),
              semanticLabel: l10n.hydrionLogoSemantics,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    capabilities.elkaConfigured
                        ? l10n.elkaAdapterConfiguredMode
                        : l10n.standaloneLocalMode,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.localDataNoProviderRuntime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityStatusCard extends StatelessWidget {
  final AppCapabilities capabilities;

  const _CapabilityStatusCard({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.runtimeFeatureStatus,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          _CapabilityTile(
            icon: Icons.storage_outlined,
            title: l10n.localPersistence,
            enabled: capabilities.localPersistence,
            enabledLabel: l10n.onDevice,
            disabledLabel: l10n.unavailable,
            description: l10n.localPersistenceDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.hub_outlined,
            title: l10n.elkaAdapter,
            enabled: capabilities.elkaConfigured,
            enabledLabel: l10n.configured,
            disabledLabel: l10n.unconfigured,
            description: l10n.elkaAdapterDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.cloud_off_outlined,
            title: l10n.cloudAi,
            enabled: capabilities.cloudAi,
            enabledLabel: l10n.connected,
            disabledLabel: l10n.disabled,
            description: l10n.cloudAiDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.mic_off_outlined,
            title: l10n.voiceInput,
            enabled: capabilities.voiceInput,
            enabledLabel: l10n.available,
            disabledLabel: l10n.disabled,
            description: l10n.voiceInputDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.bluetooth_disabled_outlined,
            title: l10n.bleBottleSync,
            enabled: capabilities.bleSync,
            enabledLabel: l10n.available,
            disabledLabel: l10n.disabled,
            description: l10n.bleSyncDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.health_and_safety_outlined,
            title: l10n.healthSync,
            enabled: capabilities.healthSync,
            enabledLabel: l10n.available,
            disabledLabel: l10n.disabled,
            description: l10n.healthSyncDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.notifications_off_outlined,
            title: l10n.osNotifications,
            enabled: capabilities.osNotifications,
            enabledLabel: l10n.available,
            disabledLabel: l10n.disabled,
            description: l10n.osNotificationsDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.view_in_ar_outlined,
            title: l10n.arVisualization,
            enabled: capabilities.arVisualization,
            enabledLabel: l10n.available,
            disabledLabel: l10n.disabled,
            description: l10n.arVisualizationDescription,
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.groups_2_outlined,
            title: l10n.socialSync,
            enabled: capabilities.socialSync,
            enabledLabel: l10n.connected,
            disabledLabel: l10n.localOnly,
            description: l10n.socialSyncDescription,
          ),
        ],
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool enabled;
  final String enabledLabel;
  final String disabledLabel;
  final String description;

  const _CapabilityTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: _StatusPill(
        label: enabled ? enabledLabel : disabledLabel,
        enabled: enabled,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool enabled;

  const _StatusPill({
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = enabled
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground =
        enabled ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
