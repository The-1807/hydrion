import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/i18n_resolver.dart';
import '../../utils/permissions.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('settings_title', 'Settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i18n.getText('language', 'Language'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        DropdownButton<Locale>(
                          value: _selected,
                          isExpanded: true,
                          items: I18nResolver.supportedLocales.map((locale) {
                            return DropdownMenuItem(
                              value: locale,
                              child: Text(locale.languageCode.toUpperCase()),
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
                                  content: Text(i18n.getText(
                                      'lang_updated', 'Language updated'))),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user),
              title: Text(i18n.getText('permissions', 'Permissions')),
              subtitle: const Text(
                'Standalone mode does not request BLE, Health, voice, or notification permissions.',
              ),
              onTap: () async {
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
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.bluetooth_disabled),
                  title: Text('BLE bottle sync disabled'),
                  subtitle: Text('No Bluetooth scan or connection is started.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Health sync disabled'),
                  subtitle: Text('No HealthKit or Google Fit data is read.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.mic_off),
                  title: Text('Voice input disabled'),
                  subtitle: Text(
                      'Commands can be typed; microphone capture is not active.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_off_outlined),
                  title: Text('OS notifications disabled'),
                  subtitle:
                      Text('Reminder definitions are saved locally only.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
