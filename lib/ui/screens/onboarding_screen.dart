import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/life_stage_policy.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/permission_localizations.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/permissions.dart';
import '../components/hydrion_viewport.dart';
import '../components/recognition_moment.dart';
import 'body_metrics_screen.dart';
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
  HydrionBaselineSource _baselineSource = HydrionBaselineSource.manual;
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
    _baselineSource = settings.baselineSource;
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

  bool _ageIsValid() {
    return HydrionLifeStagePolicy.canCreateIndependentProfile(_parsedAge());
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
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 0:
        return true;
      case 1:
        if (!_profileIsValid()) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.onboardingNicknameInvalid)),
          );
          return false;
        }
        if (!_ageIsValid()) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.onboardingAgeInvalid)),
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
        await repository.setPersonalizedGoalOptions(
          baselineSource: _baselineSource,
          weatherModifierEnabled: repository.settings.weatherModifierEnabled,
        );
        return true;
      case 4:
        return _saveHydrationSetup(repository, messenger);
      case 5:
        return true;
      case 6:
        if (!_legalReviewReady) {
          setState(() => _legalValidationAttempt += 1);
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.onboardingTermsRequired)),
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
    final l10n = AppLocalizations.of(context);
    final goal = int.tryParse(_goalController.text.trim());
    final container = int.tryParse(_containerController.text.trim());
    if (goal == null ||
        goal < UserSettings.minDailyGoalMl ||
        goal > UserSettings.maxDailyGoalMl ||
        container == null ||
        container < UserSettings.minContainerSizeMl ||
        container > UserSettings.maxContainerSizeMl) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.onboardingGoalInvalid)),
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
    final l10n = AppLocalizations.of(context);
    if (!_profileIsValid()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.onboardingNicknameInvalid)),
      );
      await _goToStep(1);
      return;
    }
    if (!_ageIsValid()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.onboardingAgeInvalid)),
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
    await repository.setPersonalizedGoalOptions(
      baselineSource: _baselineSource,
      weatherModifierEnabled: repository.settings.weatherModifierEnabled,
    );
    await repository.completeOnboardingWithLegalReview(
        reviewedAt: DateTime.now());
    if (!mounted) {
      return;
    }
    await RecognitionMoment.showOnce(
      context,
      repository: repository,
      eventId: 'onboarding-complete',
      message: l10n.onboardingCompleteRecognition,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/mission');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(context);
    final canGoBack = _step > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingWelcome),
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
                key: const Key('onboarding-step-scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: HydrionViewport.scrollPadding(
                  context,
                  top: 20,
                  bottom: 20,
                  includeSystemBottom: false,
                ),
                children: [
                  steps[_step],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                HydrionViewport.horizontalPadding(context),
                8,
                HydrionViewport.horizontalPadding(context),
                12,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final back = OutlinedButton.icon(
                    onPressed:
                        canGoBack ? () => setState(() => _step -= 1) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.back),
                  );
                  final next = FilledButton.icon(
                    key: const Key('onboarding-next'),
                    onPressed: _next,
                    icon: Icon(_step == 7 ? Icons.check : Icons.arrow_forward),
                    label: Text(
                      _step == 7 ? l10n.start : l10n.continueAction,
                    ),
                  );
                  if (HydrionViewport.stackActions(
                    context,
                    availableWidth: constraints.maxWidth,
                    widthBreakpoint: 330,
                    textScaleBreakpoint: 1.75,
                  )) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        next,
                        const SizedBox(height: 8),
                        back,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: back),
                      const SizedBox(width: 12),
                      Expanded(child: next),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _steps(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _OnboardingPanel(
        icon: Icons.water_drop_outlined,
        title: l10n.onboardingLocalFirstTitle,
        child: Column(
          children: [
            Image.asset(
              HydrionAvatarManifest.mascotAssetPath,
              key: const Key('onboarding-mascot'),
              height: 180,
              semanticLabel: l10n.onboardingMascotSemantics,
            ),
            const SizedBox(height: 12),
            Text(l10n.onboardingLocalFirstBody),
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.person_outline,
        title: l10n.onboardingBasicProfile,
        child: Column(
          children: [
            TextField(
              key: const Key('onboarding-nickname'),
              controller: _nicknameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.nickname,
                helperText: l10n.requiredSavedLocally,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding-age'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.age,
                helperText: l10n.ageOptionalHelp,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HydrionSex>(
              key: const Key('onboarding-sex'),
              initialValue: _sex,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.sexGuidanceLabel,
                helperText: l10n.sexOptionalHelp,
              ),
              items: HydrionSex.values
                  .map(
                    (sex) => DropdownMenuItem(
                      value: sex,
                      child: Text(_sexLabel(l10n, sex)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _sex = value),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('onboarding-optional-body-metrics'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monitor_weight_outlined),
              title: Text(AppLocalizations.of(context).bodyMetricsTitle),
              subtitle: Text(AppLocalizations.of(context).bodyMetricsOptional),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (!_profileIsValid() || !_ageIsValid()) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.onboardingProfileNeededForMetrics),
                    ),
                  );
                  return;
                }
                final saved =
                    await context.read<UserSettingsRepository>().setProfile(
                          nickname: _nicknameController.text,
                          age: _parsedAge(),
                          sex: _sex,
                        );
                if (saved && context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BodyMetricsScreen(
                        returnToOnboardingAfterApply: true,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.face_outlined,
        title: l10n.chooseDefaultAvatar,
        child: _AvatarSelectionGrid(
          selectedAvatarId: _avatarId,
          onSelected: (avatarId) => setState(() => _avatarId = avatarId),
        ),
      ),
      _OnboardingPanel(
        icon: Icons.flag_outlined,
        title: l10n.goalMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HydrionHorizontalControl(
              child: SegmentedButton<HydrionBaselineSource>(
                key: const Key('goal-mode-selector'),
                segments: [
                  ButtonSegment(
                    value: HydrionBaselineSource.manual,
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.standardOrManual),
                  ),
                  ButtonSegment(
                    value: HydrionBaselineSource.personalized,
                    icon: const Icon(Icons.person_outline),
                    label: Text(l10n.personalizedEstimate),
                  ),
                ],
                selected: {_baselineSource},
                onSelectionChanged: (selection) {
                  setState(() => _baselineSource = selection.single);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _baselineSource == HydrionBaselineSource.manual
                  ? l10n.standardGoalModeHelp
                  : l10n.personalizedGoalModeHelp,
            ),
            const SizedBox(height: 8),
            Text(l10n.weatherBaselineHelp),
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.local_drink_outlined,
        title: l10n.hydrationSetup,
        child: Column(
          children: [
            TextField(
              key: const Key('onboarding-goal'),
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.dailyGoalMlLabel,
                helperText: l10n.dailyGoalSupportedRange,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HydrionVolumeUnit>(
              initialValue: _unit,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.displayUnit,
              ),
              items: [
                DropdownMenuItem(
                  value: HydrionVolumeUnit.milliliters,
                  child: Text(l10n.milliliters),
                ),
                DropdownMenuItem(
                  value: HydrionVolumeUnit.ounces,
                  child: Text(l10n.ounces),
                ),
              ],
              onChanged: (value) => setState(() => _unit = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding-container'),
              controller: _containerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.containerSizeMlLabel,
                helperText: l10n.containerSupportedRange,
              ),
            ),
            SwitchListTile.adaptive(
              value: _reusable,
              onChanged: (value) => setState(() => _reusable = value),
              title: Text(l10n.usuallyReusable),
              subtitle: Text(l10n.reusableHelp),
            ),
          ],
        ),
      ),
      _OnboardingPanel(
        icon: Icons.notifications_none,
        title: l10n.optionalDeviceFeatures,
        child: const _OnboardingPermissionChoices(),
      ),
      _OnboardingPanel(
        icon: Icons.health_and_safety_outlined,
        title: l10n.reviewBeforeStart,
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
        title: l10n.ready,
        child: Column(
          children: [
            Image.asset(
              HydrionUiAssetManifest.successCheckAssetPath,
              key: const Key('onboarding-success-image'),
              height: 112,
              fit: BoxFit.contain,
              semanticLabel: l10n.onboardingReadySemantics,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingSummary(
                name: _nicknameController.text.trim().isEmpty
                    ? l10n.yourProfile
                    : _nicknameController.text.trim(),
                avatar: HydrionAvatarManifest.byId(_avatarId).displayName,
                goal: _goalController.text.trim(),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  String _sexLabel(AppLocalizations l10n, HydrionSex sex) {
    return switch (sex) {
      HydrionSex.female => l10n.sexFemale,
      HydrionSex.male => l10n.sexMale,
      HydrionSex.intersex => l10n.sexIntersex,
      HydrionSex.preferNotToSay => l10n.preferNotToSay,
    };
  }
}

class _OnboardingPermissionChoices extends StatefulWidget {
  const _OnboardingPermissionChoices();

  @override
  State<_OnboardingPermissionChoices> createState() =>
      _OnboardingPermissionChoicesState();
}

class _OnboardingPermissionChoicesState
    extends State<_OnboardingPermissionChoices> {
  bool _remindersSkipped = false;
  bool _weatherSkipped = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = context.watch<Permissions>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CapabilityChoice(
          key: const Key('onboarding-reminder-capability'),
          icon: Icons.notifications_active_outlined,
          title: l10n.hydrationReminders,
          description: l10n.remindersCapabilityHelp,
          enabled: permissions.snapshot.notifications.isGranted,
          status: _remindersSkipped
              ? l10n.remindersNotNowHelp
              : l10n.permissionMessage(
                  permissions.snapshot.notifications.message,
                ),
          enableLabel: l10n.enableReminders,
          notNowKey: const Key('onboarding-reminders-not-now'),
          enableKey: const Key('onboarding-enable-reminders'),
          onEnable: () async {
            await permissions.requestNotifications();
            if (mounted) setState(() => _remindersSkipped = false);
          },
          onNotNow: () async {
            setState(() => _remindersSkipped = true);
          },
        ),
        const SizedBox(height: 12),
        _CapabilityChoice(
          key: const Key('onboarding-weather-capability'),
          icon: Icons.cloud_outlined,
          title: l10n.weatherAssistance,
          description: l10n.weatherCapabilityHelp,
          enabled: permissions.snapshot.location.isGranted,
          status: _weatherSkipped
              ? l10n.weatherNotNowHelp
              : l10n.permissionMessage(permissions.snapshot.location.message),
          enableLabel: l10n.enableWeatherAssistance,
          notNowKey: const Key('onboarding-weather-not-now'),
          enableKey: const Key('onboarding-enable-weather'),
          onEnable: () async {
            await permissions.requestLocation();
            if (!context.mounted) return;
            if (permissions.snapshot.location.isGranted) {
              final repository = context.read<UserSettingsRepository>();
              await repository.setPersonalizedGoalOptions(
                baselineSource: repository.settings.baselineSource,
                weatherModifierEnabled: true,
              );
            }
            setState(() => _weatherSkipped = false);
          },
          onNotNow: () async {
            final repository = context.read<UserSettingsRepository>();
            await repository.setPersonalizedGoalOptions(
              baselineSource: repository.settings.baselineSource,
              weatherModifierEnabled: false,
            );
            if (mounted) setState(() => _weatherSkipped = true);
          },
        ),
      ],
    );
  }
}

class _CapabilityChoice extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final bool enabled;
  final String enableLabel;
  final Key enableKey;
  final Key notNowKey;
  final Future<void> Function() onEnable;
  final Future<void> Function() onNotNow;

  const _CapabilityChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.enabled,
    required this.enableLabel,
    required this.enableKey,
    required this.notNowKey,
    required this.onEnable,
    required this.onNotNow,
  });

  @override
  State<_CapabilityChoice> createState() => _CapabilityChoiceState();
}

class _CapabilityChoiceState extends State<_CapabilityChoice> {
  bool _requesting = false;

  Future<void> _enable() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await widget.onEnable();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.description),
            const SizedBox(height: 6),
            Text(
              _requesting
                  ? l10n.waitingForDevice
                  : widget.enabled
                      ? l10n.enabled
                      : widget.status,
              semanticsLabel: widget.enabled
                  ? l10n.capabilityEnabled(title: widget.title)
                  : l10n.capabilityStatus(
                      title: widget.title,
                      status: widget.status,
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (widget.enabled)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    semanticLabel: l10n.enabled,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.enabled),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: widget.enableKey,
                    onPressed: _requesting ? null : _enable,
                    child: _requesting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.enableLabel),
                  ),
                  TextButton(
                    key: widget.notNowKey,
                    onPressed: _requesting
                        ? null
                        : () async {
                            await widget.onNotNow();
                          },
                    child: Text(l10n.notNow),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? l10n.avatarSelectedSemantics(avatar: avatar.displayName)
          : l10n.selectAvatarSemantics(avatar: avatar.displayName),
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
