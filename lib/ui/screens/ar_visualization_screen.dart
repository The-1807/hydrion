import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';

class ArVisualizationScreen extends StatelessWidget {
  const ArVisualizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final arEnabled = capabilities.arVisualization;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.arTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_in_ar,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                arEnabled
                    ? l10n.arCapabilityReportedNoAdapter
                    : l10n.arDisabledStandalone,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                arEnabled ? l10n.arCapabilityNoSession : l10n.arNoPluginActive,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
