enum HydrionBuildStage {
  alpha,
  beta,
  production,
}

class HydrionReleaseMetadata {
  static const productName = 'Hydrion';
  static const publicVersion = '1.1.0';
  static const buildNumber = 3;
  static const flutterVersionName = '$publicVersion+$buildNumber';
  static const releaseDateLabel = 'Release date pending';
  static const nextPlannedVersion = '1.2.0';
  static const metadataStatus = 'Draft';
  static const termsStatus = 'Owner review required';
  static const privacyStatus = 'Owner review required';
  static const healthSafetyStatus = 'Owner review required';
  static const androidApplicationIdStatus =
      'Configured as com.the1807.hydrion; store approval required';
  static const buildStageName = String.fromEnvironment(
    'HYDRION_BUILD_STAGE',
    defaultValue: 'alpha',
  );

  static const communityName = 'HydrionSharks';
  static const communityHandle = '@HydrionSharks';
  static const contactEmail = 'hydrionsharks@gmail.com';
  static const releaseLettersSubject = 'Join HydrionSharks release letters';

  static const knownLimitations = <String>[
    'Android local notification scheduling is implemented, but delivery still requires real-device permission, reboot, timezone, and battery-policy validation.',
    'Weather-informed goals use Open-Meteo forecasts when location permission is granted; notification permission is separate for reminders and still needs real-device validation.',
    'Social challenge sync is not connected; challenges are local-only.',
    'Production signing credentials, store release metadata, legal approval, and release date still require owner approval.',
  ];

  static const releaseChecklist = <String>[
    'Approve public release date.',
    'Approve Terms, Privacy, and Health/Safety copy with the product owner.',
    'Confirm the com.the1807.hydrion package identity before store upload.',
    'Configure production Android signing credentials before store upload.',
    'Validate location, forecast, notification delivery, reminders, migration, and accessibility on real devices.',
  ];

  static HydrionBuildStage get buildStage {
    return switch (buildStageName.toLowerCase()) {
      'production' || 'stable' || 'release' => HydrionBuildStage.production,
      'beta' => HydrionBuildStage.beta,
      _ => HydrionBuildStage.alpha,
    };
  }

  static bool get requiresAlphaBetaNotice =>
      buildStage == HydrionBuildStage.alpha ||
      buildStage == HydrionBuildStage.beta;

  static String get legalDocumentOpenRequiredMessage =>
      legalDocumentOpenRequiredMessageFor(buildStage);

  static String legalDocumentOpenRequiredMessageFor(
    HydrionBuildStage stage,
  ) {
    return switch (stage) {
      HydrionBuildStage.alpha ||
      HydrionBuildStage.beta =>
        'Open the required legal document before continuing.',
      HydrionBuildStage.production =>
        'Open the required legal document before continuing.',
    };
  }
}
