import '../repositories/settings_repository.dart';

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
  neutral,
}

class HydrionLifestyleArtResolver {
  const HydrionLifestyleArtResolver._();

  static HydrionLifestylePresentation presentationFor(HydrionSex? sex) {
    return switch (sex) {
      HydrionSex.male => HydrionLifestylePresentation.male,
      HydrionSex.female => HydrionLifestylePresentation.female,
      HydrionSex.intersex ||
      HydrionSex.preferNotToSay ||
      null =>
        HydrionLifestylePresentation.neutral,
    };
  }

  static HydrionUiScene sceneFor({
    required HydrionLifestyleSurface surface,
    required HydrionSex? sex,
  }) {
    final presentation = presentationFor(sex);
    final id = switch (presentation) {
      HydrionLifestylePresentation.male => _maleSceneId(surface),
      HydrionLifestylePresentation.female => _femaleSceneId(surface),
      HydrionLifestylePresentation.neutral => _neutralSceneId(surface),
    };
    return HydrionUiAssetManifest.byId(id);
  }

  static List<HydrionUiScene> homeRailScenes(HydrionSex? sex) {
    return [
      sceneFor(surface: HydrionLifestyleSurface.homePrimary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeSecondary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeTertiary, sex: sex),
      sceneFor(surface: HydrionLifestyleSurface.homeQuaternary, sex: sex),
    ];
  }

  static String _maleSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'app-check',
      HydrionLifestyleSurface.homeSecondary => 'bottle-break',
      HydrionLifestyleSurface.homeTertiary => 'blue-kit',
      HydrionLifestyleSurface.homeQuaternary => 'cooldown',
      HydrionLifestyleSurface.weather => 'app-check',
      HydrionLifestyleSurface.progress => 'blue-kit',
      HydrionLifestyleSurface.challenges => 'runner',
      HydrionLifestyleSurface.profile => 'app-check',
      HydrionLifestyleSurface.onboarding => 'app-check',
      HydrionLifestyleSurface.emptyState => 'blue-kit',
      HydrionLifestyleSurface.recommendation => 'bottle-break',
    };
  }

  static String _femaleSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'sip-break',
      HydrionLifestyleSurface.homeSecondary => 'plan-check',
      HydrionLifestyleSurface.homeTertiary => 'runner-ready',
      HydrionLifestyleSurface.homeQuaternary => 'studio-bottle',
      HydrionLifestyleSurface.weather => 'plan-check',
      HydrionLifestyleSurface.progress => 'runner-ready',
      HydrionLifestyleSurface.challenges => 'runner-ready',
      HydrionLifestyleSurface.profile => 'studio-bottle',
      HydrionLifestyleSurface.onboarding => 'portrait',
      HydrionLifestyleSurface.emptyState => 'sip-break',
      HydrionLifestyleSurface.recommendation => 'plan-check',
    };
  }

  static String _neutralSceneId(HydrionLifestyleSurface surface) {
    return switch (surface) {
      HydrionLifestyleSurface.homePrimary => 'blue-kit',
      HydrionLifestyleSurface.homeSecondary => 'cooldown',
      HydrionLifestyleSurface.homeTertiary => 'plan-check',
      HydrionLifestyleSurface.homeQuaternary => 'bottle-break',
      HydrionLifestyleSurface.weather => 'plan-check',
      HydrionLifestyleSurface.progress => 'cooldown',
      HydrionLifestyleSurface.challenges => 'community-run',
      HydrionLifestyleSurface.profile => 'blue-kit',
      HydrionLifestyleSurface.onboarding => 'blue-kit',
      HydrionLifestyleSurface.emptyState => 'cooldown',
      HydrionLifestyleSurface.recommendation => 'plan-check',
    };
  }
}
