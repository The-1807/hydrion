import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../repositories/settings_repository.dart';

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
  bool _legalAccepted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _legalAccepted = settings.legalAndHealthAcknowledged;
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
    if (_step == 1 && !_profileIsValid()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a nickname up to 32 characters.')),
      );
      return;
    }
    if (_step == 6 && !_legalAccepted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Accept the legal and health acknowledgement.'),
        ),
      );
      return;
    }
    if (_step < 7) {
      setState(() => _step += 1);
      return;
    }
    await _finish();
  }

  bool _profileIsValid() {
    final nickname = _nicknameController.text.trim();
    return nickname.isNotEmpty &&
        nickname.length <= UserSettings.maxNicknameLength;
  }

  Future<void> _finish() async {
    final repository = context.read<UserSettingsRepository>();
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final goal = int.tryParse(_goalController.text.trim());
    final container = int.tryParse(_containerController.text.trim());

    if (goal == null ||
        goal < UserSettings.minDailyGoalMl ||
        goal > UserSettings.maxDailyGoalMl ||
        container == null ||
        container < UserSettings.minContainerSizeMl ||
        container > UserSettings.maxContainerSizeMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Check your goal and container size before continuing.'),
        ),
      );
      return;
    }

    await repository.setProfile(
      nickname: _nicknameController.text,
      age: age,
      sex: _sex,
    );
    await repository.setAvatarId(_avatarId);
    await repository.setGoalMode(_goalMode);
    await repository.setVolumeUnit(_unit);
    await repository.setDailyGoalMl(goal);
    await repository.setContainerSizeMl(container);
    await repository.setReusableContainerEnabled(_reusable);
    await repository.setOnboardingCompleted(
      completed: true,
      legalAndHealthAcknowledged: _legalAccepted,
    );
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
        title: 'Choose your shark',
        child: GridView.builder(
          key: const Key('onboarding-avatar-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: HydrionAvatarManifest.avatars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final avatar = HydrionAvatarManifest.avatars[index];
            final selected = avatar.id == _avatarId;
            return InkWell(
              key: Key('avatar-${avatar.id}'),
              onTap: () => setState(() => _avatarId = avatar.id),
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: selected ? 3 : 1,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          avatar.assetPath,
                          semanticLabel: avatar.displayName,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text(
                        avatar.displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        avatar.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                  : 'Requires age, an explicit sex option, location permission, notification permission, and a configured forecast provider. Hydrion uses a bounded formula, not medical advice.',
            ),
            if (_goalMode == HydrionGoalMode.weatherInformed) ...[
              const SizedBox(height: 8),
              const Text(
                'No forecast provider is configured in this build, so manual goals remain the reliable default until eligibility is complete.',
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
        title: 'Legal and health acknowledgement',
        child: CheckboxListTile(
          key: const Key('onboarding-legal-ack'),
          value: _legalAccepted,
          onChanged: (value) => setState(() => _legalAccepted = value == true),
          title: const Text(
            'I understand Hydrion is not medical advice and hydration needs vary.',
          ),
          subtitle: const Text(
            'Review Terms, Privacy, and Health/Safety in Settings. Stop or adjust if you feel unwell.',
          ),
        ),
      ),
      _OnboardingPanel(
        icon: Icons.check_circle_outline,
        title: 'Ready',
        child: Text(
          'Hydrion will start with ${_nicknameController.text.trim().isEmpty ? 'your profile' : _nicknameController.text.trim()}, ${HydrionAvatarManifest.byId(_avatarId).displayName}, ${_goalController.text.trim()} ml/day, and local-first tracking.',
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
