import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/permission_localizations.dart';
import '../../utils/permissions.dart';
import '../components/hydrion_viewport.dart';

class PermissionCenterScreen extends StatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  State<PermissionCenterScreen> createState() => _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends State<PermissionCenterScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<Permissions>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<Permissions>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<Permissions>();
    final snapshot = permissions.snapshot;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.permissions), centerTitle: true),
      body: ListView(
        key: const Key('permission-center-scroll-view'),
        padding: HydrionViewport.scrollPadding(context),
        children: [
          Text(
            l10n.optionalDeviceAccess,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(l10n.optionalDeviceAccessHelp),
          const SizedBox(height: 16),
          _PermissionCard(
            key: const Key('permission-notifications-card'),
            icon: Icons.notifications_outlined,
            title: l10n.hydrationReminders,
            capability: snapshot.notifications,
            allowLabel: l10n.allowNotifications,
            continueLabel: l10n.continueWithoutReminders,
            onAllow: permissions.requestNotifications,
            onSettings: permissions.openNotificationSettings,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            key: const Key('permission-location-card'),
            icon: Icons.location_on_outlined,
            title: l10n.weatherAssistance,
            capability: snapshot.location,
            allowLabel: l10n.allowLocation,
            continueLabel: l10n.continueWithStandardGoal,
            onAllow: permissions.requestLocation,
            onSettings: snapshot.location.state ==
                    HydrionPermissionState.temporarilyUnavailable
                ? permissions.openLocationServices
                : permissions.openLocationSettings,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            key: const Key('permission-exact-alarm-card'),
            icon: Icons.alarm_outlined,
            title: l10n.preciseReminderTiming,
            capability: snapshot.exactAlarms,
            allowLabel: l10n.openAlarmSettings,
            continueLabel: l10n.continueApproximateScheduling,
            onAllow: permissions.requestExactAlarms,
            onSettings: permissions.openAppSettings,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('refresh-permission-status'),
            onPressed: permissions.refreshing ? null : permissions.refresh,
            icon: permissions.refreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(l10n.refreshStatus),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final HydrionPermissionCapability capability;
  final String allowLabel;
  final String continueLabel;
  final Future<Object?> Function() onAllow;
  final Future<bool> Function() onSettings;

  const _PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.capability,
    required this.allowLabel,
    required this.continueLabel,
    required this.onAllow,
    required this.onSettings,
  });

  @override
  State<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<_PermissionCard> {
  bool _requesting = false;

  Future<void> _run(Future<Object?> Function() action) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await action();
      if (mounted) {
        await context.read<Permissions>().refresh();
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capability = widget.capability;
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _requesting
                            ? l10n.requesting
                            : l10n.permissionState(capability.state),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _requesting
                  ? l10n.waitingPermissionResult
                  : l10n.permissionMessage(capability.message),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (capability.isGranted)
                  FilledButton(
                    onPressed: null,
                    child: Text(l10n.capabilityEnabled(title: widget.title)),
                  ),
                if (capability.canRequestDirectly ||
                    (widget.title == l10n.preciseReminderTiming &&
                        capability.state == HydrionPermissionState.denied))
                  FilledButton(
                    onPressed: _requesting ? null : () => _run(widget.onAllow),
                    child: _requesting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.allowLabel),
                  ),
                if (capability.settingsRequired)
                  OutlinedButton(
                    onPressed:
                        _requesting ? null : () => _run(widget.onSettings),
                    child: Text(l10n.openDeviceSettings),
                  ),
                if (!capability.isGranted)
                  TextButton(
                    onPressed:
                        _requesting ? null : () => Navigator.maybePop(context),
                    child: Text(widget.continueLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
