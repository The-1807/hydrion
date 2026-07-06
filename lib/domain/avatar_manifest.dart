enum HydrionAvatarKind {
  shark,
  human,
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

  bool get isHuman => kind == HydrionAvatarKind.human;
}

class HydrionAvatarManifest {
  static const mascotAssetPath = 'assets/pfp_mascot/hydrion_mascot.jpg';

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

  static const humanAvatars = <HydrionAvatar>[
    HydrionAvatar(
      id: 'hydrion-human-anchor',
      displayName: 'Anchor',
      description: 'A grounded default profile portrait.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-anchor.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-bloom',
      displayName: 'Bloom',
      description: 'Bright profile energy for steady daily routines.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-bloom.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-bluebell',
      displayName: 'Bluebell',
      description: 'A colorful profile portrait with gentle confidence.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-bluebell.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-breeze',
      displayName: 'Breeze',
      description: 'A calm profile portrait for easy check-ins.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-breeze.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-compass',
      displayName: 'Compass',
      description: 'A polished profile portrait for focused tracking.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-compass.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-cove',
      displayName: 'Cove',
      description: 'Warm profile energy for a local-first routine.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-cove.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-current',
      displayName: 'Current',
      description: 'Clean profile energy for momentum days.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-current.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-drift',
      displayName: 'Drift',
      description: 'A relaxed default portrait for lighter routines.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-drift.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-harbor',
      displayName: 'Harbor',
      description: 'Steady profile energy for reliable daily logging.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-harbor.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-lagoon',
      displayName: 'Lagoon',
      description: 'Friendly profile energy for hydrated mornings.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-lagoon.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-mist',
      displayName: 'Mist',
      description: 'Soft profile energy for quiet consistency.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-mist.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-pearl',
      displayName: 'Pearl',
      description: 'A simple, polished default profile portrait.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-pearl.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-reef',
      displayName: 'Reef',
      description: 'Confident profile energy for active routines.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-reef.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-river',
      displayName: 'River',
      description: 'Friendly profile energy for steady hydration.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-river.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-silver',
      displayName: 'Silver',
      description: 'A composed profile portrait for long-term habits.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-silver.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-splash',
      displayName: 'Splash',
      description: 'Upbeat profile energy for quick water logs.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-splash.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-sunrise',
      displayName: 'Sunrise',
      description: 'Bright profile energy for the first check-in.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-sunrise.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-tide',
      displayName: 'Tide',
      description: 'Clean profile energy for daily progress.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-tide.jpg',
      kind: HydrionAvatarKind.human,
    ),
    HydrionAvatar(
      id: 'hydrion-human-wave',
      displayName: 'Wave',
      description: 'A lively default portrait for hydration wins.',
      assetPath: 'assets/pfp_mascot/hpfp/hydrion-human-wave.jpg',
      kind: HydrionAvatarKind.human,
    ),
  ];

  static const avatars = <HydrionAvatar>[
    ...sharkAvatars,
    ...humanAvatars,
  ];

  static HydrionAvatar byId(String? id) {
    return avatars.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => avatars.first,
    );
  }

  static HydrionAvatar companionByProfileAvatarId(String? id) {
    final avatar = byId(id);
    if (avatar.kind == HydrionAvatarKind.shark) {
      return avatar;
    }
    return sharkAvatars.first;
  }
}
