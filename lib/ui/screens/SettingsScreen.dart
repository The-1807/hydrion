import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/i18n_resolver.dart';
import '../../utils/permissions.dart';

/// SettingsScreen — language + permissions
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale? _selected;

  @override
  void initState() {
    super.initState();
    // Best-effort guess of current locale; fallback to first supported.
    _selected = I18nResolver.supportedLocales.first;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final perms = context.read<Permissions>();
    final dir = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('settings_title', 'Settings'), textDirection: dir),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Text(i18n.getText('language', 'Language'),
                            textDirection: dir, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        DropdownButton<Locale>(
                          value: _selected,
                          isExpanded: true,
                          items: I18nResolver.supportedLocales.map((loc) {
                            return DropdownMenuItem(
                              value: loc,
                              child: Text(
                                loc.languageCode.toUpperCase(),
                                textDirection: dir,
                              ),
                            );
                          }).toList(),
                          onChanged: (loc) async {
                            if (loc == null) return;
                            setState(() => _selected = loc);
                            await i18n.loadLocale(loc);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(i18n.getText('lang_updated', 'Language updated'))),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.verified_user),
              title: Text(i18n.getText('permissions', 'Permissions'), textDirection: dir),
              subtitle: Text(
                i18n.getText('manage_permissions', 'Manage app permissions'),
                textDirection: dir,
              ),
              onTap: () async {
                await perms.requestPermissions();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(i18n.getText('permissions_updated', 'Permissions updated'))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
