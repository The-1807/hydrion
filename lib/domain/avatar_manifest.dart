class HydrionAvatar {
  final String id;
  final String displayName;
  final String description;
  final String assetPath;

  const HydrionAvatar({
    required this.id,
    required this.displayName,
    required this.description,
    required this.assetPath,
  });
}

class HydrionAvatarManifest {
  static const mascotAssetPath = 'assets/pfp_mascot/hydrion_mascot.png';

  static const avatars = <HydrionAvatar>[
    HydrionAvatar(
      id: 'savvy-eco_shark',
      displayName: 'Savvy Eco',
      description: 'Eco-minded and steady, for reusable-bottle routines.',
      assetPath: 'assets/pfp_mascot/pfp/savvy-eco_shark.png',
    ),
    HydrionAvatar(
      id: 'scout_shark',
      displayName: 'Scout',
      description: 'Curious and practical, for checking in throughout the day.',
      assetPath: 'assets/pfp_mascot/pfp/scout_shark.png',
    ),
    HydrionAvatar(
      id: 'sensei_shark',
      displayName: 'Sensei',
      description: 'Calm and focused, for gentle habit building.',
      assetPath: 'assets/pfp_mascot/pfp/sensei_shark.png',
    ),
    HydrionAvatar(
      id: 'slicky_shark',
      displayName: 'Slicky',
      description: 'Smooth and upbeat, for quick daily tracking.',
      assetPath: 'assets/pfp_mascot/pfp/slicky_shark.png',
    ),
    HydrionAvatar(
      id: 'smartty_shark',
      displayName: 'Smartty',
      description: 'Analytical and tidy, for goal-aware hydration logs.',
      assetPath: 'assets/pfp_mascot/pfp/smartty_shark.png',
    ),
    HydrionAvatar(
      id: 'snss',
      displayName: 'SNSS',
      description:
          'A preserved community avatar name awaiting owner direction.',
      assetPath: 'assets/pfp_mascot/pfp/snss.png',
    ),
    HydrionAvatar(
      id: 'strong_shark',
      displayName: 'Strong',
      description: 'Reliable and direct, for consistent everyday goals.',
      assetPath: 'assets/pfp_mascot/pfp/strong_shark.png',
    ),
    HydrionAvatar(
      id: 'sundown_shark',
      displayName: 'Sundown',
      description: 'Relaxed evening energy, for winding down without rushing.',
      assetPath: 'assets/pfp_mascot/pfp/sundown_shark.png',
    ),
    HydrionAvatar(
      id: 'supercool_shark',
      displayName: 'Supercool',
      description: 'Cool and playful, for keeping hydration light.',
      assetPath: 'assets/pfp_mascot/pfp/supercool_shark.png',
    ),
    HydrionAvatar(
      id: 'superhappy_shark',
      displayName: 'Superhappy',
      description: 'Bright and cheerful, for celebrating small wins.',
      assetPath: 'assets/pfp_mascot/pfp/superhappy_shark.png',
    ),
  ];

  static HydrionAvatar byId(String? id) {
    return avatars.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => avatars.first,
    );
  }
}
