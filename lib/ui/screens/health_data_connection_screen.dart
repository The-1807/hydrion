import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/health_data.dart';
import '../../l10n/app_localizations.dart';
import '../../services/health_connection_controller.dart';
import '../components/hydrion_viewport.dart';

class HealthDataConnectionScreen extends StatefulWidget {
  const HealthDataConnectionScreen({super.key});

  @override
  State<HealthDataConnectionScreen> createState() =>
      _HealthDataConnectionScreenState();
}

class _HealthDataConnectionScreenState extends State<HealthDataConnectionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HealthConnectionController>().initialize();
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
      context.read<HealthConnectionController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<HealthConnectionController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isConnected
            ? l10n.healthDataDashboardTitle
            : l10n.healthDataTitle),
      ),
      body: ListView(
        padding: HydrionViewport.scrollPadding(context),
        children: [
          _StatusPanel(controller: controller),
          const SizedBox(height: 20),
          if (!controller.isConnected)
            const _ConsentSection()
          else
            _ConnectedDetails(controller: controller),
          const SizedBox(height: 20),
          _Actions(controller: controller),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final HealthConnectionController controller;

  const _StatusPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final visual = _visual(controller.state, theme.colorScheme);
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: 0.10),
          border: Border.all(color: visual.color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(visual.icon, color: visual.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _stateTitle(l10n, controller.state),
                      key: const Key('health-data-state-title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: visual.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${l10n.healthDataProvider}: '
                  '${_providerLabel(l10n, controller.providerId)}'),
              if (controller.state ==
                  HealthConnectionViewState.connectedNotSynchronized) ...[
                const SizedBox(height: 8),
                Text(l10n.healthDataNoSyncYet),
              ],
              if (controller.state ==
                  HealthConnectionViewState.synchronizing) ...[
                const SizedBox(height: 8),
                Text(l10n.healthDataReadingSecurely),
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  key: Key('health-data-sync-progress'),
                ),
              ],
              if (controller.state ==
                  HealthConnectionViewState.synchronizedNoRecords) ...[
                const SizedBox(height: 8),
                Text(l10n.healthDataNoDataExplanation),
              ],
              if (controller.state ==
                      HealthConnectionViewState.synchronizationFailed ||
                  controller.state ==
                      HealthConnectionViewState
                          .synchronizationPartiallySuccessful) ...[
                const SizedBox(height: 8),
                if (controller.state ==
                    HealthConnectionViewState.synchronizationFailed)
                  Text(l10n.healthDataLatestAttemptFailed),
                if (controller.successfulMetrics.isNotEmpty)
                  Text(l10n.healthDataSuccessfulCategories(
                    categories:
                        _metricLabels(l10n, controller.successfulMetrics),
                  )),
                if (controller.failedMetrics.isNotEmpty)
                  Text(l10n.healthDataFailedCategories(
                    categories: _metricLabels(l10n, controller.failedMetrics),
                  )),
                const SizedBox(height: 4),
                Text(_failureText(l10n, controller.failureReason)),
              ],
              if (controller.state ==
                      HealthConnectionViewState.permissionsRevoked ||
                  controller.state ==
                      HealthConnectionViewState.permissionPartiallyGranted) ...[
                const SizedBox(height: 8),
                Text(l10n.healthDataMissingCategories(
                  categories: _metricLabels(l10n, controller.missingMetrics),
                )),
              ],
              if (controller.lastSynchronizationOutcome != null &&
                  controller.lastAttemptedSynchronization != null) ...[
                const SizedBox(height: 8),
                Text(l10n.healthDataLastAttempt(
                  time: _dateTime(
                    context,
                    controller.lastAttemptedSynchronization!,
                  ),
                )),
              ],
              if (controller.lastSynchronizationOutcome != null &&
                  controller.lastSuccessfulSynchronization != null)
                Text(l10n.healthDataLastSuccessful(
                  time: _dateTime(
                    context,
                    controller.lastSuccessfulSynchronization!,
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }

  static _StateVisual _visual(
    HealthConnectionViewState state,
    ColorScheme colors,
  ) =>
      switch (state) {
        HealthConnectionViewState.synchronizedWithRecords ||
        HealthConnectionViewState.connectedNotSynchronized =>
          _StateVisual(Icons.check_circle_outline, colors.primary),
        HealthConnectionViewState.synchronizing ||
        HealthConnectionViewState.permissionRequesting ||
        HealthConnectionViewState.loading =>
          _StateVisual(Icons.sync, colors.primary),
        HealthConnectionViewState.synchronizedNoRecords ||
        HealthConnectionViewState.synchronizationPartiallySuccessful ||
        HealthConnectionViewState.permissionPartiallyGranted ||
        HealthConnectionViewState.permissionsRevoked =>
          _StateVisual(Icons.info_outline, colors.tertiary),
        HealthConnectionViewState.synchronizationFailed ||
        HealthConnectionViewState.providerUnavailable ||
        HealthConnectionViewState.permissionDenied =>
          _StateVisual(Icons.warning_amber_rounded, colors.error),
        _ => _StateVisual(Icons.health_and_safety_outlined, colors.primary),
      };

  static String _stateTitle(
    AppLocalizations l10n,
    HealthConnectionViewState state,
  ) =>
      switch (state) {
        HealthConnectionViewState.loading => l10n.healthDataLoading,
        HealthConnectionViewState.providerUnavailable =>
          l10n.healthDataProviderFailure,
        HealthConnectionViewState.installationRequired =>
          l10n.healthDataInstallationRequired,
        HealthConnectionViewState.updateRequired =>
          l10n.healthDataUpdateRequired,
        HealthConnectionViewState.unsupported => l10n.healthDataUnsupported,
        HealthConnectionViewState.disconnected => l10n.healthDataDisconnected,
        HealthConnectionViewState.consentRequired => l10n.healthDataAvailable,
        HealthConnectionViewState.permissionRequesting =>
          l10n.healthDataPermissionRequesting,
        HealthConnectionViewState.permissionDenied =>
          l10n.healthDataPermissionDenied,
        HealthConnectionViewState.permissionPartiallyGranted =>
          l10n.healthDataPermissionPartial,
        HealthConnectionViewState.connectedNotSynchronized =>
          l10n.healthDataConnectedNotSynchronized,
        HealthConnectionViewState.synchronizing => l10n.healthDataSynchronizing,
        HealthConnectionViewState.synchronizedWithRecords =>
          l10n.healthDataSynchronizedWithRecords,
        HealthConnectionViewState.synchronizedNoRecords =>
          l10n.healthDataSynchronizedNoRecords,
        HealthConnectionViewState.synchronizationPartiallySuccessful =>
          l10n.healthDataSyncPartial,
        HealthConnectionViewState.synchronizationFailed =>
          l10n.healthDataSyncFailed,
        HealthConnectionViewState.permissionsRevoked =>
          l10n.healthDataPermissionRevoked,
      };

  static String _failureText(AppLocalizations l10n, String? failure) =>
      switch (failure) {
        'protected_storage_unavailable' => l10n.healthDataStorageUnavailable,
        'permission_request_failed' ||
        'permissionRequired' ||
        'permissionDenied' =>
          l10n.healthDataReasonPermission,
        'provider_refresh_failed' ||
        'health_connect_unavailable' ||
        'unavailable' =>
          l10n.healthDataReasonUnavailable,
        _ => l10n.healthDataReasonOperation,
      };
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.healthDataConsentIntro),
        const SizedBox(height: 16),
        Text(l10n.healthDataCategories,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _MetricChips(
            metrics: context.read<HealthConnectionController>().metrics),
        const SizedBox(height: 8),
        Text(l10n.healthDataCategoryExplanation),
        const SizedBox(height: 16),
        Text(l10n.healthDataPrivacyExplanation),
        const SizedBox(height: 12),
        Text(l10n.healthDataWellnessDisclaimer),
      ],
    );
  }
}

class _ConnectedDetails extends StatelessWidget {
  final HealthConnectionController controller;

  const _ConnectedDetails({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sourceEntries = controller.contributingApplicationRecordCounts.entries
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.readAuthorizationIsOpaque
              ? l10n.healthDataAppleAccessRequested
              : controller.grantedMetrics.isEmpty
                  ? l10n.healthDataNoGrantedCategories
                  : l10n.healthDataGrantedCategories(
                      categories:
                          _metricLabels(l10n, controller.grantedMetrics),
                    ),
        ),
        if (controller.lastSynchronizationOutcome != null) ...[
          const SizedBox(height: 8),
          Text(l10n.healthDataSyncCounts(
            read: controller.lastRecordsRead,
            inserted: controller.lastInsertedCount,
            updated: controller.lastUpdatedCount,
            deleted: controller.lastDeletedCount,
            rejected: controller.lastRejectedCount,
          )),
        ],
        const SizedBox(height: 8),
        Text(l10n.healthDataImportedCount(
          count: controller.importedRecordCount,
        )),
        if (controller.earliestRecordTime case final start?)
          Text(l10n.healthDataRecordPeriod(
            start: _date(context, start),
            end: _date(context, controller.latestRecordTime ?? start),
          )),
        if (sourceEntries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.healthDataContributingSources),
          for (final entry in sourceEntries)
            Text(l10n.healthDataSourceCount(
              source: entry.key,
              count: entry.value,
            )),
        ] else if (controller.lastSynchronizationOutcome != null) ...[
          const SizedBox(height: 8),
          Text(l10n.healthDataNoContributors),
        ],
        if (controller.availableMetrics.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.healthDataDataAvailable,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _MetricChips(metrics: controller.availableMetrics, checked: true),
        ],
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(l10n.healthDataWhatReads),
          children: [
            Text(l10n.healthDataCategoryExplanation),
            const SizedBox(height: 12),
            Text(l10n.healthDataPrivacyExplanation),
            const SizedBox(height: 12),
            Text(l10n.healthDataWellnessDisclaimer),
          ],
        ),
      ],
    );
  }
}

class _MetricChips extends StatelessWidget {
  final Set<HealthMetric> metrics;
  final bool checked;

  const _MetricChips({required this.metrics, this.checked = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordered = context
        .read<HealthConnectionController>()
        .metrics
        .where(metrics.contains)
        .toList(growable: false);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metric in ordered)
          Chip(
            avatar: checked ? const Icon(Icons.check, size: 18) : null,
            label: Text(_metricLabel(l10n, metric)),
          ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final HealthConnectionController controller;

  const _Actions({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = controller.state == HealthConnectionViewState.loading ||
        controller.state == HealthConnectionViewState.permissionRequesting ||
        controller.state == HealthConnectionViewState.synchronizing;
    final retry =
        controller.state == HealthConnectionViewState.synchronizedNoRecords ||
            controller.state == HealthConnectionViewState.synchronizationFailed;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_canConnect(controller.state))
          FilledButton.icon(
            key: const Key('health-data-connect'),
            onPressed: busy ? null : controller.connect,
            icon: const Icon(Icons.link),
            label: Text(l10n.healthDataTitle),
          ),
        if (controller.isConnected && controller.missingMetrics.isNotEmpty)
          FilledButton.icon(
            key: const Key('health-data-request-missing'),
            onPressed: busy ? null : controller.requestMissingPermissions,
            icon: const Icon(Icons.add_moderator_outlined),
            label: Text(l10n.healthDataRequestMissing),
          ),
        if (controller.isConnected && controller.grantedMetrics.isNotEmpty)
          FilledButton.tonalIcon(
            key: const Key('health-data-sync'),
            onPressed: busy ? null : () => controller.synchronize(),
            icon: const Icon(Icons.sync),
            label:
                Text(retry ? l10n.healthDataTryAgain : l10n.healthDataSyncNow),
          ),
        if (controller.isConnected && controller.failedMetrics.isNotEmpty)
          FilledButton.tonalIcon(
            key: const Key('health-data-retry-failed'),
            onPressed: busy ? null : controller.retryFailedMetrics,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.healthDataRetryFailedCategories),
          ),
        OutlinedButton.icon(
          key: const Key('health-data-settings'),
          onPressed: busy ? null : controller.openSettings,
          icon: const Icon(Icons.settings_outlined),
          label: Text(controller.state ==
                  HealthConnectionViewState.synchronizedNoRecords
              ? l10n.healthDataCheckHealthConnect
              : l10n.healthDataManageAccess),
        ),
        if (controller.importedRecordCount > 0)
          TextButton.icon(
            key: const Key('health-data-delete'),
            onPressed: busy ? null : () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.healthDataDeleteImported),
          ),
        if (controller.isConnected)
          OutlinedButton.icon(
            key: const Key('health-data-disconnect'),
            onPressed: busy ? null : controller.disconnect,
            icon: const Icon(Icons.link_off),
            label: Text(l10n.healthDataDisconnect),
          ),
      ],
    );
  }

  static bool _canConnect(HealthConnectionViewState state) =>
      state == HealthConnectionViewState.consentRequired ||
      state == HealthConnectionViewState.disconnected ||
      state == HealthConnectionViewState.permissionDenied;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.healthDataDeleteQuestion),
        content: Text(l10n.healthDataDeleteExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.healthDataDeleteImported),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteImportedData();
  }
}

String _providerLabel(AppLocalizations l10n, String providerId) =>
    providerId == 'apple.health_kit'
        ? l10n.healthDataAppleHealth
        : l10n.healthDataHealthConnect;

class _StateVisual {
  final IconData icon;
  final Color color;

  const _StateVisual(this.icon, this.color);
}

String _metricLabels(AppLocalizations l10n, Set<HealthMetric> metrics) =>
    _displayMetrics
        .where(metrics.contains)
        .map((metric) => _metricLabel(l10n, metric))
        .join(', ');

const _displayMetrics = <HealthMetric>{
  HealthMetric.workout,
  HealthMetric.activeEnergy,
  HealthMetric.steps,
  HealthMetric.distance,
};

String _metricLabel(AppLocalizations l10n, HealthMetric metric) =>
    switch (metric) {
      HealthMetric.workout => l10n.healthDataWorkouts,
      HealthMetric.activeEnergy => l10n.healthDataActiveEnergy,
      HealthMetric.steps => l10n.healthDataSteps,
      HealthMetric.distance => l10n.healthDataDistance,
      _ => metric.name,
    };

String _dateTime(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_jm()
        .format(value.toLocal());

String _date(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(value.toLocal());
