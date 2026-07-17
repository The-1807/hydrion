import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

class AppRefreshController {
  final HydrationRepository hydrationRepository;
  final ChallengeRepository challengeRepository;
  final UserSettingsRepository settingsRepository;
  Future<void>? _inFlight;

  AppRefreshController({
    required this.hydrationRepository,
    required this.challengeRepository,
    required this.settingsRepository,
  });

  Future<void> refresh() => _inFlight ??= _run();

  Future<void> _run() async {
    try {
      await hydrationRepository.refreshFromStore();
      await challengeRepository.refreshFromStore();
      await settingsRepository.refreshFromStore();
    } finally {
      _inFlight = null;
    }
  }
}

Future<void> refreshHydrionData(BuildContext context) async {
  try {
    await context.read<AppRefreshController>().refresh();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't refresh everything. Your saved hydration data is still available.",
        ),
      ),
    );
  }
}
