import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/release_metadata.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';
import '../../services/location_service.dart';
import '../../services/notifications.dart';
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
    final settings = context.watch<UserSettingsRepository>().settings;

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
          _ProfileSummaryCard(settings: settings),
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
          _DailyGoalCard(settings: settings),
          const SizedBox(height: 12),
          _WeatherGoalSettingsCard(settings: settings),
          const SizedBox(height: 12),
          _ReusableContainerCard(settings: settings),
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
                          'Hydrion asks for location and notification permission only after you use a feature that needs it. No permission prompt is shown on cold launch.',
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
          _LocalFirstPrivacyCard(capabilities: capabilities),
          const SizedBox(height: 12),
          const _LegalAboutCard(),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            const _DebugDiagnosticsCard(),
          ],
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

class _ProfileSummaryCard extends StatelessWidget {
  final UserSettings settings;

  const _ProfileSummaryCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);
    final nickname = settings.nickname?.trim();
    final goalMode = switch (settings.goalMode) {
      HydrionGoalMode.manual => 'Manual goal',
      HydrionGoalMode.weatherInformed => 'Weather-informed goal',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                avatar.assetPath,
                key: const Key('settings-avatar'),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                semanticLabel: avatar.displayName,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname == null || nickname.isEmpty
                        ? 'Local profile'
                        : nickname,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${avatar.displayName} • $goalMode'),
                  const SizedBox(height: 4),
                  Text(
                    '${settings.containerSizeMl} ml container • ${settings.dailyGoalMl} ml/day',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('settings-reopen-onboarding'),
                    onPressed: () async {
                      await context
                          .read<UserSettingsRepository>()
                          .reopenOnboarding();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pushReplacementNamed('/onboarding');
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit onboarding'),
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

class DebugDiagnosticsScreen extends StatefulWidget {
  const DebugDiagnosticsScreen({super.key});

  @override
  State<DebugDiagnosticsScreen> createState() => _DebugDiagnosticsScreenState();
}

class _DebugDiagnosticsScreenState extends State<DebugDiagnosticsScreen> {
  Future<void> _setNonLocalProviderConsentGranted(bool value) async {
    final settingsRepository = context.read<UserSettingsRepository>();
    final providerHealthReporter = context.read<ProviderHealthReporter>();
    final capabilityReporter = context.read<AppCapabilityReporter>();
    final health = providerHealthReporter.providerHealth;

    await settingsRepository.setNonLocalProviderConsentGranted(value);
    providerHealthReporter.updatePrivacyConsent(value);
    capabilityReporter.updateCapabilities(
      capabilityReporter.capabilities.copyWith(
        cloudAi: health.selectedProvider == HydrionAiProviderKind.gemini &&
            health.geminiConfigured &&
            value,
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final providerHealth =
        context.watch<ProviderHealthReporter>().providerHealth;
    final settings = context.watch<UserSettingsRepository>().settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugDiagnosticsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProviderHealthCard(
            health: providerHealth,
            nonLocalProviderConsentGranted:
                settings.nonLocalProviderConsentGranted,
            onNonLocalProviderConsentChanged:
                _setNonLocalProviderConsentGranted,
          ),
          const SizedBox(height: 12),
          _CapabilityStatusCard(capabilities: capabilities),
        ],
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.settings.dailyGoalMl.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _DailyGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.settings.dailyGoalMl.toString();
    if (_controller.text != current) {
      _controller.text = current;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.dailyGoalInvalid)),
      );
      return;
    }
    final saved =
        await context.read<UserSettingsRepository>().setDailyGoalMl(parsed);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(saved ? l10n.dailyGoalUpdated : l10n.dailyGoalInvalid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dailyGoalTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dailyGoalDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('settings-daily-goal-field'),
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.dailyGoalFieldLabel,
                      helperText: l10n.dailyGoalRange(
                        minMl: UserSettings.minDailyGoalMl,
                        maxMl: UserSettings.maxDailyGoalMl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('settings-daily-goal-save'),
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherGoalSettingsCard extends StatelessWidget {
  final UserSettings settings;

  const _WeatherGoalSettingsCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<UserSettingsRepository>();
    final weatherEnabled = settings.goalMode == HydrionGoalMode.weatherInformed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Weather-informed goals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Hydrion can use a one-time approximate location lookup and a daily forecast to suggest a conservative adjustment to your approved baseline. Coordinates are not stored as history.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<HydrionGoalMode>(
              key: const Key('settings-goal-mode-selector'),
              segments: const [
                ButtonSegment(
                  value: HydrionGoalMode.manual,
                  icon: Icon(Icons.tune),
                  label: Text('Manual'),
                ),
                ButtonSegment(
                  value: HydrionGoalMode.weatherInformed,
                  icon: Icon(Icons.wb_sunny_outlined),
                  label: Text('Weather'),
                ),
              ],
              selected: {settings.goalMode},
              onSelectionChanged: (selection) async {
                await repository.setGoalMode(selection.single);
              },
            ),
            const SizedBox(height: 8),
            Text(
              weatherEnabled
                  ? 'Current baseline: ${settings.baselineDailyGoalMl} ml. Current displayed goal: ${settings.dailyGoalMl} ml.'
                  : 'Manual mode is active. Your baseline remains ${settings.baselineDailyGoalMl} ml.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: settings.weatherGoalDailyConfirmationEnabled,
              onChanged: weatherEnabled
                  ? (value) async {
                      await repository
                          .setWeatherGoalDailyConfirmationEnabled(value);
                    }
                  : null,
              title: const Text('Confirm each daily recommendation'),
              subtitle: Text(
                settings.weatherGoalDailyConfirmationEnabled
                    ? 'Hydrion will ask before applying a weather-adjusted goal.'
                    : 'Eligible daily recommendations may auto-apply; restore confirmation any time.',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('settings-request-location'),
                  onPressed: weatherEnabled
                      ? () => _requestLocationPermission(context)
                      : null,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Allow location'),
                ),
                OutlinedButton.icon(
                  key: const Key('settings-request-notifications'),
                  onPressed: weatherEnabled
                      ? () => _requestNotificationPermission(context)
                      : null,
                  icon: const Icon(Icons.notifications_none),
                  label: const Text('Allow notifications'),
                ),
                OutlinedButton.icon(
                  key: const Key('settings-open-app-settings'),
                  onPressed: () async {
                    await context
                        .read<HydrionLocationService>()
                        .openAppSettings();
                  },
                  icon: const Icon(Icons.settings_applications_outlined),
                  label: const Text('App settings'),
                ),
              ],
            ),
            if (settings.lastWeatherGoalExplanation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last weather decision: ${settings.lastWeatherGoalExplanation}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<UserSettingsRepository>();
    final locationService = context.read<HydrionLocationService>();
    await repository.recordLocationPermissionPrompt(DateTime.now());
    final result = await locationService.requestPermission();
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Location permission status: ${result.name}')),
    );
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<UserSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    await repository.recordNotificationPermissionPrompt(DateTime.now());
    final result = await notificationService.requestPermission();
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Notification permission status: ${result.name}'),
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
      child: SwitchListTile.adaptive(
        key: const Key('settings-reusable-container-switch'),
        secondary: const Icon(Icons.eco_outlined),
        title: Text(l10n.reusableContainerTitle),
        subtitle: Text(l10n.reusableContainerDescription),
        value: settings.reusableContainerEnabled,
        onChanged: (value) async {
          await context
              .read<UserSettingsRepository>()
              .setReusableContainerEnabled(value);
        },
      ),
    );
  }
}

class _LocalFirstPrivacyCard extends StatelessWidget {
  final AppCapabilities capabilities;

  const _LocalFirstPrivacyCard({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localFirstPrivacyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    capabilities.cloudAi
                        ? l10n.optionalProviderConsumerDescription
                        : l10n.localFirstPrivacyDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _LegalAboutCard extends StatelessWidget {
  const _LegalAboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: const Key('settings-legal-about'),
        leading: const Icon(Icons.article_outlined),
        title: const Text('Legal & About'),
        subtitle: const Text(
          'Version ${HydrionReleaseMetadata.flutterVersionName} • ${HydrionReleaseMetadata.releaseDateLabel}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/legal-about'),
      ),
    );
  }
}

class _DebugDiagnosticsCard extends StatelessWidget {
  const _DebugDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(l10n.debugDiagnosticsTitle),
        subtitle: Text(l10n.debugDiagnosticsDescription),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed('/debug-diagnostics'),
      ),
    );
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
                    _modeLabel(capabilities, l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    capabilities.cloudAi
                        ? l10n.geminiProviderActiveDescription
                        : capabilities.geminiConfigured
                            ? l10n.geminiProviderConfiguredLocalDescription
                            : l10n.localDataNoProviderRuntime,
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

class _ProviderHealthCard extends StatelessWidget {
  final ProviderHealthSnapshot health;
  final bool nonLocalProviderConsentGranted;
  final ValueChanged<bool> onNonLocalProviderConsentChanged;

  const _ProviderHealthCard({
    required this.health,
    required this.nonLocalProviderConsentGranted,
    required this.onNonLocalProviderConsentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canToggleNonLocalProvider =
        health.selectedProvider == HydrionAiProviderKind.gemini &&
            health.geminiConfigured;

    return Card(
      key: const Key('provider-health-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.providerHealthTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HealthLine(
              label: l10n.selectedProvider,
              value: _providerLabel(health.selectedProvider, l10n),
            ),
            _HealthLine(
              label: l10n.activeProvider,
              value: _providerLabel(health.activeProvider, l10n),
            ),
            _HealthLine(
              label: l10n.providerGeminiConfigured,
              value: health.geminiConfigured
                  ? l10n.providerConfigured
                  : l10n.providerUnconfigured,
            ),
            _HealthLine(
              label: l10n.providerGeminiHealth,
              value: _diagnosticHealthLabel(health, l10n),
            ),
            _HealthLine(
              label: l10n.providerConsentStatus,
              value: health.privacyConsentRecorded ? l10n.yes : l10n.no,
            ),
            _HealthLine(
              label: l10n.providerLastDiagnosticPhase,
              value: health.diagnostic.lastDiagnosticCode,
            ),
            _HealthLine(
              label: l10n.providerFallbackState,
              value: _fallbackStateLabel(health, l10n),
            ),
            _HealthLine(
              label: l10n.localRulesProvider,
              value: health.localRulesAvailable
                  ? l10n.providerAvailable
                  : l10n.providerUnavailable,
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                l10n.providerDiagnosticsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                _HealthLine(
                  label: l10n.providerGeminiModel,
                  value: health.diagnostic.modelId ?? l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerEndpointHost,
                  value: health.diagnostic.endpointHost ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerModelPath,
                  value:
                      health.diagnostic.modelPath ?? l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerApiKeyPresent,
                  value: _yesNoOrUnavailable(
                    health.diagnostic.apiKeyPresent,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerApiKeyLength,
                  value: _numberOrUnavailable(
                    health.diagnostic.apiKeyLength,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerApiKeyFingerprint,
                  value: health.diagnostic.apiKeyFingerprint ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerApiKeyContainsWhitespace,
                  value: _yesNoOrUnavailable(
                    health.diagnostic.apiKeyContainsWhitespace,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerApiKeyWasTrimmed,
                  value: _yesNoOrUnavailable(
                    health.diagnostic.apiKeyWasTrimmed,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerApiKeyStartsWithGooglePrefix,
                  value: _yesNoOrUnavailable(
                    health.diagnostic.apiKeyStartsWithExpectedGooglePrefix,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerAuthHeaderPresent,
                  value: _yesNoOrUnavailable(
                    health.diagnostic.authHeaderPresent,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerAuthHeaderValueLength,
                  value: _numberOrUnavailable(
                    health.diagnostic.authHeaderValueLength,
                    l10n,
                  ),
                ),
                _HealthLine(
                  label: l10n.providerRequestAttempted,
                  value: _yesNo(health.diagnostic.requestAttempted, l10n),
                ),
                _HealthLine(
                  label: l10n.providerHttpStatusClass,
                  value: health.diagnostic.httpStatusClass ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerErrorStatus,
                  value: health.diagnostic.providerErrorStatus ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerErrorMessage,
                  value: health.diagnostic.providerErrorMessage ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerErrorDetails,
                  value: health.diagnostic.providerErrorDetailTypes.isEmpty
                      ? l10n.providerNotAvailable
                      : health.diagnostic.providerErrorDetailTypes.join(', '),
                ),
                _HealthLine(
                  label: l10n.providerParserCode,
                  value: health.diagnostic.parserRejectionCode ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerValidatorCode,
                  value: health.diagnostic.validatorRejectionCode ??
                      l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.providerBlockedCapabilities,
                  value: health.diagnostic.blockedCapabilityLabels.isEmpty
                      ? l10n.providerNotAvailable
                      : health.diagnostic.blockedCapabilityLabels.join(', '),
                ),
                _HealthLine(
                  label: l10n.providerFallbackCode,
                  value: _fallbackCode(health) ?? l10n.providerNotAvailable,
                ),
                _HealthLine(
                  label: l10n.elkaProvider,
                  value: health.elkaAvailable
                      ? l10n.providerAvailable
                      : l10n.providerUnavailable,
                ),
                _HealthLine(
                  label: l10n.providerLastSuccess,
                  value: _timestamp(health.diagnostic.lastSuccessAt, l10n),
                ),
                _HealthLine(
                  label: l10n.providerLastFailureAt,
                  value: _timestamp(health.diagnostic.lastFailureAt, l10n),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l10n.providerPrivacyTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              canToggleNonLocalProvider
                  ? l10n.providerPrivacyGeminiDisclosure
                  : l10n.providerPrivacyLocalOnly,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (canToggleNonLocalProvider) ...[
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                key: const Key('provider-privacy-consent-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.providerConsentToggleTitle),
                subtitle: Text(
                  nonLocalProviderConsentGranted
                      ? l10n.providerConsentEnabled
                      : l10n.providerConsentDisabled,
                ),
                value: nonLocalProviderConsentGranted,
                onChanged: onNonLocalProviderConsentChanged,
              ),
              if (!nonLocalProviderConsentGranted) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.providerConsentRequired,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _providerLabel(
    HydrionAiProviderKind provider,
    AppLocalizations l10n,
  ) {
    return switch (provider) {
      HydrionAiProviderKind.localRules => l10n.localRulesProvider,
      HydrionAiProviderKind.gemini => l10n.geminiProvider,
      HydrionAiProviderKind.elka => l10n.elkaProvider,
    };
  }

  String _yesNo(bool value, AppLocalizations l10n) {
    return value ? l10n.yes : l10n.no;
  }

  String _yesNoOrUnavailable(bool? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.providerNotAvailable;
    }
    return _yesNo(value, l10n);
  }

  String _numberOrUnavailable(int? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.providerNotAvailable;
    }
    return value.toString();
  }

  String _timestamp(DateTime? timestamp, AppLocalizations l10n) {
    if (timestamp == null) {
      return l10n.providerNotAvailable;
    }
    return timestamp.toLocal().toIso8601String();
  }

  String _fallbackStateLabel(
    ProviderHealthSnapshot health,
    AppLocalizations l10n,
  ) {
    if (health.fallbackReason != null) {
      return l10n.providerFallbackInUse;
    }
    if (health.localRulesAvailable) {
      return l10n.providerFallbackReady;
    }
    return l10n.providerUnavailable;
  }

  String? _fallbackCode(ProviderHealthSnapshot health) {
    final reason = health.fallbackReason;
    if (reason == null || reason.trim().isEmpty) {
      return null;
    }
    final separator = reason.indexOf(':');
    if (separator <= 0) {
      return reason.trim();
    }
    return reason.substring(0, separator).trim();
  }

  String _diagnosticHealthLabel(
    ProviderHealthSnapshot health,
    AppLocalizations l10n,
  ) {
    if (!health.geminiConfigured &&
        health.selectedProvider == HydrionAiProviderKind.gemini) {
      return l10n.providerDiagnosticNoApiKey;
    }
    if (health.diagnostic.responseEnvelopePhase ==
        ProviderDiagnosticCodes.providerConsentRequired) {
      return l10n.providerDiagnosticConsentRequired;
    }
    if (health.diagnostic.lastSuccessAt != null &&
        health.diagnostic.fallbackReason == null) {
      return l10n.providerDiagnosticHealthy;
    }
    if (health.diagnostic.fallbackReason != null) {
      return l10n.providerDiagnosticFallbackActive;
    }
    if (health.geminiConfigured && !health.diagnostic.requestAttempted) {
      return l10n.providerDiagnosticNotProven;
    }
    return l10n.providerDiagnosticLocalRules;
  }
}

class _HealthLine extends StatelessWidget {
  final String label;
  final String value;

  const _HealthLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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
            description: capabilities.cloudAi
                ? l10n.cloudAiConfiguredDescription
                : capabilities.geminiConfigured
                    ? l10n.cloudAiConsentRequiredDescription
                    : l10n.cloudAiDescription,
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
            description: capabilities.osNotifications
                ? 'Android local reminders can be scheduled after notification permission is granted.'
                : l10n.osNotificationsDescription,
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

String _modeLabel(AppCapabilities capabilities, AppLocalizations l10n) {
  if (capabilities.elkaConfigured) {
    return l10n.elkaAdapterConfiguredMode;
  }
  if (capabilities.geminiConfigured) {
    return l10n.geminiProviderConfiguredMode;
  }
  return l10n.standaloneLocalMode;
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
