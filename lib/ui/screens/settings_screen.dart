import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
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
    final permissions = context.read<Permissions>();
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('settings_title', 'Settings')),
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
                        i18n.getText('language', 'Language'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Locale>(
                    key: const Key('settings-locale-picker'),
                    initialValue: _selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'App language',
                    ),
                    items: I18nResolver.supportedLocales.map((locale) {
                      return DropdownMenuItem(
                        value: locale,
                        child: Text(_localeLabel(locale)),
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
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            i18n.getText('lang_updated', 'Language updated'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _localeCoverage(_selected ?? i18n.locale),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Language choice is saved locally.',
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
                          i18n.getText('permissions', 'Permissions'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Standalone mode does not request Bluetooth, Health, microphone, camera, or notification permissions.',
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
                        const SnackBar(
                          content: Text(
                            'No platform permissions requested in standalone mode',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Check'),
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

  String _localeLabel(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'English (US)',
      'es' => 'Spanish (ES)',
      'fr' => 'French (FR)',
      'ar' => 'Arabic (SA)',
      'de' => 'German (DE)',
      'pt' => 'Portuguese (PT)',
      'zh' => 'Chinese (CN)',
      _ => locale.toLanguageTag(),
    };
  }

  String _localeCoverage(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'Hydrion strings are available for this locale.',
      'es' ||
      'fr' =>
        'Partial Hydrion strings are available; untranslated text falls back to English.',
      _ =>
        'Material widgets use this locale; Hydrion text currently falls back to English.',
    };
  }
}

class _SettingsHeader extends StatelessWidget {
  final AppCapabilities capabilities;

  const _SettingsHeader({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const HydrionLogo(
              size: 56,
              imageKey: Key('settings-logo'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hydrion',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    capabilities.modeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local data, local rules, no provider runtime.',
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
                    'Runtime feature status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          _CapabilityTile(
            icon: Icons.storage_outlined,
            title: 'Local persistence',
            enabled: capabilities.localPersistence,
            enabledLabel: 'On device',
            disabledLabel: 'Unavailable',
            description:
                'Hydration logs, settings, reminders, and challenge state are stored locally.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.hub_outlined,
            title: 'ELKA adapter',
            enabled: capabilities.elkaConfigured,
            enabledLabel: 'Configured',
            disabledLabel: 'Unconfigured',
            description:
                'Adapter boundary exists, but no ELKA runtime is connected.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.cloud_off_outlined,
            title: 'Cloud AI',
            enabled: capabilities.cloudAi,
            enabledLabel: 'Connected',
            disabledLabel: 'Disabled',
            description: 'No provider SDK or cloud model is connected.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.mic_off_outlined,
            title: 'Voice input',
            enabled: capabilities.voiceInput,
            enabledLabel: 'Available',
            disabledLabel: 'Disabled',
            description:
                'Typed commands can be parsed; microphone capture is unavailable.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.bluetooth_disabled_outlined,
            title: 'BLE bottle sync',
            enabled: capabilities.bleSync,
            enabledLabel: 'Available',
            disabledLabel: 'Disabled',
            description:
                'No Bluetooth scan, connection, or bottle level read is started.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Health sync',
            enabled: capabilities.healthSync,
            enabledLabel: 'Available',
            disabledLabel: 'Disabled',
            description:
                'No HealthKit, Google Fit, or wearable read is active.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.notifications_off_outlined,
            title: 'OS notifications',
            enabled: capabilities.osNotifications,
            enabledLabel: 'Available',
            disabledLabel: 'Disabled',
            description:
                'Reminder definitions save locally; no platform notification is scheduled.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.view_in_ar_outlined,
            title: 'AR visualization',
            enabled: capabilities.arVisualization,
            enabledLabel: 'Available',
            disabledLabel: 'Disabled',
            description:
                'AR route is a placeholder; no camera or native AR session starts.',
          ),
          const Divider(height: 1),
          _CapabilityTile(
            icon: Icons.groups_2_outlined,
            title: 'Social sync',
            enabled: capabilities.socialSync,
            enabledLabel: 'Connected',
            disabledLabel: 'Local only',
            description:
                'Challenges are local-only; no backend state is shared.',
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
