import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/avatar_manifest.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/release_metadata.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('avatar manifest preserves supplied shark identities and assets', () {
    expect(HydrionAvatarManifest.mascotAssetPath,
        'assets/pfp_mascot/hydrion_mascot.png');
    expect(HydrionAvatarManifest.avatars, hasLength(10));
    expect(
      HydrionAvatarManifest.avatars.map((avatar) => avatar.displayName),
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
        'assets/pfp_mascot/pfp/snss.png');
    expect(HydrionAvatarManifest.byId('missing').id, 'savvy-eco_shark');
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
    expect(second.settings.goalMode, HydrionGoalMode.weatherInformed);
    expect(second.settings.volumeUnit, HydrionVolumeUnit.ounces);
    expect(second.settings.containerSizeMl, 750);
    expect(second.settings.onboardingCompleted, isTrue);
    expect(second.settings.legalAndHealthAcknowledged, isTrue);
  });

  test('invalid profile settings recover to safe defaults', () {
    final settings = UserSettings.fromJson({
      'languageCode': 'en',
      'nickname': 'x' * 80,
      'age': 4,
      'sex': 'unknown',
      'avatarId': 'renamed-by-guessing',
      'goalMode': 'mystery',
      'volumeUnit': 'cups',
      'containerSizeMl': 9000,
      'dailyGoalMl': 99999,
    });

    expect(settings.nickname, isNull);
    expect(settings.age, isNull);
    expect(settings.sex, isNull);
    expect(settings.avatarId, 'savvy-eco_shark');
    expect(settings.goalMode, HydrionGoalMode.manual);
    expect(settings.volumeUnit, HydrionVolumeUnit.milliliters);
    expect(settings.containerSizeMl, UserSettings.defaultContainerSizeMl);
    expect(settings.dailyGoalMl, UserSettings.defaultDailyGoalMl);
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
