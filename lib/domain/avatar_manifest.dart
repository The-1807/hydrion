enum HydrionAvatarKind {
  shark,
}

class HydrionAvatar {
  final String id;
  final String displayName;
  final String description;
  final String assetPath;
  final HydrionAvatarKind kind;

  const HydrionAvatar({
    required this.id,
    required this.displayName,
    required this.description,
    required this.assetPath,
    this.kind = HydrionAvatarKind.shark,
  });

  bool get isHuman => false;
}

class HydrionAvatarManifest {
  static const mascotAssetPath = 'assets/pfp_mascot/hydrion_mascot.jpg';
  static const defaultAvatarId = 'savvy-eco_shark';

  static const sharkAvatars = <HydrionAvatar>[
    HydrionAvatar(
      id: 'savvy-eco_shark',
      displayName: 'Savvy Eco',
      description: 'Eco-minded and steady, for reusable-bottle routines.',
      assetPath: 'assets/pfp_mascot/pfp/savvy-eco_shark.jpg',
    ),
    HydrionAvatar(
      id: 'scout_shark',
      displayName: 'Scout',
      description: 'Curious and practical, for checking in throughout the day.',
      assetPath: 'assets/pfp_mascot/pfp/scout_shark.jpg',
    ),
    HydrionAvatar(
      id: 'sensei_shark',
      displayName: 'Sensei',
      description: 'Calm and focused, for gentle habit building.',
      assetPath: 'assets/pfp_mascot/pfp/sensei_shark.jpg',
    ),
    HydrionAvatar(
      id: 'slicky_shark',
      displayName: 'Slicky',
      description: 'Smooth and upbeat, for quick daily tracking.',
      assetPath: 'assets/pfp_mascot/pfp/slicky_shark.jpg',
    ),
    HydrionAvatar(
      id: 'smartty_shark',
      displayName: 'Smartty',
      description: 'Analytical and tidy, for goal-aware hydration logs.',
      assetPath: 'assets/pfp_mascot/pfp/smartty_shark.jpg',
    ),
    HydrionAvatar(
      id: 'snss',
      displayName: 'SNSS',
      description:
          'A preserved community avatar name awaiting owner direction.',
      assetPath: 'assets/pfp_mascot/pfp/snss.jpg',
    ),
    HydrionAvatar(
      id: 'strong_shark',
      displayName: 'Strong',
      description: 'Reliable and direct, for consistent everyday goals.',
      assetPath: 'assets/pfp_mascot/pfp/strong_shark.jpg',
    ),
    HydrionAvatar(
      id: 'sundown_shark',
      displayName: 'Sundown',
      description: 'Relaxed evening energy, for winding down without rushing.',
      assetPath: 'assets/pfp_mascot/pfp/sundown_shark.jpg',
    ),
    HydrionAvatar(
      id: 'supercool_shark',
      displayName: 'Supercool',
      description: 'Cool and playful, for keeping hydration light.',
      assetPath: 'assets/pfp_mascot/pfp/supercool_shark.jpg',
    ),
    HydrionAvatar(
      id: 'superhappy_shark',
      displayName: 'Superhappy',
      description: 'Bright and cheerful, for celebrating small wins.',
      assetPath: 'assets/pfp_mascot/pfp/superhappy_shark.jpg',
    ),
  ];

  static const removedHumanAvatarIds = <String>{
    'hydrion-human-anchor',
    'hydrion-human-bloom',
    'hydrion-human-bluebell',
    'hydrion-human-breeze',
    'hydrion-human-compass',
    'hydrion-human-cove',
    'hydrion-human-current',
    'hydrion-human-drift',
    'hydrion-human-harbor',
    'hydrion-human-lagoon',
    'hydrion-human-mist',
    'hydrion-human-pearl',
    'hydrion-human-reef',
    'hydrion-human-river',
    'hydrion-human-silver',
    'hydrion-human-splash',
    'hydrion-human-sunrise',
    'hydrion-human-tide',
    'hydrion-human-wave',
  };

  static const humanAvatars = <HydrionAvatar>[];

  static const avatars = <HydrionAvatar>[...sharkAvatars];

  static HydrionAvatar byId(String? id) {
    return avatars.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => avatars.first,
    );
  }

  static bool isRemovedHumanAvatarId(String? id) {
    return id != null && removedHumanAvatarIds.contains(id.trim());
  }

  static HydrionAvatar companionByProfileAvatarId(String? id) {
    return byId(id);
  }
}
