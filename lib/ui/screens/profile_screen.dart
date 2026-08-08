import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/community_links.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/asset_localizations.dart';
import '../../l10n/challenge_localizations.dart';
import '../../repositories/reminder_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/profile_photo_service.dart';
import '../theme/hydrion_design.dart';
import '../components/hydrion_viewport.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsRepository>().settings;
    final l10n = AppLocalizations.of(context);
    final reminderRepository = context.watch<ReminderRepository>();
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(l10n.profileTitle),
              actions: [_ProfileMenu(embedded: embedded)],
            ),
      body: ListView(
        key: const Key('profile-scroll-view'),
        padding: HydrionViewport.scrollPadding(
          context,
          top: 20,
          bottom: 28,
          includeSystemBottom: !embedded,
        ),
        children: [
          _ProfileHero(
            settings: settings,
            avatar: avatar,
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
                label: Text(l10n.editProfile),
              ),
              OutlinedButton.icon(
                key: const Key('profile-body-metrics-action'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/body-metrics'),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: Text(l10n.bodyMetricsTitle),
              ),
              OutlinedButton.icon(
                key: const Key('profile-settings-action'),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
                icon: const Icon(Icons.tune),
                label: Text(l10n.settingsTitle),
              ),
              if (capabilities.osNotifications)
                OutlinedButton.icon(
                  key: const Key('profile-reminders-action'),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/reminders'),
                  icon: const Icon(Icons.notifications_none),
                  label: Text(l10n.remindersTitle),
                ),
              OutlinedButton.icon(
                key: const Key('profile-legal-action'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/legal-about'),
                icon: const Icon(Icons.article_outlined),
                label: Text(l10n.legal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileLifestyleMoment(settings: settings),
          const SizedBox(height: 16),
          HydrionSurface(
            key: const Key('profile-identity-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hydrationIdentity,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                _ProfileStat(
                  icon: Icons.flag_outlined,
                  label: l10n.dailyGoal,
                  value: l10n.volumeMlValue(amount: settings.dailyGoalMl),
                ),
                _ProfileStat(
                  icon: Icons.straighten,
                  label: l10n.units,
                  value: settings.volumeUnit == HydrionVolumeUnit.ounces
                      ? l10n.ounces
                      : l10n.milliliters,
                ),
                _ProfileStat(
                  icon: Icons.local_drink_outlined,
                  label: l10n.preferredContainer,
                  value: settings.usableContainerSizeMl == null
                      ? l10n.notSet
                      : l10n.volumeMlValue(amount: settings.containerSizeMl),
                ),
                _ProfileStat(
                  icon: Icons.notifications_none,
                  label: l10n.remindersTitle,
                  value: reminderRepository.reminders.isEmpty
                      ? l10n.noRemindersYet
                      : l10n.savedCount(
                          count: reminderRepository.reminders.length,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HydrionSurface(
            key: const Key('profile-support-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.support,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.contactEmail(
                    email: HydrionCommunityConfig.contactEmail,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  const _ProfileHero({
    required this.settings,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nickname = settings.nickname?.trim();
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname == null || nickname.isEmpty
                      ? l10n.challengeText('Local Hydrion profile')
                      : nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(_avatarRelationshipLabel(l10n, avatar)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill('${settings.dailyGoalMl} ml/day'),
                    _MiniPill(
                      settings.baselineSource ==
                              HydrionBaselineSource.personalized
                          ? 'Personalized baseline'
                          : 'Standard or manual baseline',
                    ),
                    _MiniPill(
                      settings.weatherModifierEnabled
                          ? 'Weather assistance selected'
                          : 'Weather assistance off',
                    ),
                  ],
                ),
              ],
            ),
          );
          final compact = constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ProfileImage(
                      settings: settings,
                      avatar: avatar,
                      size: 80,
                    ),
                    const _ProfileMenu(embedded: true),
                  ],
                ),
                const SizedBox(height: 14),
                details,
              ],
            );
          }
          return Row(
            children: [
              _ProfileImage(settings: settings, avatar: avatar, size: 96),
              const SizedBox(width: 16),
              Expanded(child: details),
              const _ProfileMenu(embedded: true),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileLifestyleMoment extends StatelessWidget {
  final UserSettings settings;

  const _ProfileLifestyleMoment({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scene = HydrionLifestyleArtResolver.sceneFor(
      surface: HydrionLifestyleSurface.profile,
      sex: settings.sex,
    );
    return HydrionSurface(
      key: const Key('profile-lifestyle-moment'),
      gradient: LinearGradient(
        colors: [
          HydrionColors.foam,
          HydrionColors.glow.withValues(alpha: 0.12),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = SizedBox(
            width: 104,
            height: 132,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HydrionRadii.sm),
              child: Image.asset(
                scene.assetPath,
                key: const Key('profile-lifestyle-art'),
                width: 104,
                height: 132,
                fit: BoxFit.contain,
                cacheWidth: 256,
                semanticLabel:
                    AppLocalizations.of(context).sceneDescription(scene),
              ),
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.challengeText('Built around your routine'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.challengeText(
                  'Your photo, avatar, goals, reminders, and challenge state stay local to this device.',
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.4) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: image),
                const SizedBox(height: 12),
                copy,
              ],
            );
          }
          return Row(
            children: [
              image,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
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
            semanticLabel: AppLocalizations.of(context).localProfilePhoto,
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
  late final TextEditingController _containerController;
  late final TextEditingController _goalController;
  late HydrionVolumeUnit _unit;
  late HydrionBaselineSource _baselineSource;
  late String _avatarId;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _nicknameController = TextEditingController(text: settings.nickname ?? '');
    _containerController =
        TextEditingController(text: settings.containerSizeMl.toString());
    _goalController =
        TextEditingController(text: settings.dailyGoalMl.toString());
    _unit = settings.volumeUnit;
    _baselineSource = settings.baselineSource;
    _avatarId = settings.avatarId;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _containerController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final repository = context.read<UserSettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final goal = int.tryParse(_goalController.text.trim());
    final container = int.tryParse(_containerController.text.trim());

    final profileSaved = await repository.setProfile(
      nickname: _nicknameController.text,
      age: repository.settings.age,
      sex: repository.settings.sex,
    );
    if (!profileSaved || goal == null || container == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.editProfileInvalid)),
      );
      return;
    }
    await repository.setAvatarId(_avatarId);
    await repository.setVolumeUnit(_unit);
    await repository.setPersonalizedGoalOptions(
      baselineSource: _baselineSource,
      weatherModifierEnabled: repository.settings.weatherModifierEnabled,
    );
    await repository.setDailyGoalMl(goal);
    await repository.setContainerSizeMl(container);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
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
          saved ? l10n.profilePhotoSaved : l10n.profilePhotoTooLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<UserSettingsRepository>().settings;
    final avatar = HydrionAvatarManifest.byId(settings.avatarId);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: ListView(
        key: const Key('profile-editor-list'),
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.editProfile,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: l10n.cancel,
              ),
            ],
          ),
          Text(l10n.profileEditorSummary),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProfileImage(settings: settings, avatar: avatar, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profilePhotoPrivacy),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('profile-pick-photo'),
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.choosePhoto),
                        ),
                        OutlinedButton.icon(
                          key: const Key('profile-remove-photo'),
                          onPressed: settings.profilePhotoBase64 == null
                              ? null
                              : () => context
                                  .read<UserSettingsRepository>()
                                  .clearProfilePhoto(),
                          icon: const Icon(Icons.person_outline),
                          label: Text(l10n.useDefaultAvatar),
                        ),
                      ],
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
            decoration: InputDecoration(
              labelText: l10n.displayName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _avatarId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.defaultProfileAvatar,
              border: const OutlineInputBorder(),
            ),
            items: HydrionAvatarManifest.avatars
                .map(
                  (avatar) => DropdownMenuItem(
                    value: avatar.id,
                    child: Text(
                      avatar.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          HydrionHorizontalControl(
            child: SegmentedButton<HydrionVolumeUnit>(
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
              onSelectionChanged: (value) =>
                  setState(() => _unit = value.single),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.baselineDailyGoalMl,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _containerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.preferredContainerMl,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          HydrionHorizontalControl(
            child: SegmentedButton<HydrionBaselineSource>(
              selected: {_baselineSource},
              segments: [
                ButtonSegment(
                  value: HydrionBaselineSource.manual,
                  label: Text(l10n.standardOrManual),
                ),
                ButtonSegment(
                  value: HydrionBaselineSource.personalized,
                  label: Text(l10n.personalized),
                ),
              ],
              onSelectionChanged: (value) =>
                  setState(() => _baselineSource = value.single),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('profile-save'),
            onPressed: _save,
            child: Text(l10n.saveProfile),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = HydrionViewport.stackActions(
          context,
          availableWidth: constraints.maxWidth,
          widthBreakpoint: 340,
        );
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
          subtitle: stacked
              ? Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge,
                )
              : null,
          trailing: stacked
              ? null
              : Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
        );
      },
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
      tooltip: AppLocalizations.of(context).profileMenu,
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
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context);
        return [
          PopupMenuItem(value: 'profile', child: Text(l10n.viewProfile)),
          PopupMenuItem(value: 'settings', child: Text(l10n.settingsTitle)),
          PopupMenuItem(value: 'support', child: Text(l10n.support)),
        ];
      },
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

String _avatarRelationshipLabel(
  AppLocalizations l10n,
  HydrionAvatar avatar,
) {
  final name = avatar.displayName;
  return l10n.sharedAvatarRelationship(name);
}
