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
  static const lifestyleScenes = <HydrionUiScene>[
    HydrionUiScene(
      id: 'app-check',
      label: 'App Check',
      description: 'A Hydrion user checking the app after a water log.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-app-check.png',
      intendedUse: 'Home ritual rail, onboarding/product atmosphere.',
    ),
    HydrionUiScene(
      id: 'blue-kit',
      label: 'Blue Kit',
      description: 'A Hydrion lifestyle figure holding a bottle.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-blue-kit.png',
      intendedUse: 'Progress, profile, or empty-state accent.',
    ),
    HydrionUiScene(
      id: 'bottle-break',
      label: 'Bottle Break',
      description: 'A person taking a relaxed Hydrion bottle break.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-bottle-break.png',
      intendedUse: 'Challenge and routine-building surfaces.',
    ),
    HydrionUiScene(
      id: 'cooldown',
      label: 'Cooldown',
      description: 'A Hydrion character ready after a workout or walk.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-cooldown.png',
      intendedUse: 'Progress dashboard and activity-adjacent moments.',
    ),
    HydrionUiScene(
      id: 'plan-check',
      label: 'Plan Check',
      description: 'A Hydrion user reviewing progress on a phone.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-plan-check.png',
      intendedUse: 'Home daily-plan and weather-goal panels.',
    ),
    HydrionUiScene(
      id: 'portrait',
      label: 'Portrait',
      description: 'A cropped Hydrion lifestyle portrait.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-portrait.png',
      intendedUse: 'Brand atmosphere only; not a selectable profile photo.',
    ),
    HydrionUiScene(
      id: 'runner-ready',
      label: 'Runner Ready',
      description: 'A Hydrion user ready for a light active routine.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-runner-ready.png',
      intendedUse: 'Challenges and active routine cards.',
    ),
    HydrionUiScene(
      id: 'sip-break',
      label: 'Sip Break',
      description: 'A calm hydration sip with the Hydrion bottle.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-sip-break.png',
      intendedUse: 'Home daily ritual and coach-safe suggestions.',
    ),
    HydrionUiScene(
      id: 'studio-bottle',
      label: 'Studio Bottle',
      description: 'A Hydrion user holding a bottle in a studio pose.',
      assetPath: 'assets/UI_BETA/hydrion-lifestyle-studio-bottle.png',
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
