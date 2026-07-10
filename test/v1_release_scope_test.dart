import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/avatar_manifest.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/companion_state.dart';
import 'package:hydrion/domain/legal_document_registry.dart';
import 'package:hydrion/domain/release_metadata.dart';
import 'package:hydrion/domain/ui_asset_manifest.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('avatar manifest preserves supplied shark identities and assets', () {
    expect(HydrionAvatarManifest.mascotAssetPath,
        'assets/pfp_mascot/hydrion_mascot.jpg');
    expect(HydrionAvatarManifest.sharkAvatars, hasLength(10));
    expect(HydrionAvatarManifest.humanAvatars, isEmpty);
    expect(HydrionAvatarManifest.removedHumanAvatarIds, hasLength(19));
    expect(HydrionAvatarManifest.avatars, hasLength(10));
    expect(
      HydrionAvatarManifest.sharkAvatars.map((avatar) => avatar.displayName),
      containsAll([
        'Savvy Eco',
        'Scout',
        'Sensei',
        'Slicky',
        'Smartty',
        'SNSS',
        'Strong',
        'Sundown',
        'Supercool',
        'Superhappy',
      ]),
    );
    expect(HydrionAvatarManifest.byId('snss').assetPath,
        'assets/pfp_mascot/pfp/snss.jpg');
    expect(HydrionAvatarManifest.byId('hydrion-human-river').id,
        'savvy-eco_shark');
    expect(HydrionAvatarManifest.isRemovedHumanAvatarId('hydrion-human-river'),
        isTrue);
    expect(HydrionAvatarManifest.byId('missing').id, 'savvy-eco_shark');
  });

  test('UI asset manifest separates lifestyle scenes from profile avatars', () {
    expect(HydrionUiAssetManifest.lifestyleScenes, hasLength(9));
    expect(HydrionUiAssetManifest.byId('sip-break').assetPath,
        'assets/UI_BETA/hydrion-lifestyle-sip-break.jpg');
    expect(
      HydrionUiAssetManifest.lifestyleScenes.map((scene) => scene.assetPath),
      everyElement(
        allOf(
          startsWith('assets/UI_BETA/'),
          isNot(contains('ChatGPT Image')),
          isNot(contains(' ')),
        ),
      ),
    );
  });

  test('profile and onboarding settings persist across repository reloads',
      () async {
    final store = MemoryHydrionStore();
    final first = await UserSettingsRepository.load(store);

    expect(first.settings.onboardingCompleted, isFalse);
    expect(
        await first.setProfile(
          nickname: '  Shark Friend  ',
          age: 29,
          sex: HydrionSex.intersex,
        ),
        isTrue);
    expect(await first.setAvatarId('superhappy_shark'), isTrue);
    expect(await first.setProfilePhotoBase64('AQIDBA=='), isTrue);
    await first.setGoalMode(HydrionGoalMode.weatherInformed);
    await first.setVolumeUnit(HydrionVolumeUnit.ounces);
    expect(await first.setContainerSizeMl(750), isTrue);
    await first.setOnboardingCompleted(
      completed: true,
      legalAndHealthAcknowledged: true,
    );

    final second = await UserSettingsRepository.load(store);

    expect(second.settings.nickname, 'Shark Friend');
    expect(second.settings.age, 29);
    expect(second.settings.sex, HydrionSex.intersex);
    expect(second.settings.avatarId, 'superhappy_shark');
    expect(second.settings.profilePhotoBase64, 'AQIDBA==');
    expect(second.settings.goalMode, HydrionGoalMode.weatherInformed);
    expect(second.settings.volumeUnit, HydrionVolumeUnit.ounces);
    expect(second.settings.containerSizeMl, 750);
    expect(second.settings.onboardingCompleted, isTrue);
    expect(second.settings.legalAndHealthAcknowledged, isTrue);
    expect(
      second.settings.acceptedTermsVersion,
      HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
    );
    expect(
      second.settings.acknowledgedHealthDisclaimerVersion,
      HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
    );
    expect(
      second.settings.privacyPolicyVersionShown,
      HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion,
    );

    await second.clearProfilePhoto();
    final third = await UserSettingsRepository.load(store);
    expect(third.settings.profilePhotoBase64, isNull);
  });

  test('invalid profile settings recover to safe defaults', () {
    final settings = UserSettings.fromJson({
      'languageCode': 'en',
      'nickname': 'x' * 80,
      'age': 4,
      'sex': 'unknown',
      'avatarId': 'renamed-by-guessing',
      'profilePhotoBase64': 'not a valid base64 image',
      'goalMode': 'mystery',
      'volumeUnit': 'cups',
      'containerSizeMl': 9000,
      'dailyGoalMl': 99999,
    });

    expect(settings.nickname, isNull);
    expect(settings.age, isNull);
    expect(settings.sex, isNull);
    expect(settings.avatarId, 'savvy-eco_shark');
    expect(settings.profilePhotoBase64, isNull);
    expect(settings.goalMode, HydrionGoalMode.manual);
    expect(settings.volumeUnit, HydrionVolumeUnit.milliliters);
    expect(settings.containerSizeMl, UserSettings.defaultContainerSizeMl);
    expect(settings.dailyGoalMl, UserSettings.defaultDailyGoalMl);

    final migrated = UserSettings.fromJson({
      'avatarId': 'hydrion-human-river',
    });
    expect(migrated.avatarId, HydrionAvatarManifest.defaultAvatarId);
  });

  test('companion state reacts to weather and completed goals', () {
    const director = HydrionCompanionDirector();
    const weatherSettings = UserSettings(
      locale: UserSettings.fallbackLocale,
      goalMode: HydrionGoalMode.weatherInformed,
      weatherAdjustedGoalActive: true,
      lastWeatherGoalExplanation: 'Heat added a small adjustment.',
    );

    final weatherState = director.select(
      hydrationPercent: 35,
      entryCount: 1,
      settings: weatherSettings,
      now: DateTime(2026, 7, 5, 10),
    );

    expect(weatherState.mood, HydrionCompanionMood.hotWeather);
    expect(weatherState.message, contains('Heat added'));

    final completeState = director.select(
      hydrationPercent: 101,
      entryCount: 4,
      settings: const UserSettings(locale: UserSettings.fallbackLocale),
      now: DateTime(2026, 7, 5, 18),
    );

    expect(completeState.mood, HydrionCompanionMood.goalComplete);
    expect(completeState.title, 'Goal reached');
  });

  test('weather goal recommendation is deterministic bounded and explainable',
      () {
    const service = DeterministicWeatherGoalService();
    final decision = service.recommend(
      WeatherGoalInputs(
        baselineGoalMl: 2200,
        age: 31,
        sex: HydrionSex.female,
        locationPermissionGranted: true,
        notificationPermissionGranted: true,
        weather: WeatherSnapshot(
          temperatureC: 34,
          humidityPercent: 75,
          uvIndex: 9,
          observedAt: DateTime(2026, 7, 5, 12),
        ),
        userAdjustmentMl: 80,
      ),
    );

    expect(decision.eligible, isTrue);
    expect(decision.weatherAdjustmentMl, 500);
    expect(decision.userAdjustmentMl, 80);
    expect(decision.recommendedGoalMl, 2800);
    expect(decision.explanation, contains('Baseline 2200 ml'));

    final notificationDeniedDecision = service.recommend(
      WeatherGoalInputs(
        baselineGoalMl: 2200,
        age: 31,
        sex: HydrionSex.female,
        locationPermissionGranted: true,
        notificationPermissionGranted: false,
        weather: WeatherSnapshot(
          temperatureC: 27,
          humidityPercent: 50,
          uvIndex: 0,
          observedAt: DateTime(2026, 7, 5, 12),
        ),
      ),
    );
    expect(notificationDeniedDecision.eligible, isTrue);

    final ineligible = service.recommend(
      WeatherGoalInputs(
        baselineGoalMl: 2200,
        age: 31,
        sex: HydrionSex.preferNotToSay,
        weather: WeatherSnapshot(
          temperatureC: 40,
          humidityPercent: 90,
          uvIndex: 10,
          observedAt: DateTime(2026, 7, 5, 12),
        ),
      ),
    );

    expect(ineligible.eligible, isFalse);
    expect(ineligible.recommendedGoalMl, 2200);
    expect(ineligible.explanation, contains('Manual goal kept'));
  });

  test('challenge catalogue contains safe local v1 challenges', () {
    expect(HydrionChallengeCatalog.challenges, hasLength(7));
    expect(
      HydrionChallengeCatalog.challenges.map((challenge) => challenge.name),
      containsAll([
        'Around the World Infusion Week',
        'Temperature Roulette',
        'Eat Your Water Day',
        'Front-Loader Challenge',
        'Pomodoro Sip',
        'Plant Twin Challenge',
        'Bottle Bingo',
      ]),
    );
    for (final challenge in HydrionChallengeCatalog.challenges) {
      expect(challenge.safetyNote, HydrionChallengeCatalog.safetyNote);
      expect(
          challenge.targetMl,
          inInclusiveRange(
              UserSettings.minDailyGoalMl, UserSettings.maxDailyGoalMl));
      expect(challenge.description.toLowerCase(), isNot(contains('urine')));
      expect(challenge.description.toLowerCase(), isNot(contains('force')));
    }
    final bottleBingo = HydrionChallengeCatalog.byId('bottle-bingo');
    expect(bottleBingo.dailyTask, 'Logged water before lunch.');
    expect(
        bottleBingo.description.toLowerCase(), isNot(contains('peed clear')));
    expect(bottleBingo.description.toLowerCase(), isNot(contains('wager')));
  });

  test('Bottle Bingo progress comes from water logged before lunch', () async {
    final hydrationRepository = HydrationRepository.memory();
    final challengeRepository = ChallengeRepository.memory();
    final bottleBingo = HydrionChallengeCatalog.byId('bottle-bingo');
    final today = DateTime.now();

    await challengeRepository.join(
      id: bottleBingo.id,
      name: bottleBingo.name,
      description: bottleBingo.description,
      targetMl: bottleBingo.targetMl,
      durationDays: bottleBingo.durationDays,
      joinedAt: DateTime(today.year, today.month, today.day),
    );
    await hydrationRepository.addLog(
      volumeMl: 250,
      timestamp: DateTime(today.year, today.month, today.day, 13),
    );

    expect(
      challengeRepository.progressFor(hydrationRepository).completedDays,
      0,
    );

    await hydrationRepository.addLog(
      volumeMl: 150,
      timestamp: DateTime(today.year, today.month, today.day, 9),
    );

    final progress = challengeRepository.progressFor(hydrationRepository);
    expect(progress.completedDays, 1);
    expect(progress.todayMl, 150);
  });

  test('Bottle Bingo manual tiles persist with active challenge state',
      () async {
    final store = MemoryHydrionStore();
    final first = await ChallengeRepository.load(store);
    final bottleBingo = HydrionChallengeCatalog.byId('bottle-bingo');

    await first.join(
      id: bottleBingo.id,
      name: bottleBingo.name,
      description: bottleBingo.description,
      targetMl: bottleBingo.targetMl,
      durationDays: bottleBingo.durationDays,
      joinedAt: DateTime(2026, 7, 6),
    );

    expect(await first.toggleBottleBingoTile(2), isTrue);
    expect(await first.toggleBottleBingoTile(5), isTrue);
    expect(await first.toggleBottleBingoTile(1), isFalse);
    expect(await first.toggleBottleBingoTile(0), isFalse);

    final second = await ChallengeRepository.load(store);
    expect(second.activeChallenge?.bottleBingoCompletedTiles, {2, 5});

    expect(await second.resetBottleBingoTiles(), isTrue);
    final third = await ChallengeRepository.load(store);
    expect(third.activeChallenge?.bottleBingoCompletedTiles, isEmpty);
  });

  test('Bottle Bingo hydration tile creates one normal hydration log',
      () async {
    final hydrationRepository = HydrationRepository.memory();
    final challengeRepository = ChallengeRepository.memory();
    final bottleBingo = HydrionChallengeCatalog.byId('bottle-bingo');
    final today = DateTime.now();
    final timestamp = DateTime(today.year, today.month, today.day, 10);

    await challengeRepository.join(
      id: bottleBingo.id,
      name: bottleBingo.name,
      description: bottleBingo.description,
      targetMl: bottleBingo.targetMl,
      durationDays: bottleBingo.durationDays,
      joinedAt: DateTime(today.year, today.month, today.day),
    );

    final log = await challengeRepository.completeBottleBingoHydrationTile(
      index: 4,
      hydrationRepository: hydrationRepository,
      volumeMl: 150,
      timestamp: timestamp,
    );

    expect(log, isNotNull);
    expect(hydrationRepository.logs, hasLength(1));
    expect(hydrationRepository.logs.single.id, log!.id);
    expect(hydrationRepository.logs.single.source,
        'challenge:bottle-bingo:tile-4');
    expect(hydrationRepository.totalForDay(today), 150);
    expect(
      challengeRepository.progressFor(hydrationRepository).todayMl,
      150,
    );
    expect(
      challengeRepository.activeChallenge?.bottleBingoCompletedTiles,
      contains(4),
    );

    final duplicate =
        await challengeRepository.completeBottleBingoHydrationTile(
      index: 4,
      hydrationRepository: hydrationRepository,
      volumeMl: 150,
      timestamp: timestamp,
    );

    expect(duplicate, isNull);
    expect(hydrationRepository.logs, hasLength(1));
    expect(hydrationRepository.totalForDay(today), 150);

    expect(await challengeRepository.resetBottleBingoTiles(), isTrue);
    expect(
      challengeRepository.activeChallenge?.bottleBingoCompletedTiles,
      contains(4),
    );

    final afterReset =
        await challengeRepository.completeBottleBingoHydrationTile(
      index: 4,
      hydrationRepository: hydrationRepository,
      volumeMl: 150,
      timestamp: timestamp,
    );

    expect(afterReset, isNull);
    expect(hydrationRepository.logs, hasLength(1));
  });

  test('release metadata keeps v1 identity and pending release date explicit',
      () {
    expect(HydrionReleaseMetadata.productName, 'Hydrion');
    expect(HydrionReleaseMetadata.flutterVersionName, '1.0.0+1');
    expect(HydrionReleaseMetadata.releaseDateLabel, 'Release date pending');
    expect(HydrionReleaseMetadata.communityName, 'HydrionSharks');
    expect(HydrionReleaseMetadata.contactEmail, 'hydrionsharks@gmail.com');
  });
}
