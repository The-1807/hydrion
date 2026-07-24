import 'profile_art_registry.dart';

class HydrionUiScene {
  final String id;
  final String label;
  final String description;
  final String assetPath;
  final String intendedUse;

  const HydrionUiScene({
    required this.id,
    required this.label,
    required this.description,
    required this.assetPath,
    required this.intendedUse,
  });
}

class HydrionUiAssetManifest {
  static const successCheckAssetPath = 'assets/UI_BETA/green-check.png';
  static const hotSummerAssetPath = 'assets/UI_BETA/hot-summer.png';

  static const lifestyleScenes = <HydrionUiScene>[
    HydrionUiScene(
      id: 'app-check',
      label: 'App Check',
      description: 'A Hydrion user checking the app after a water log.',
      assetPath: 'assets/UI_BETA/man-checking-app.png',
      intendedUse: 'Home ritual rail, onboarding/product atmosphere.',
    ),
    HydrionUiScene(
      id: 'blue-kit',
      label: 'Tracked Intake',
      description: 'A Hydrion intake tracking illustration.',
      assetPath: 'assets/UI_BETA/tracked_intake.png',
      intendedUse: 'Progress, profile, or empty-state accent.',
    ),
    HydrionUiScene(
      id: 'neutral-bottle',
      label: 'Hydrion Bottle',
      description: 'A neutral Hydrion water bottle illustration.',
      assetPath: 'assets/UI_BETA/ble_bottle.png',
      intendedUse: 'Safe neutral profile-aware fallback.',
    ),
    HydrionUiScene(
      id: 'neutral-infusion',
      label: 'Infused Water',
      description: 'A neutral infused-water bottle illustration.',
      assetPath: 'assets/UI_BETA/arounddworld.png',
      intendedUse: 'Safe neutral routine and profile fallback.',
    ),
    HydrionUiScene(
      id: 'neutral-temperature',
      label: 'Water Temperature',
      description: 'A neutral hot-and-cold water dispenser illustration.',
      assetPath: 'assets/UI_BETA/temp-roulette.png',
      intendedUse: 'Safe neutral progress and empty-state fallback.',
    ),
    HydrionUiScene(
      id: 'bottle-break',
      label: 'Bottle Break',
      description: 'A person taking a relaxed Hydrion bottle break.',
      assetPath: 'assets/UI_BETA/drinking-man.png',
      intendedUse: 'Challenge and routine-building surfaces.',
    ),
    HydrionUiScene(
      id: 'cooldown',
      label: 'Cooldown',
      description: 'A Hydrion character ready after a workout or walk.',
      assetPath: 'assets/UI_BETA/workout-man.png',
      intendedUse: 'Progress dashboard and activity-adjacent moments.',
    ),
    HydrionUiScene(
      id: 'plan-check',
      label: 'Plan Check',
      description: 'A Hydrion user reviewing progress on a phone.',
      assetPath: 'assets/UI_BETA/lady-checking-app.png',
      intendedUse: 'Home daily-plan and weather-goal panels.',
    ),
    HydrionUiScene(
      id: 'portrait',
      label: 'Drink Break',
      description: 'A Hydrion user drinking water.',
      assetPath: 'assets/UI_BETA/drinking-lady.png',
      intendedUse: 'Brand atmosphere only; not a selectable profile photo.',
    ),
    HydrionUiScene(
      id: 'community-run',
      label: 'Community Run',
      description: 'A local challenge community run illustration.',
      assetPath: 'assets/UI_BETA/community-run.png',
      intendedUse: 'Local challenge and social-coming-soon context.',
    ),
    HydrionUiScene(
      id: 'challenge',
      label: 'Challenge',
      description: 'A Hydrion challenge illustration.',
      assetPath: 'assets/UI_BETA/challenge.png',
      intendedUse: 'Challenge dock and active challenge context.',
    ),
    HydrionUiScene(
      id: 'goals',
      label: 'Goals',
      description: 'A Hydrion goals illustration.',
      assetPath: 'assets/UI_BETA/goals.png',
      intendedUse: 'Goal setup and hydration target context.',
    ),
    HydrionUiScene(
      id: 'goals-lady',
      label: 'Goals',
      description: 'A Hydrion user reviewing hydration goals.',
      assetPath: 'assets/UI_BETA/goals-lady.png',
      intendedUse: 'Goal setup and hydration target context.',
    ),
    HydrionUiScene(
      id: 'men-goals',
      label: 'Goals',
      description: 'A Hydrion user reviewing hydration goals.',
      assetPath: 'assets/UI_BETA/men-goals.png',
      intendedUse: 'Goal setup and hydration target context.',
    ),
    HydrionUiScene(
      id: 'weather',
      label: 'Weather',
      description: 'A Hydrion weather illustration.',
      assetPath: 'assets/UI_BETA/weather.png',
      intendedUse: 'Weather goal and daily condition context.',
    ),
    HydrionUiScene(
      id: 'hot-summer',
      label: 'Hot Summer',
      description: 'A Hydrion hot weather illustration.',
      assetPath: hotSummerAssetPath,
      intendedUse: 'Active heat/weather-adjusted goal context.',
    ),
    HydrionUiScene(
      id: 'runner',
      label: 'Runner',
      description: 'A Hydrion runner ready for an active routine.',
      assetPath: 'assets/UI_BETA/running-man.png',
      intendedUse: 'Active routine and challenge cards.',
    ),
    HydrionUiScene(
      id: 'runner-ready',
      label: 'Runner Ready',
      description: 'A Hydrion user ready for a light active routine.',
      assetPath: 'assets/UI_BETA/running-lady.png',
      intendedUse: 'Challenges and active routine cards.',
    ),
    HydrionUiScene(
      id: 'sip-break',
      label: 'Sip Break',
      description: 'A calm hydration sip with the Hydrion bottle.',
      assetPath: 'assets/UI_BETA/drinking-lady.png',
      intendedUse: 'Home daily ritual and coach-safe suggestions.',
    ),
    HydrionUiScene(
      id: 'studio-bottle',
      label: 'Workout Routine',
      description: 'A Hydrion user in an active routine.',
      assetPath: 'assets/UI_BETA/workout-lady.png',
      intendedUse: 'Profile and polished brand moments.',
    ),
    HydrionUiScene(
      id: 'pride-be-proud',
      label: 'Be Proud',
      description: 'A Pride encouragement illustration.',
      assetPath: 'assets/UI_BETA/pride/be-proud.png',
      intendedUse: 'Intersex progress, celebration, and empty-state moments.',
    ),
    HydrionUiScene(
      id: 'pride-eat-your-water',
      label: 'Eat Your Water',
      description: 'A Pride hydration-food illustration.',
      assetPath: 'assets/UI_BETA/pride/eat-your-water.png',
      intendedUse: 'Intersex Eat Your Water challenge support.',
    ),
    HydrionUiScene(
      id: 'pride-gender',
      label: 'Profile Identity',
      description: 'A Pride identity illustration.',
      assetPath: 'assets/UI_BETA/pride/gender_icon.png',
      intendedUse: 'Intersex profile summary.',
    ),
    HydrionUiScene(
      id: 'pride-banner',
      label: 'Pride Progress',
      description: 'A Pride banner illustration.',
      assetPath: 'assets/UI_BETA/pride/pride-banner.png',
      intendedUse: 'Intersex home and progress encouragement.',
    ),
    HydrionUiScene(
      id: 'pride-bottle',
      label: 'Pride Hydration',
      description: 'A Pride hydration bottle illustration.',
      assetPath: 'assets/UI_BETA/pride/pride-bottle.png',
      intendedUse: 'Intersex welcome and hydration moments.',
    ),
  ];

  static HydrionUiScene byId(String id) {
    return lifestyleScenes.firstWhere(
      (scene) => scene.id == id,
      orElse: () => lifestyleScenes.first,
    );
  }
}

enum HydrionLifestyleSurface {
  homePrimary,
  homeSecondary,
  homeTertiary,
  homeQuaternary,
  weather,
  progress,
  challenges,
  profile,
  onboarding,
  emptyState,
  recommendation,
}

enum HydrionLifestylePresentation {
  male,
  female,
  intersex,
  neutral,
}

class HydrionLifestyleArtResolver {
  const HydrionLifestyleArtResolver._();

  static HydrionLifestylePresentation presentationFor(Object? sex) {
    return switch (HydrionProfileArtResolver.presentationFor(sex)) {
      HydrionProfileArtPresentation.male => HydrionLifestylePresentation.male,
      HydrionProfileArtPresentation.female =>
        HydrionLifestylePresentation.female,
      HydrionProfileArtPresentation.intersex =>
        HydrionLifestylePresentation.intersex,
      HydrionProfileArtPresentation.neutral =>
        HydrionLifestylePresentation.neutral,
    };
  }

  static HydrionUiScene sceneFor({
    required HydrionLifestyleSurface surface,
    required Object? sex,
  }) {
    final presentation = presentationFor(sex);
    final id = switch (presentation) {
      HydrionLifestylePresentation.male => _maleSceneId(surface),
      HydrionLifestylePresentation.female => _femaleSceneId(surface),
      HydrionLifestylePresentation.intersex => _intersexSceneId(surface),
      HydrionLifestylePresentation.neutral => _neutralSceneId(surface),
    };
    return HydrionUiAssetManifest.byId(id);
  }

  static List<HydrionUiScene> homeRailScenes(Object? sex) {
    return [
      sceneFor(surface: HydrionLifestyleSurface.homePrimary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeSecondary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeTertiary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeQuaternary, sex: sex),
    ];
  }

  static String _maleSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'men-goals',
      HydrionLifestyleSurface.homeSecondary => 'bottle-break',
      HydrionLifestyleSurface.homeTertiary => 'runner',
      HydrionLifestyleSurface.homeQuaternary => 'cooldown',
      HydrionLifestyleSurface.weather => 'weather',
      HydrionLifestyleSurface.progress => 'runner',
      HydrionLifestyleSurface.challenges => 'challenge',
      HydrionLifestyleSurface.profile => 'app-check',
      HydrionLifestyleSurface.onboarding => 'men-goals',
      HydrionLifestyleSurface.emptyState => 'bottle-break',
      HydrionLifestyleSurface.recommendation => 'bottle-break',
    };
  }

  static String _femaleSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'sip-break',
      HydrionLifestyleSurface.homeSecondary => 'goals-lady',
      HydrionLifestyleSurface.homeTertiary => 'runner-ready',
      HydrionLifestyleSurface.homeQuaternary => 'studio-bottle',
      HydrionLifestyleSurface.weather => 'weather',
      HydrionLifestyleSurface.progress => 'runner-ready',
      HydrionLifestyleSurface.challenges => 'challenge',
      HydrionLifestyleSurface.profile => 'studio-bottle',
      HydrionLifestyleSurface.onboarding => 'goals-lady',
      HydrionLifestyleSurface.emptyState => 'sip-break',
      HydrionLifestyleSurface.recommendation => 'plan-check',
    };
  }

  static String _neutralSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'neutral-bottle',
      HydrionLifestyleSurface.homeSecondary => 'neutral-infusion',
      HydrionLifestyleSurface.homeTertiary => 'weather',
      HydrionLifestyleSurface.homeQuaternary => 'neutral-temperature',
      HydrionLifestyleSurface.weather => 'weather',
      HydrionLifestyleSurface.progress => 'neutral-bottle',
      HydrionLifestyleSurface.challenges => 'challenge',
      HydrionLifestyleSurface.profile => 'neutral-infusion',
      HydrionLifestyleSurface.onboarding => 'neutral-bottle',
      HydrionLifestyleSurface.emptyState => 'neutral-temperature',
      HydrionLifestyleSurface.recommendation => 'neutral-infusion',
    };
  }

  static String _intersexSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'pride-bottle',
      HydrionLifestyleSurface.homeSecondary => 'neutral-infusion',
      HydrionLifestyleSurface.homeTertiary => 'pride-banner',
      HydrionLifestyleSurface.homeQuaternary => 'neutral-temperature',
      HydrionLifestyleSurface.weather => 'weather',
      HydrionLifestyleSurface.progress => 'pride-be-proud',
      HydrionLifestyleSurface.challenges => 'challenge',
      HydrionLifestyleSurface.profile => 'pride-gender',
      HydrionLifestyleSurface.onboarding => 'pride-bottle',
      HydrionLifestyleSurface.emptyState => 'pride-be-proud',
      HydrionLifestyleSurface.recommendation => 'neutral-infusion',
    };
  }
}
