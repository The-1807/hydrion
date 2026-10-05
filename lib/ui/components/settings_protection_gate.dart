import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/locale_registry.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/settings_protection.dart';
import '../../repositories/app_locale_repository.dart';
import '../../services/profile_photo_service.dart';

/// Unknown classified settings cannot drive onboarding, targets or consent UI.
/// Ordinary theme settings remain independently accessible below.
class SettingsProtectionGate extends StatefulWidget {
  final Widget child;
  const SettingsProtectionGate({super.key, required this.child});
  @override
  State<SettingsProtectionGate> createState() => _SettingsProtectionGateState();
}

class _SettingsProtectionGateState extends State<SettingsProtectionGate> {
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      // Repository status remains authoritative. Never render raw exceptions.
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<UserSettingsRepository>();
    final l10n = AppLocalizations.of(context);
    if (repository.isKnown) {
      if (repository.protectionStatus == SettingsProtectionStatus.ready) {
        return widget.child;
      }
      return Column(children: [
        MaterialBanner(content: Text(l10n.profileStorageIncomplete), actions: [
          TextButton(
              onPressed: busy ? null : () => run(repository.retryProtection),
              child: Text(l10n.retry)),
        ]),
        Expanded(child: widget.child),
      ]);
    }
    final invalidPhoto = repository.protectionStatus ==
        SettingsProtectionStatus.invalidLegacyPhoto;
    return Scaffold(
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Icon(Icons.lock_outline, size: 36),
                const SizedBox(height: 16),
                Text(invalidPhoto
                    ? l10n.profilePhotoMigrationBlocked
                    : l10n.profileStorageUnavailable),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed:
                        busy ? null : () => run(repository.retryProtection),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry)),
                if (invalidPhoto)
                  OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async => run(() async {
                                final picker =
                                    context.read<HydrionProfilePhotoPicker>();
                                final selected =
                                    await picker.pickProfilePhoto();
                                if (selected != null) {
                                  await repository
                                      .setProfilePhotoBytes(selected.bytes);
                                }
                              }),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.choosePhoto)),
                const SizedBox(height: 16),
                DropdownButton<HydrionThemePreference>(
                    value: repository.settings.themePreference,
                    items: HydrionThemePreference.values
                        .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(switch (value) {
                              HydrionThemePreference.system =>
                                l10n.useDeviceSetting,
                              HydrionThemePreference.automatic =>
                                l10n.automaticDayNight,
                              HydrionThemePreference.light => l10n.dayTheme,
                              HydrionThemePreference.dark => l10n.nightTheme,
                            })))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) {
                            if (value != null) {
                              run(() => repository.setThemePreference(value));
                            }
                          }),
                DropdownButton<String>(
                  value:
                      context.watch<AppLocaleRepository>().locale.languageCode,
                  items: HydrionLocaleRegistry.productionLocales
                      .map((entry) => DropdownMenuItem(
                          value: entry.locale.languageCode,
                          child: Text(entry.nativeName)))
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) {
                            run(() => context
                                .read<AppLocaleRepository>()
                                .selectLocale(Locale(value)));
                          }
                        },
                ),
              ],
            )),
      ))),
    );
  }
}
