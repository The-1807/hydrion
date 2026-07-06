import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/community_links.dart';
import '../../domain/hydration_contracts.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/reminder_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/achievement_service.dart';
import '../../services/profile_photo_service.dart';
import '../theme/hydrion_design.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsRepository>().settings;
    final hydrationRepository = context.watch<HydrationRepository>();
    final reminderRepository = context.watch<ReminderRepository>();
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);
    final today = DateTime.now();
    final achievements = const AchievementService().evaluate(
      hydrationRepository: hydrationRepository,
      now: today,
      activeGoalMl: settings.dailyGoalMl,
    );
    final unlocked = [
      achievements.dailyGoal,
      achievements.threeLogsToday,
      achievements.sevenDayStreak,
    ].where((achievement) => achievement.unlocked).length;

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('Profile'),
              actions: [_ProfileMenu(embedded: embedded)],
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          _ProfileHero(
            settings: settings,
            avatar: avatar,
            unlockedAchievements: unlocked,
          ),
          const SizedBox(height: 16),
          HydrionSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration identity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                _ProfileStat(
                  icon: Icons.flag_outlined,
                  label: 'Daily goal',
                  value: '${settings.dailyGoalMl} ml',
                ),
                _ProfileStat(
                  icon: Icons.straighten,
                  label: 'Units',
                  value: settings.volumeUnit == HydrionVolumeUnit.ounces
                      ? 'Ounces'
                      : 'Milliliters',
                ),
                _ProfileStat(
                  icon: Icons.local_drink_outlined,
                  label: 'Preferred container',
                  value: '${settings.containerSizeMl} ml',
                ),
                _ProfileStat(
                  icon: Icons.notifications_none,
                  label: 'Reminders',
                  value: reminderRepository.reminders.isEmpty
                      ? 'No reminders yet'
                      : '${reminderRepository.reminders.length} saved',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HydrionSurface(
            gradient: LinearGradient(
              colors: settings.goalMode == HydrionGoalMode.weatherInformed
                  ? [
                      HydrionColors.sunrise.withValues(alpha: 0.22),
                      HydrionColors.glow.withValues(alpha: 0.16),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.96),
                      HydrionColors.foam,
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Weather personalization',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_weatherStatus(settings)),
                if (settings.lastWeatherGoalExplanation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    settings.lastWeatherGoalExplanation!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('profile-edit-action'),
                onPressed: () => _openEditor(context, settings),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
              OutlinedButton.icon(
                key: const Key('profile-settings-action'),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
                icon: const Icon(Icons.tune),
                label: const Text('Settings'),
              ),
              if (capabilities.osNotifications)
                OutlinedButton.icon(
                  key: const Key('profile-reminders-action'),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/reminders'),
                  icon: const Icon(Icons.notifications_none),
                  label: const Text('Reminders'),
                ),
              OutlinedButton.icon(
                key: const Key('profile-legal-action'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/legal-about'),
                icon: const Icon(Icons.article_outlined),
                label: const Text('Legal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HydrionSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact: ${HydrionCommunityConfig.contactEmail}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hydrion has no sign-out action because this build does not use accounts or authentication.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weatherStatus(UserSettings settings) {
    if (settings.goalMode != HydrionGoalMode.weatherInformed) {
      return 'Manual mode is active. Enable weather goals when you want Hydrion to explain temperature-aware adjustments.';
    }
    if (settings.weatherAdjustedGoalActive) {
      final adjustment = settings.dailyGoalMl - settings.baselineDailyGoalMl;
      return 'Base goal: ${settings.baselineDailyGoalMl} ml. Weather adjustment: ${adjustment >= 0 ? '+' : ''}$adjustment ml. Today: ${settings.dailyGoalMl} ml.';
    }
    return 'Weather mode is enabled, but today has not applied a forecast adjustment yet.';
  }

  Future<void> _openEditor(BuildContext context, UserSettings settings) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProfileEditor(initialSettings: settings),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserSettings settings;
  final HydrionAvatar avatar;
  final int unlockedAchievements;

  const _ProfileHero({
    required this.settings,
    required this.avatar,
    required this.unlockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = settings.nickname?.trim();
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: Row(
        children: [
          _ProfileImage(settings: settings, avatar: avatar, size: 96),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname == null || nickname.isEmpty
                        ? 'Local Hydrion profile'
                        : nickname,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text('${avatar.displayName} is your shark companion.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill('${settings.dailyGoalMl} ml/day'),
                      _MiniPill(
                        settings.goalMode == HydrionGoalMode.weatherInformed
                            ? 'Weather-aware'
                            : 'Manual goal',
                      ),
                      _MiniPill('$unlockedAchievements badges'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const _ProfileMenu(embedded: true),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final UserSettings settings;
  final HydrionAvatar avatar;
  final double size;

  const _ProfileImage({
    required this.settings,
    required this.avatar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _decodePhoto(settings.profilePhotoBase64);
    final image = bytes == null
        ? Image.asset(
            avatar.assetPath,
            fit: BoxFit.cover,
            semanticLabel: avatar.displayName,
          )
        : Image.memory(
            bytes,
            fit: BoxFit.cover,
            semanticLabel: 'Local profile photo',
          );
    return ClipOval(
      child: SizedBox.square(
        key: const Key('profile-photo-avatar'),
        dimension: size,
        child: image,
      ),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  final UserSettings initialSettings;

  const _ProfileEditor({required this.initialSettings});

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _ageController;
  late final TextEditingController _containerController;
  late final TextEditingController _goalController;
  late HydrionSex? _sex;
  late HydrionVolumeUnit _unit;
  late HydrionGoalMode _goalMode;
  late String _avatarId;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _nicknameController = TextEditingController(text: settings.nickname ?? '');
    _ageController =
        TextEditingController(text: settings.age?.toString() ?? '');
    _containerController =
        TextEditingController(text: settings.containerSizeMl.toString());
    _goalController =
        TextEditingController(text: settings.dailyGoalMl.toString());
    _sex = settings.sex;
    _unit = settings.volumeUnit;
    _goalMode = settings.goalMode;
    _avatarId = settings.avatarId;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _containerController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repository = context.read<UserSettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final goal = int.tryParse(_goalController.text.trim());
    final container = int.tryParse(_containerController.text.trim());

    final profileSaved = await repository.setProfile(
      nickname: _nicknameController.text,
      age: age,
      sex: _sex,
    );
    if (!profileSaved || goal == null || container == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Check the profile fields and try again.')),
      );
      return;
    }
    await repository.setAvatarId(_avatarId);
    await repository.setVolumeUnit(_unit);
    await repository.setGoalMode(_goalMode);
    await repository.setDailyGoalMl(goal);
    await repository.setContainerSizeMl(container);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickPhoto() async {
    final picker = context.read<HydrionProfilePhotoPicker>();
    final repository = context.read<UserSettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final photo = await picker.pickProfilePhoto();
    if (!mounted || photo == null) {
      return;
    }
    final saved = await repository.setProfilePhotoBase64(photo.base64Data);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Profile photo saved locally.'
              : 'That photo was too large for local profile storage.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsRepository>().settings;
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
              ),
            ],
          ),
          const Text(
            'Update your Hydrion identity and preferences. This does not restart onboarding or delete history.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProfileImage(settings: settings, avatar: avatar, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('profile-pick-photo'),
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose photo'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('profile-remove-photo'),
                      onPressed: settings.profilePhotoBase64 == null
                          ? null
                          : () => context
                              .read<UserSettingsRepository>()
                              .clearProfilePhoto(),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Use shark'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('profile-edit-nickname'),
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('profile-edit-age'),
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<HydrionSex>(
            initialValue: _sex,
            decoration: const InputDecoration(
              labelText: 'Sex selection',
              border: OutlineInputBorder(),
            ),
            items: HydrionSex.values
                .map(
                  (sex) => DropdownMenuItem(
                    value: sex,
                    child: Text(_sexLabel(sex)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _sex = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _avatarId,
            decoration: const InputDecoration(
              labelText: 'Shark companion',
              border: OutlineInputBorder(),
            ),
            items: HydrionAvatarManifest.avatars
                .map(
                  (avatar) => DropdownMenuItem(
                    value: avatar.id,
                    child: Text(avatar.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _avatarId = value);
              }
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<HydrionVolumeUnit>(
            selected: {_unit},
            segments: const [
              ButtonSegment(
                value: HydrionVolumeUnit.milliliters,
                label: Text('mL'),
              ),
              ButtonSegment(
                value: HydrionVolumeUnit.ounces,
                label: Text('oz'),
              ),
            ],
            onSelectionChanged: (value) => setState(() => _unit = value.single),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Baseline daily goal in mL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _containerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Preferred container in mL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<HydrionGoalMode>(
            selected: {_goalMode},
            segments: const [
              ButtonSegment(
                value: HydrionGoalMode.manual,
                label: Text('Manual'),
              ),
              ButtonSegment(
                value: HydrionGoalMode.weatherInformed,
                label: Text('Weather'),
              ),
            ],
            onSelectionChanged: (value) =>
                setState(() => _goalMode = value.single),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('profile-save'),
            onPressed: _save,
            child: const Text('Save profile'),
          ),
          TextButton(
            key: const Key('profile-restart-guided-setup'),
            onPressed: () async {
              await context.read<UserSettingsRepository>().reopenOnboarding();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushReplacementNamed('/onboarding');
            },
            child: const Text('Restart guided setup'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill(this.label);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(HydrionRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final bool embedded;

  const _ProfileMenu({required this.embedded});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('profile-menu'),
      tooltip: 'Profile menu',
      icon: Icon(
        Icons.more_horiz,
        color: embedded ? Colors.white : null,
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            if (!embedded) {
              return;
            }
            Navigator.of(context).pushNamed('/profile');
            break;
          case 'settings':
            Navigator.of(context).pushNamed('/settings');
            break;
          case 'support':
            Navigator.of(context).pushNamed('/legal-about');
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'profile', child: Text('View Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuItem(value: 'support', child: Text('Support')),
      ],
    );
  }
}

Uint8List? _decodePhoto(String? base64Data) {
  if (base64Data == null || base64Data.isEmpty) {
    return null;
  }
  try {
    return base64Decode(base64Data);
  } on FormatException {
    return null;
  }
}

String _sexLabel(HydrionSex sex) {
  return switch (sex) {
    HydrionSex.female => 'Female',
    HydrionSex.male => 'Male',
    HydrionSex.intersex => 'Intersex',
    HydrionSex.preferNotToSay => 'Prefer not to say',
  };
}
