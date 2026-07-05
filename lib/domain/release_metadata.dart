class HydrionReleaseMetadata {
  static const productName = 'Hydrion';
  static const publicVersion = '1.0.0';
  static const buildNumber = 1;
  static const flutterVersionName = '$publicVersion+$buildNumber';
  static const releaseDateLabel = 'Release date pending';
  static const nextPlannedVersion = '1.1.0';

  static const communityName = 'HydrionSharks';
  static const communityHandle = '@HydrionSharks';
  static const contactEmail = 'hydrionsharks@gmail.com';
  static const releaseLettersSubject = 'Join HydrionSharks release letters';

  static const knownLimitations = <String>[
    'OS notification delivery is not connected in this build.',
    'Weather-informed goals are deterministic and require a configured forecast provider before use.',
    'Social challenge sync is not connected; challenges are local-only.',
    'Android signing and store release metadata still require owner approval.',
  ];

  static const releaseChecklist = <String>[
    'Approve public release date.',
    'Approve Terms, Privacy, and Health/Safety copy with the product owner.',
    'Configure production Android application id and signing before store upload.',
    'Verify notification and location permissions only after native adapters are connected.',
  ];
}
