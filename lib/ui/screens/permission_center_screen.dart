import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions'), centerTitle: true),
      body: ListView(
        key: const Key('permission-center-scroll-view'),
        padding: HydrionViewport.scrollPadding(context),
        children: [
          const Text(
            'Optional device access',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hydrion works with a standard hydration goal even when you skip these options.',
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            key: const Key('permission-notifications-card'),
            icon: Icons.notifications_outlined,
            title: 'Hydration reminders',
            capability: snapshot.notifications,
            allowLabel: 'Allow notifications',
            continueLabel: 'Continue without reminders',
            onAllow: permissions.requestNotifications,
            onSettings: permissions.openNotificationSettings,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            key: const Key('permission-location-card'),
            icon: Icons.location_on_outlined,
            title: 'Weather assistance',
            capability: snapshot.location,
            allowLabel: 'Allow location',
            continueLabel: 'Continue with standard goal',
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
            title: 'Precise reminder timing',
            capability: snapshot.exactAlarms,
            allowLabel: 'Open Alarms and reminders settings',
            continueLabel: 'Continue with approximate scheduling',
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
            label: const Text('Refresh status'),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_stateLabel(capability.state)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(capability.explanation),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (capability.canRequestDirectly ||
                    (title == 'Precise reminder timing' &&
                        capability.state == HydrionPermissionState.denied))
                  FilledButton(
                    onPressed: onAllow,
                    child: Text(allowLabel),
                  ),
                if (capability.settingsRequired)
                  OutlinedButton(
                    onPressed: onSettings,
                    child: const Text('Open device settings'),
                  ),
                if (!capability.isGranted)
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(continueLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(HydrionPermissionState state) {
    return switch (state) {
      HydrionPermissionState.notRequested => 'Not requested',
      HydrionPermissionState.granted => 'Allowed',
      HydrionPermissionState.approximateGranted =>
        'Approximate location allowed',
      HydrionPermissionState.preciseGranted => 'Precise location allowed',
      HydrionPermissionState.denied => 'Denied',
      HydrionPermissionState.permanentlyDenied => 'Blocked',
      HydrionPermissionState.restricted => 'Restricted',
      HydrionPermissionState.notRequired => 'Not required',
      HydrionPermissionState.unsupported => 'Unsupported',
      HydrionPermissionState.temporarilyUnavailable =>
        'Temporarily unavailable',
      HydrionPermissionState.unknown => 'Status unavailable',
    };
  }
}
