import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../repositories/settings_repository.dart';
import 'legal_about_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _goalController = TextEditingController(
    text: UserSettings.defaultDailyGoalMl.toString(),
  );
  final _containerController = TextEditingController(
    text: UserSettings.defaultContainerSizeMl.toString(),
  );
  int _step = 0;
  String _avatarId = HydrionAvatarManifest.avatars.first.id;
  HydrionSex? _sex;
  HydrionGoalMode _goalMode = HydrionGoalMode.manual;
  HydrionVolumeUnit _unit = HydrionVolumeUnit.milliliters;
  bool _reusable = false;
  bool _termsAccepted = false;
  bool _healthAcknowledged = false;
  bool _legalReviewReady = false;
  int _legalValidationAttempt = 0;
  bool _initializedFromSettings = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromSettings) {
      return;
    }
    final settings = context.read<UserSettingsRepository>().settings;
    _nicknameController.text = settings.nickname ?? _nicknameController.text;
    _ageController.text = settings.age?.toString() ?? _ageController.text;
    _goalController.text = settings.dailyGoalMl.toString();
    _containerController.text = settings.containerSizeMl.toString();
    _avatarId = settings.avatarId;
    _sex = settings.sex;
    _goalMode = settings.goalMode;
    _unit = settings.volumeUnit;
    _reusable = settings.reusableContainerEnabled;
    _step = settings.onboardingCompleted ? 0 : settings.onboardingStep;
    _initializedFromSettings = true;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _goalController.dispose();
    _containerController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_step == UserSettings.maxOnboardingStep) {
      await _finish();
      return;
    }
    if (!await _persistCurrentStep(messenger)) {
      return;
    }
    await _goToStep(_step + 1);
  }

  bool _profileIsValid() {
    final nickname = _nicknameController.text.trim();
    return nickname.isNotEmpty &&
        nickname.length <= UserSettings.maxNicknameLength;
  }

  Future<void> _goToStep(int step) async {
    final nextStep = step.clamp(0, UserSettings.maxOnboardingStep).toInt();
    await context.read<UserSettingsRepository>().setOnboardingStep(nextStep);
    if (!mounted) {
      return;
    }
    setState(() => _step = nextStep);
  }

  Future<bool> _persistCurrentStep(ScaffoldMessengerState messenger) async {
    final repository = context.read<UserSettingsRepository>();
    switch (_step) {
      case 0:
        return true;
      case 1:
        if (!_profileIsValid()) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Enter a nickname up to 32 characters.'),
            ),
          );
          return false;
        }
        return repository.setProfile(
          nickname: _nicknameController.text,
          age: _parsedAge(),
          sex: _sex,
        );
      case 2:
        return repository.setAvatarId(_avatarId);
      case 3:
        await repository.setGoalMode(_goalMode);
        return true;
      case 4:
        return _saveHydrationSetup(repository, messenger);
      case 5:
        return true;
      case 6:
        if (!_legalReviewReady) {
          setState(() => _legalValidationAttempt += 1);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Accept the Terms and acknowledge the health disclaimer to continue.',
              ),
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  int? _parsedAge() {
    final ageText = _ageController.text.trim();
    return ageText.isEmpty ? null : int.tryParse(ageText);
  }

  Future<bool> _saveHydrationSetup(
    UserSettingsRepository repository,
    ScaffoldMessengerState messenger,
  ) async {
    final goal = int.tryParse(_goalController.text.trim());
    final container = int.tryParse(_containerController.text.trim());
    if (goal == null ||
        goal < UserSettings.minDailyGoalMl ||
        goal > UserSettings.maxDailyGoalMl ||
        container == null ||
        container < UserSettings.minContainerSizeMl ||
        container > UserSettings.maxContainerSizeMl) {
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Check your goal and container size before continuing.'),
        ),
      );
      return false;
    }
    await repository.setVolumeUnit(_unit);
    await repository.setDailyGoalMl(goal);
    await repository.setContainerSizeMl(container);
    await repository.setReusableContainerEnabled(_reusable);
    return true;
  }

  Future<void> _finish() async {
    final repository = context.read<UserSettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    if (!_profileIsValid()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a nickname up to 32 characters.')),
      );
      await _goToStep(1);
      return;
    }
    if (!await _saveHydrationSetup(repository, messenger)) {
      await _goToStep(4);
      return;
    }

    await repository.setProfile(
      nickname: _nicknameController.text,
      age: _parsedAge(),
      sex: _sex,
    );
    await repository.setAvatarId(_avatarId);
    await repository.setGoalMode(_goalMode);
    await repository.completeOnboardingWithLegalReview(
        reviewedAt: DateTime.now());
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps(context);
    final canGoBack = _step > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Hydrion'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              key: const Key('onboarding-progress'),
              value: (_step + 1) / steps.length,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  steps[_step],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          canGoBack ? () => setState(() => _step -= 1) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('onboarding-next'),
                      onPressed: _next,
                      icon:
                          Icon(_step == 7 ? Icons.check : Icons.arrow_forward),
                      label: Text(_step == 7 ? 'Start' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _steps(BuildContext context) {
    return [
      _OnboardingPanel(
        icon: Icons.water_drop_outlined,
        title: 'Hydrion keeps hydration local-first',
        child: Column(
          children: [
            Image.asset(
              HydrionAvatarManifest.mascotAssetPath,
              key: const Key('onboarding-mascot'),
              height: 180,
              semanticLabel: 'Hydrion mascot',
            ),
            const SizedBox(height: 12),
            const Text(
              'Track water, goals, reminders, and solo challenges on this device. Optional provider features stay off until you choose them.',
            ),
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.person_outline,
        title: 'Basic profile',
        child: Column(
          children: [
            TextField(
              key: const Key('onboarding-nickname'),
              controller: _nicknameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nickname',
                helperText: 'Required, saved locally.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding-age'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Age',
                helperText:
                    'Optional for manual goals; required for weather mode.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HydrionSex>(
              key: const Key('onboarding-sex'),
              initialValue: _sex,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Sex option',
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
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.face_outlined,
        title: 'Choose your default avatar',
        child: _AvatarSelectionGrid(
          selectedAvatarId: _avatarId,
          onSelected: (avatarId) => setState(() => _avatarId = avatarId),
        ),
      ),
      _OnboardingPanel(
        icon: Icons.flag_outlined,
        title: 'Goal mode',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<HydrionGoalMode>(
              key: const Key('goal-mode-selector'),
              segments: const [
                ButtonSegment(
                  value: HydrionGoalMode.manual,
                  icon: Icon(Icons.tune),
                  label: Text('Manual'),
                ),
                ButtonSegment(
                  value: HydrionGoalMode.weatherInformed,
                  icon: Icon(Icons.wb_sunny_outlined),
                  label: Text('Weather'),
                ),
              ],
              selected: {_goalMode},
              onSelectionChanged: (selection) {
                setState(() => _goalMode = selection.single);
              },
            ),
            const SizedBox(height: 12),
            Text(
              _goalMode == HydrionGoalMode.manual
                  ? 'You choose the daily target.'
                  : 'Requires age, an explicit sex option, location permission for live lookup, and a configured forecast provider. Notification permission is separate for reminders. Hydrion uses a bounded formula, not medical advice.',
            ),
            if (_goalMode == HydrionGoalMode.weatherInformed) ...[
              const SizedBox(height: 8),
              const Text(
                'Hydrion will ask for location access after setup, then show a daily weather-based suggestion for you to accept or keep your standard goal.',
              ),
            ],
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.local_drink_outlined,
        title: 'Hydration setup',
        child: Column(
          children: [
            TextField(
              key: const Key('onboarding-goal'),
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Daily goal in ml',
                helperText: 'Supported range: 500-5000 ml.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HydrionVolumeUnit>(
              initialValue: _unit,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Display unit',
              ),
              items: const [
                DropdownMenuItem(
                  value: HydrionVolumeUnit.milliliters,
                  child: Text('Milliliters'),
                ),
                DropdownMenuItem(
                  value: HydrionVolumeUnit.ounces,
                  child: Text('Ounces'),
                ),
              ],
              onChanged: (value) => setState(() => _unit = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding-container'),
              controller: _containerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Usual container size in ml',
                helperText: 'Supported range: 100-2000 ml.',
              ),
            ),
            SwitchListTile.adaptive(
              value: _reusable,
              onChanged: (value) => setState(() => _reusable = value),
              title: const Text('Usually reusable'),
              subtitle: const Text(
                'Only enable this if most logged drinks use a reusable bottle or cup.',
              ),
            ),
          ],
        ),
      ),
      const _OnboardingPanel(
        icon: Icons.notifications_none,
        title: 'Reminder setup',
        child: Text(
          'This build stores reminder definitions locally. OS notification delivery is unavailable until a native notification adapter is connected, permission UX is added, and scheduling is verified.',
        ),
      ),
      _OnboardingPanel(
        icon: Icons.health_and_safety_outlined,
        title: 'Review before you start',
        child: LegalAcceptancePanel(
          termsAccepted: _termsAccepted,
          healthAcknowledged: _healthAcknowledged,
          validationAttempt: _legalValidationAttempt,
          onTermsChanged: (value) {
            setState(() => _termsAccepted = value);
          },
          onHealthChanged: (value) {
            setState(() => _healthAcknowledged = value);
          },
          onReviewReadinessChanged: (value) {
            if (_legalReviewReady != value) {
              setState(() => _legalReviewReady = value);
            }
          },
        ),
      ),
      _OnboardingPanel(
        icon: Icons.check_circle_outline,
        title: 'Ready',
        child: Column(
          children: [
            Image.asset(
              HydrionUiAssetManifest.successCheckAssetPath,
              key: const Key('onboarding-success-image'),
              height: 112,
              fit: BoxFit.contain,
              semanticLabel: 'Onboarding ready',
            ),
            const SizedBox(height: 12),
            Text(
              'Hydrion will start with ${_nicknameController.text.trim().isEmpty ? 'your profile' : _nicknameController.text.trim()}, ${HydrionAvatarManifest.byId(_avatarId).displayName}, ${_goalController.text.trim()} ml/day, and local-first tracking.',
            ),
          ],
        ),
      ),
    ];
  }

  String _sexLabel(HydrionSex sex) {
    return switch (sex) {
      HydrionSex.female => 'Female',
      HydrionSex.male => 'Male',
      HydrionSex.intersex => 'Intersex',
      HydrionSex.preferNotToSay => 'Prefer not to say',
    };
  }
}

class _AvatarSelectionGrid extends StatelessWidget {
  final String selectedAvatarId;
  final ValueChanged<String> onSelected;

  const _AvatarSelectionGrid({
    required this.selectedAvatarId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620
            ? 4
            : constraints.maxWidth >= 440
                ? 3
                : 2;
        return GridView.builder(
          key: const Key('onboarding-avatar-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: HydrionAvatarManifest.avatars.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final avatar = HydrionAvatarManifest.avatars[index];
            return _AvatarChoiceTile(
              avatar: avatar,
              selected: avatar.id == selectedAvatarId,
              onTap: () => onSelected(avatar.id),
            );
          },
        );
      },
    );
  }
}

class _AvatarChoiceTile extends StatelessWidget {
  final HydrionAvatar avatar;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarChoiceTile({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '${avatar.displayName} avatar selected'
          : 'Select ${avatar.displayName} avatar',
      child: InkWell(
        key: Key('avatar-${avatar.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: selected ? 3 : 1,
              color: selected ? scheme.primary : Theme.of(context).dividerColor,
            ),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.24)
                : scheme.surface.withValues(alpha: 0.76),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: Image.asset(
                                avatar.assetPath,
                                semanticLabel: avatar.displayName,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avatar.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _OnboardingPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 36),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
