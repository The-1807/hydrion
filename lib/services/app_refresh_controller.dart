import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

class AppRefreshController {
  final HydrationRepository hydrationRepository;
  final ChallengeRepository challengeRepository;
  final UserSettingsRepository settingsRepository;
  Future<AppRefreshResult>? _inFlight;

  AppRefreshController({
    required this.hydrationRepository,
    required this.challengeRepository,
    required this.settingsRepository,
  });

  Future<AppRefreshResult> refresh() => _inFlight ??= _run();

  Future<AppRefreshResult> _run() async {
    try {
      await hydrationRepository.refreshFromStore();
      await challengeRepository.refreshFromStore();
      await settingsRepository.refreshFromStore();
      return AppRefreshResult.success;
    } catch (_) {
      return AppRefreshResult.failed;
    } finally {
      _inFlight = null;
    }
  }
}

enum AppRefreshResult { success, failed }
