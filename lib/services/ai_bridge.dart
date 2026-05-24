import '../adapters/local/local_hydrion_adapters.dart';
import '../domain/hydration_contracts.dart';
import '../repositories/hydration_repository.dart';

export '../domain/hydration_contracts.dart'
    show HydrationChallenge, HydrationSummary;

@Deprecated('Use HydrationSummaryService and ChallengeGenerator instead.')
class AIBridge implements HydrationSummaryService, ChallengeGenerator {
  final LocalHydrationSummaryService _summaryService;
  final LocalChallengeGenerator _challengeGenerator;

  AIBridge({HydrationRepository? hydrationRepository})
      : _summaryService = LocalHydrationSummaryService(
          hydrationRepository:
              hydrationRepository ?? HydrationRepository.memory(),
        ),
        _challengeGenerator = const LocalChallengeGenerator();

  @override
  Future<HydrationSummary> getHydrationSummary() {
    return _summaryService.getHydrationSummary();
  }

  @override
  Future<HydrationChallenge> createChallenge({required String userLevel}) {
    return _challengeGenerator.createChallenge(userLevel: userLevel);
  }
}
