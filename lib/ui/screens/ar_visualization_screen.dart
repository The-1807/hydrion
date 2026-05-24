import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/i18n_resolver.dart';

class ArVisualizationScreen extends StatelessWidget {
  const ArVisualizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('ar_title', 'AR Hydration View')),
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
                'AR is disabled in this standalone build.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'No AR plugin, camera permission, or native AR session is active.',
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
