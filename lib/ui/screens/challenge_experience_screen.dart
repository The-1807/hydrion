import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_experience.dart';
import '../../domain/bottle_bingo.dart';
import '../../domain/challenge_visual_registry.dart';
import '../../domain/hydration_contracts.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/app_refresh_controller.dart';
import '../../services/weather_goal_service.dart';
import '../../services/notifications.dart';
import '../components/intake_ring.dart';
import '../presentation/challenge_history_presenter.dart';
import '../theme/hydrion_design.dart';

class ChallengeExperienceScreen extends StatefulWidget {
  final HydrationChallenge challenge;

  const ChallengeExperienceScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeExperienceScreen> createState() =>
      _ChallengeExperienceScreenState();
}

class _ChallengeExperienceScreenState extends State<ChallengeExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  ChallengeExperienceDefinition get definition =>
      HydrionChallengeExperiences.byId(widget.challenge.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.read<ChallengeRepository>().activeChallenge;
    final unit = context.read<UserSettingsRepository>().settings.volumeUnit;
    for (final key in definition.requiredParameters) {
      final storedValue =
          active?.id == widget.challenge.id ? active?.parameters[key] : null;
      _controllers.putIfAbsent(
        key,
        () => TextEditingController(
          text: key == 'amountMl' && storedValue is num
              ? HydrationVolumeFormatter.fromMilliliters(storedValue, unit)
                  .toStringAsFixed(unit == HydrionVolumeUnit.ounces ? 1 : 0)
              : storedValue?.toString() ?? _defaultParameterValue(key, unit),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeRepository = context.watch<ChallengeRepository>();
    final active = challengeRepository.activeChallenge;
    final isActive = active?.id == widget.challenge.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.name),
        actions: [
          if (isActive)
            TextButton(
              onPressed: () => _leaveChallenge(context, active!),
              child: const Text('Leave'),
            ),
        ],
      ),
      body: RefreshIndicator(
        key: Key('challenge-dashboard-refresh-${widget.challenge.id}'),
        onRefresh: () => refreshHydrionData(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: active != null && isActive && !active.needsSetup
              ? _dashboard(context, active)
              : _previewAndSetup(context),
        ),
      ),
    );
  }

  List<Widget> _previewAndSetup(BuildContext context) {
    final active = context.watch<ChallengeRepository>().activeChallenge;
    final completingSetup = active?.id == widget.challenge.id;
    final otherActive = active != null && !completingSetup;
    final settings = context.read<UserSettingsRepository>().settings;
    return [
      _ChallengeImageHero(
        challengeName: widget.challenge.name,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
        sex: settings.sex,
      ),
      _Section(title: 'What this challenge is', body: definition.purpose),
      _Section(
        title: 'What you will do',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < definition.actions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. ${definition.actions[i]}'),
              ),
          ],
        ),
      ),
      _Section(title: 'What counts', body: definition.whatCounts),
      _Section(title: 'What does not count', body: definition.whatDoesNotCount),
      _Section(
        title: 'Duration',
        body:
            '${widget.challenge.durationDays} local calendar days. The challenge starts when joined. Daily requirements reset at local midnight; missed days are not silently recovered.',
      ),
      if (definition.schedule.isNotEmpty)
        _Section(
          title: 'Complete schedule',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < definition.schedule.length; i++)
                Text('Day ${i + 1}: ${definition.schedule[i]}'),
            ],
          ),
        ),
      const _Section(
        title: 'Hydration relationship',
        body:
            'Your normal hydration goal remains active. Water logged here also appears on Home, History, Progress, and Analytics. Only drinks that match the challenge task complete it. Check-ins add no water.',
      ),
      const _Section(
        title: 'Privacy and persistence',
        body: 'Challenge configuration and progress remain on this device.',
      ),
      HydrionSurface(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Required setup',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final key in definition.requiredParameters) ...[
                _ChallengeParameterField(
                  parameterKey: key,
                  controller: _controllers[key]!,
                  unit: context
                      .read<UserSettingsRepository>()
                      .settings
                      .volumeUnit,
                  savedContainerMl: context
                      .read<UserSettingsRepository>()
                      .settings
                      .usableContainerSizeMl,
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                key: Key('activate-challenge-${widget.challenge.id}'),
                onPressed: otherActive ? null : () => _activate(context),
                icon: const Icon(Icons.play_arrow),
                label: Text(!otherActive
                    ? completingSetup
                        ? 'Complete setup'
                        : 'Join challenge'
                    : 'Leave current challenge first'),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _dashboard(BuildContext context, JoinedChallenge active) {
    final hydration = context.watch<HydrationRepository>();
    final settings = context.watch<UserSettingsRepository>().settings;
    final repository = context.read<ChallengeRepository>();
    final now = DateTime.now();
    final elapsedDays = now
        .difference(DateTime(
            active.joinedAt.year, active.joinedAt.month, active.joinedAt.day))
        .inDays;
    final day = elapsedDays.clamp(0, active.durationDays - 1);
    final challengeComplete = elapsedDays >= active.durationDays;
    final total = hydration.totalForDay(now);
    final qualified = repository.progressFor(
      hydration,
      targetMlOverride: settings.dailyGoalMl,
    );
    final instruction = _instruction(active, day);
    return [
      _ChallengeImageHero(
        challengeName: widget.challenge.name,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
        sex: settings.sex,
      ),
      _Section(
        title: challengeComplete
            ? 'Completed · ${active.durationDays} days'
            : 'Active · Day ${day + 1} of ${active.durationDays}',
        body: widget.challenge.description,
      ),
      _Section(title: "Today's instruction", body: instruction),
      if (widget.challenge.id == 'temperature-roulette')
        _TemperatureChallengePanel(
          active: active,
          day: day,
          fallbackSchedule: definition.schedule,
        ),
      if (widget.challenge.id == 'around-the-world-infusion-week')
        _InfusionJourneyPanel(
          active: active,
          day: day,
          schedule: definition.schedule,
          unit: settings.volumeUnit,
        ),
      if (widget.challenge.id == 'eat-your-water-day')
        _EatYourWaterPanel(active: active),
      if (widget.challenge.id == 'plant-twin-challenge')
        _PlantCuePanel(active: active),
      if (widget.challenge.id == 'bottle-bingo')
        _LiveBingoBoard(
          active: active,
          repository: repository,
          hydrationRepository: hydration,
          settings: settings,
        ),
      if (widget.challenge.id == 'pomodoro-sip')
        _PomodoroTimerCard(active: active),
      _Section(
        title: "Today's parameters",
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: active.parameters.entries
              .where((entry) =>
                  !entry.key.startsWith('timer') &&
                  entry.key != 'weatherContext' &&
                  entry.key != 'temperatureSchedule')
              .map((entry) => Chip(
                    label: Text(_parameterSummary(
                      entry.key,
                      entry.value,
                      settings.volumeUnit,
                    )),
                  ))
              .toList(),
        ),
      ),
      _ProgressSection(
        title: "Today's total hydration",
        valueMl: total,
        targetMl: settings.dailyGoalMl,
        unit: settings.volumeUnit,
      ),
      _ProgressSection(
        title: 'Challenge-qualified hydration',
        valueMl: qualified.todayMl,
        targetMl: qualified.targetMl,
        unit: settings.volumeUnit,
      ),
      _Section(
        title: 'Challenge progress',
        body:
            '${qualified.completedDays}/${qualified.durationDays} days completed. ${active.completedActionIds.length} challenge actions recorded.',
      ),
      _Section(
        title: 'History',
        child: ChallengeHistoryView(
          items: ChallengeHistoryPresenter.present(
            challenge: active,
            hydrationLogs: hydration.logs,
            unit: settings.volumeUnit,
          ),
        ),
      ),
      HydrionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: Key('challenge-primary-action-${widget.challenge.id}'),
              onPressed: challengeComplete
                  ? null
                  : () => _performPrimaryAction(context, active, day),
              icon: Icon(definition.actionKind == ChallengeActionKind.checkIn
                  ? Icons.check_circle_outline
                  : Icons.water_drop),
              label: Text(_primaryActionLabel(active)),
            ),
          ],
        ),
      ),
      const _Section(
        title: 'Challenge settings',
        body:
            'Leave and rejoin to change structural parameters. This prevents an active rule from changing silently during a day.',
      ),
    ];
  }

  Future<void> _activate(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final settingsRepository = context.read<UserSettingsRepository>();
    final repository = context.read<ChallengeRepository>();
    final weatherCoordinator = context.read<DailyWeatherGoalCoordinator>();
    final notifications = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    final unit = settingsRepository.settings.volumeUnit;
    final parameters = <String, Object?>{};
    for (final entry in _controllers.entries) {
      final raw = entry.value.text.trim();
      parameters[entry.key] = entry.key == 'amountMl'
          ? HydrationVolumeFormatter.toMilliliters(double.parse(raw), unit)
          : _isNumeric(entry.key)
              ? int.parse(raw)
              : raw;
    }
    if (widget.challenge.id == 'pomodoro-sip') {
      final total = (parameters['amountMl'] as int) *
          (parameters['sessionsPerDay'] as int);
      final goal = settingsRepository.settings.dailyGoalMl;
      if (total > goal) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Choose a smaller sip amount or fewer sessions so the plan does not exceed your normal goal.',
            ),
          ),
        );
        return;
      }
      final now = DateTime.now();
      final end =
          now.add(Duration(minutes: parameters['sessionMinutes'] as int));
      parameters['timerStatus'] = 'running';
      parameters['timerStartedAt'] = now.toIso8601String();
      parameters['timerEndsAt'] = end.toIso8601String();
      parameters['timerSession'] = 1;
      if ((parameters['notifications'] as String).toLowerCase() == 'enabled') {
        final scheduled = await notifications.createReminder(
          triggerTime: end,
          message:
              'Focus session complete. Take your planned sip when you’re ready.',
          priority: 1,
          requestPermissionIfNeeded: true,
        );
        parameters['timerReminderId'] = scheduled.reminder?.id;
      }
    }
    if (widget.challenge.id == 'temperature-roulette') {
      final weatherEnabled = parameters['weatherOrdering'] == 'enabled';
      var schedule = List<String>.of(definition.schedule);
      var contextText = 'Today’s standard temperature plan is in use.';
      if (weatherEnabled) {
        final result = await weatherCoordinator.prepareWeatherMode(
          requestLocationPermission: true,
          forceRefresh: false,
        );
        final forecast = result.forecast;
        if (forecast != null) {
          if (forecast.temperatureC >= 24) {
            schedule = const [
              'Cool',
              'Room temperature',
              'Comfortably warm',
              'Cool',
              'Room temperature',
            ];
          } else if (forecast.temperatureC <= 10) {
            schedule = const [
              'Comfortably warm',
              'Room temperature',
              'Cool',
              'Comfortably warm',
              'Room temperature',
            ];
          }
          contextText = '${forecast.condition}, '
              '${forecast.temperatureC.toStringAsFixed(1)}°C'
              '${forecast.humidityPercent == null ? '' : ', ${forecast.humidityPercent!.round()}% humidity'}. '
              'Updated ${forecast.retrievedAt.toLocal()}. Today’s plan favors a comfortable style while keeping the week varied.';
        } else {
          contextText =
              'Weather is unavailable right now, so today’s standard temperature plan is being used.';
        }
      }
      parameters['temperatureSchedule'] = schedule;
      parameters['weatherContext'] = contextText;
    }
    if (widget.challenge.id == 'bottle-bingo') {
      parameters['bingoBoardVersion'] = 2;
    }
    if (repository.activeChallenge?.id == widget.challenge.id) {
      await repository.updateParameters(parameters);
      return;
    }
    await repository.join(
      id: widget.challenge.id,
      name: widget.challenge.name,
      description: widget.challenge.description,
      targetMl: settingsRepository.settings.dailyGoalMl,
      durationDays: widget.challenge.id == 'pomodoro-sip'
          ? parameters['challengeDurationDays'] as int
          : widget.challenge.durationDays,
      parameters: parameters,
    );
  }

  Future<void> _performPrimaryAction(
    BuildContext context,
    JoinedChallenge active,
    int day,
  ) async {
    final repository = context.read<ChallengeRepository>();
    final notifications = context.read<NotificationService>();
    if (widget.challenge.id == 'pomodoro-sip') {
      final endsAt = DateTime.tryParse(
        active.parameters['timerEndsAt']?.toString() ?? '',
      );
      if (endsAt != null && DateTime.now().isBefore(endsAt)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Finish this focus session before logging its sip.')),
        );
        return;
      }
    }
    final sessionSuffix = widget.challenge.id == 'pomodoro-sip'
        ? '-session-${active.completedActionIds.length + 1}'
        : '';
    final now = DateTime.now();
    final localDay = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final key = '$localDay:day-${day + 1}-${widget.challenge.id}$sessionSuffix';
    if (definition.actionKind == ChallengeActionKind.checkIn) {
      await repository.completeCheckIn(key);
      return;
    }
    if (definition.actionKind == ChallengeActionKind.automaticQualification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Log water normally; qualifying records update this challenge automatically.')),
      );
      return;
    }
    final amount = active.parameters['amountMl'];
    if (amount is! int || amount <= 0) return;
    final log = await repository.completeHydrationAction(
      hydrationRepository: context.read<HydrationRepository>(),
      volumeMl: amount,
      actionKey: key,
    );
    if (log != null && widget.challenge.id == 'pomodoro-sip') {
      final session =
          ((active.parameters['timerSession'] as num?) ?? 1).round();
      final planned =
          ((active.parameters['sessionsPerDay'] as num?) ?? 1).round();
      final autoStart =
          active.parameters['autoStartNext']?.toString().toLowerCase() ==
              'enabled';
      if (session < planned) {
        final next = session + 1;
        final minutes =
            ((active.parameters['sessionMinutes'] as num?) ?? 25).round();
        final now = DateTime.now();
        final nextEnd = now.add(Duration(minutes: minutes));
        await repository.updateParameters({
          ...repository.activeChallenge!.parameters,
          'timerSession': next,
          'timerStatus': autoStart ? 'running' : 'stopped',
          'timerStartedAt': autoStart ? now.toIso8601String() : '',
          'timerEndsAt': autoStart ? nextEnd.toIso8601String() : '',
          'timerReminderId': '',
        });
        if (autoStart &&
            active.parameters['notifications']?.toString().toLowerCase() ==
                'enabled') {
          final scheduled = await notifications.createReminder(
            triggerTime: nextEnd,
            message:
                'Focus session complete. Take your planned sip when you’re ready.',
            priority: 1,
            requestPermissionIfNeeded: true,
          );
          if (scheduled.reminder != null) {
            await repository.updateParameters({
              ...repository.activeChallenge!.parameters,
              'timerReminderId': scheduled.reminder!.id,
            });
          }
        }
      } else {
        await repository.updateParameters({
          ...repository.activeChallenge!.parameters,
          'timerStatus': 'complete',
          'timerEndsAt': '',
        });
      }
    }
  }

  String _instruction(JoinedChallenge active, int day) {
    final amount = active.parameters['amountMl'];
    final amountText = amount is int
        ? HydrationVolumeFormatter.format(
            amount, context.read<UserSettingsRepository>().settings.volumeUnit)
        : 'your chosen amount';
    return switch (widget.challenge.id) {
      'around-the-world-infusion-week' =>
        "Today's theme: ${definition.schedule[day % definition.schedule.length]}. Confirm no added sugar and log the actual $amountText consumed.",
      'temperature-roulette' =>
        "Today's assigned style: ${((active.parameters['temperatureSchedule'] as List?) ?? definition.schedule)[day % definition.schedule.length]}. Log $amountText. ${active.parameters['weatherContext'] ?? 'Today’s standard temperature plan is in use.'}",
      'eat-your-water-day' =>
        'Include ${active.parameters['food']} with ${active.parameters['meal']}, then confirm the food task. No hydration volume will be added.',
      'pomodoro-sip' =>
        'After each ${active.parameters['sessionMinutes']}-minute focus session, manually confirm the break and log $amountText. Complete ${active.parameters['sessionsPerDay']} sessions today.',
      'bottle-bingo' =>
        'Review a Bingo tile, follow its exact amount or check-in rule, and complete it once.',
      _ =>
        'Complete today’s ${active.parameters['cue']} cue and confirm it locally. Log consumed water separately.',
    };
  }

  String _primaryActionLabel(JoinedChallenge active) {
    if (definition.actionKind == ChallengeActionKind.checkIn) {
      return 'Confirm task complete';
    }
    if (definition.actionKind == ChallengeActionKind.automaticQualification) {
      return 'Review qualifying rule';
    }
    final amount = active.parameters['amountMl'];
    return amount is int
        ? 'Log ${HydrationVolumeFormatter.format(amount, context.read<UserSettingsRepository>().settings.volumeUnit)}'
        : 'Choose amount';
  }

  Future<void> _leaveChallenge(
    BuildContext screenContext,
    JoinedChallenge active,
  ) async {
    final repository = screenContext.read<ChallengeRepository>();
    final notifications = screenContext.read<NotificationService>();
    final navigator = Navigator.of(screenContext);
    final confirmed = await showDialog<bool>(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this challenge?'),
        content: const Text(
          'Your hydration history stays intact. Challenge setup and unfinished task progress will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep challenge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave challenge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (active.id == 'pomodoro-sip') {
      final reminderId = active.parameters['timerReminderId']?.toString();
      if (reminderId != null && reminderId.isNotEmpty) {
        await notifications.deleteReminder(reminderId);
      }
    }
    await repository.leave();
    if (mounted) navigator.pop();
  }
}

class _ChallengeImageHero extends StatelessWidget {
  final String challengeName;
  final ChallengeVisualIdentity identity;
  final HydrionSex? sex;

  const _ChallengeImageHero({
    required this.challengeName,
    required this.identity,
    required this.sex,
  });

  @override
  Widget build(BuildContext context) {
    final asset = identity.dashboardAssetFor(sex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '$challengeName illustration',
        image: asset != null,
        child: Container(
          height: 210,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HydrionRadii.lg),
            gradient: LinearGradient(
              colors: [
                identity.primary.withValues(alpha: 0.92),
                identity.secondary.withValues(alpha: 0.72),
              ],
            ),
          ),
          child: asset == null
              ? Center(
                  child: Icon(identity.icon, color: Colors.white, size: 88),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      alignment: identity.imageAlignment,
                      excludeFromSemantics: true,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            identity.primary.withValues(alpha: 0.78),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          challengeName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TemperatureChallengePanel extends StatelessWidget {
  final JoinedChallenge active;
  final int day;
  final List<String> fallbackSchedule;

  const _TemperatureChallengePanel({
    required this.active,
    required this.day,
    required this.fallbackSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final stored = active.parameters['temperatureSchedule'];
    final schedule = stored is List && stored.isNotEmpty
        ? stored.map((item) => item.toString()).toList()
        : fallbackSchedule;
    final assigned = schedule[day % schedule.length];
    const styles = ['Cool', 'Room temperature', 'Comfortably warm'];
    return _Section(
      title: 'Temperature Roulette',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: "Today's assigned temperature is $assigned",
            child: Row(
              children: [
                for (final style in styles)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: style == assigned
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: style == assigned
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: style == assigned ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            style == 'Cool'
                                ? Icons.ac_unit
                                : style == 'Comfortably warm'
                                    ? Icons.local_fire_department_outlined
                                    : Icons.thermostat,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            style,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (style == assigned)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('TODAY'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(active.parameters['weatherContext']?.toString() ??
              'Weather is unavailable, so the safe standard schedule is active.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var index = 0; index < schedule.length; index++)
                Chip(
                  avatar:
                      index == day ? const Icon(Icons.today, size: 18) : null,
                  label: Text('Day ${index + 1}: ${schedule[index]}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfusionJourneyPanel extends StatelessWidget {
  final JoinedChallenge active;
  final int day;
  final List<String> schedule;
  final HydrionVolumeUnit unit;

  const _InfusionJourneyPanel({
    required this.active,
    required this.day,
    required this.schedule,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final amount = ((active.parameters['amountMl'] as num?) ?? 0).round();
    return _Section(
      title: 'Seven-day infusion journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's theme: ${schedule[day % schedule.length]}",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            amount > 0
                ? 'Prepare without added sugar and log ${HydrationVolumeFormatter.format(amount, unit)} after drinking it.'
                : 'Prepare without added sugar and log only what you drink.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var index = 0; index < schedule.length; index++)
                Chip(
                  avatar: Icon(
                    index < day
                        ? Icons.check_circle
                        : index == day
                            ? Icons.local_florist
                            : Icons.circle_outlined,
                    size: 18,
                  ),
                  label: Text('${index + 1}. ${schedule[index]}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EatYourWaterPanel extends StatelessWidget {
  final JoinedChallenge active;

  const _EatYourWaterPanel({required this.active});

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Meal check-in',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.restaurant)),
          title: Text('${active.parameters['food']}'),
          subtitle: Text(
            'Add it to ${active.parameters['meal']}. Confirming this task adds no hydration volume.',
          ),
        ),
      );
}

class _PlantCuePanel extends StatelessWidget {
  final JoinedChallenge active;

  const _PlantCuePanel({required this.active});

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Today’s real-world cue',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.local_florist)),
          title: Text('${active.parameters['cue']}'),
          subtitle: const Text(
            'Complete the cue, then check it in. Any water you drink is logged normally and never fabricated.',
          ),
        ),
      );
}

class _LiveBingoBoard extends StatelessWidget {
  final JoinedChallenge active;
  final ChallengeRepository repository;
  final HydrationRepository hydrationRepository;
  final UserSettings settings;

  const _LiveBingoBoard({
    required this.active,
    required this.repository,
    required this.hydrationRepository,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final completed = <int>{BottleBingoBoard.centerIndex};
    for (var index = 0; index < board.tiles.length; index++) {
      if (_isComplete(board.tiles[index], index)) completed.add(index);
    }
    final lines = board.completedLines(completed);
    return _Section(
      title: 'Your Bottle Bingo board',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${completed.length} of 25 tiles · ${lines.length} of 12 lines'),
          const SizedBox(height: 12),
          GridView.builder(
            key: const Key('live-bottle-bingo-board'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) {
              final tile = board.tiles[index];
              final done = completed.contains(index);
              return Semantics(
                button: tile.kind != BingoTileKind.free,
                label: '${tile.title}. ${done ? 'Completed' : 'Available'}.',
                child: InkWell(
                  key: Key('live-bingo-tile-$index'),
                  onTap: tile.kind == BingoTileKind.free
                      ? null
                      : () => _showTile(context, tile, index, done),
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: done
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tile.kind == BingoTileKind.free
                                ? Icons.water_drop
                                : done
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                            size: 18,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tile.title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          if (!done && tile.kind == BingoTileKind.automatic)
                            Text(
                              _progressLabel(context, tile),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isComplete(BingoTileDefinition tile, int index) {
    if (tile.kind == BingoTileKind.free) return true;
    if (tile.kind == BingoTileKind.checkIn) {
      return active.bottleBingoCompletedTiles.contains(index);
    }
    if (tile.kind == BingoTileKind.hydrationAction) {
      return active.completedActionIds.any((id) => id.endsWith(':${tile.id}'));
    }
    final now = DateTime.now();
    final logs = hydrationRepository.logs
        .where((log) =>
            log.timestamp.year == now.year &&
            log.timestamp.month == now.month &&
            log.timestamp.day == now.day)
        .toList();
    if (tile.goalFraction != null) {
      final total = logs.fold<int>(0, (sum, log) => sum + log.volumeMl);
      return total >= (settings.dailyGoalMl * tile.goalFraction!).round();
    }
    if (tile.logCount != null) return logs.length >= tile.logCount!;
    if (tile.id == 'afternoon-water') {
      return logs
          .any((log) => log.timestamp.hour >= 12 && log.timestamp.hour < 17);
    }
    final cutoff = ((active.parameters['cutoffHour'] as num?) ?? 12).round();
    return logs.any((log) => log.timestamp.hour < cutoff);
  }

  String _progressLabel(BuildContext context, BingoTileDefinition tile) {
    final now = DateTime.now();
    final logs = hydrationRepository.logs
        .where((log) =>
            log.timestamp.year == now.year &&
            log.timestamp.month == now.month &&
            log.timestamp.day == now.day)
        .toList();
    if (tile.goalFraction != null) {
      final total = logs.fold<int>(0, (sum, log) => sum + log.volumeMl);
      final target = (settings.dailyGoalMl * tile.goalFraction!).round();
      return '${HydrationVolumeFormatter.format(total, settings.volumeUnit)} / ${HydrationVolumeFormatter.format(target, settings.volumeUnit)}';
    }
    if (tile.logCount != null) {
      return '${logs.length} of ${tile.logCount} logs';
    }
    if (tile.id == 'afternoon-water') return '12 PM–5 PM';
    final cutoff = ((active.parameters['cutoffHour'] as num?) ?? 12).round();
    if (now.hour >= cutoff && !logs.any((log) => log.timestamp.hour < cutoff)) {
      return 'Missed today';
    }
    return 'Before ${TimeOfDay(hour: cutoff, minute: 0).format(context)}';
  }

  Future<void> _showTile(
    BuildContext context,
    BingoTileDefinition tile,
    int index,
    bool completed,
  ) async {
    final amount = ((active.parameters['amountMl'] as num?) ?? 250).round();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tile.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(tile.instruction),
              const SizedBox(height: 8),
              Text(completed
                  ? 'Completed. Your board will update if the supporting water record changes.'
                  : tile.kind == BingoTileKind.automatic
                      ? 'Water logged from Home or anywhere in Hydrion can complete this tile.'
                      : tile.kind == BingoTileKind.hydrationAction
                          ? 'This will log ${HydrationVolumeFormatter.format(amount, settings.volumeUnit)}.'
                          : 'This check-in does not add water.'),
              const SizedBox(height: 16),
              if (!completed && tile.kind == BingoTileKind.checkIn)
                FilledButton(
                  onPressed: () async {
                    await repository.toggleBottleBingoTile(index);
                    await HapticFeedback.selectionClick();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${tile.title} completed.')),
                      );
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Mark complete'),
                ),
              if (!completed && tile.kind == BingoTileKind.hydrationAction)
                FilledButton(
                  onPressed: () async {
                    final log = await repository.completeHydrationAction(
                      hydrationRepository: hydrationRepository,
                      volumeMl: amount,
                      actionKey: tile.id,
                    );
                    if (log != null) {
                      await HapticFeedback.selectionClick();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${tile.title} completed and added to your hydration log.',
                            ),
                          ),
                        );
                      }
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(
                    'Log ${HydrationVolumeFormatter.format(amount, settings.volumeUnit)}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroTimerCard extends StatefulWidget {
  final JoinedChallenge active;

  const _PomodoroTimerCard({required this.active});

  @override
  State<_PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<_PomodoroTimerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parameters = widget.active.parameters;
    final status = parameters['timerStatus']?.toString() ?? 'stopped';
    final end = DateTime.tryParse(parameters['timerEndsAt']?.toString() ?? '');
    final pausedSeconds =
        ((parameters['timerPausedSeconds'] as num?) ?? 0).round();
    final remaining = status == 'paused'
        ? Duration(seconds: pausedSeconds)
        : end == null
            ? Duration.zero
            : end.difference(DateTime.now());
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final complete = status == 'running' && safe == Duration.zero;
    final minutes = safe.inMinutes.toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final session = ((parameters['timerSession'] as num?) ?? 1).round();
    final planned = ((parameters['sessionsPerDay'] as num?) ?? 1).round();
    return _Section(
      title: 'Focus timer · Session $session of $planned',
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            label: complete
                ? 'Focus session complete'
                : '$minutes minutes $seconds seconds remaining',
            child: Text(
              complete ? 'Sip ready' : '$minutes:$seconds',
              key: const Key('pomodoro-countdown'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (status == 'running' && !complete)
                OutlinedButton.icon(
                  onPressed: () => _pause(safe),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              if (status == 'paused')
                FilledButton.icon(
                  onPressed: () => _resume(pausedSeconds),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              if (status == 'stopped')
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start next focus session'),
                ),
              if (status != 'stopped')
                OutlinedButton(
                  onPressed: _restart,
                  child: const Text('Restart session'),
                ),
              if (!complete && status != 'stopped')
                TextButton(
                  onPressed: _endEarly,
                  child: const Text('End early'),
                ),
              TextButton(
                onPressed: _stop,
                child: const Text('Stop today’s plan'),
              ),
            ],
          ),
          if (complete) ...[
            const SizedBox(height: 8),
            const Text(
                'Focus session complete. Log your planned sip when you’re ready.'),
          ],
        ],
      ),
    );
  }

  Future<void> _save(Map<String, Object?> values) async {
    await context.read<ChallengeRepository>().updateParameters({
      ...widget.active.parameters,
      ...values,
    });
  }

  Future<void> _cancelReminder() async {
    final id = widget.active.parameters['timerReminderId']?.toString();
    if (id != null && id.isNotEmpty) {
      await context.read<NotificationService>().deleteReminder(id);
    }
  }

  Future<void> _pause(Duration remaining) async {
    await _cancelReminder();
    await _save({
      'timerStatus': 'paused',
      'timerPausedSeconds': remaining.inSeconds,
      'timerEndsAt': '',
      'timerReminderId': '',
    });
  }

  Future<void> _resume(int seconds) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    await _save({
      'timerStatus': 'running',
      'timerEndsAt': end.toIso8601String(),
      'timerPausedSeconds': 0,
    });
    await _scheduleCompletionReminder(end);
  }

  Future<void> _restart() async {
    await _cancelReminder();
    final minutes =
        ((widget.active.parameters['sessionMinutes'] as num?) ?? 25).round();
    final now = DateTime.now();
    await _save({
      'timerStatus': 'running',
      'timerStartedAt': now.toIso8601String(),
      'timerEndsAt': now.add(Duration(minutes: minutes)).toIso8601String(),
      'timerPausedSeconds': 0,
      'timerReminderId': '',
    });
    await _scheduleCompletionReminder(
      now.add(Duration(minutes: minutes)),
    );
  }

  Future<void> _endEarly() async {
    await _cancelReminder();
    await _save({
      'timerStatus': 'running',
      'timerEndsAt': DateTime.now().toIso8601String(),
      'timerReminderId': '',
    });
  }

  Future<void> _stop() async {
    await _cancelReminder();
    await _save({
      'timerStatus': 'stopped',
      'timerEndsAt': '',
      'timerPausedSeconds': 0,
      'timerReminderId': '',
    });
  }

  Future<void> _scheduleCompletionReminder(DateTime end) async {
    if (widget.active.parameters['notifications']?.toString().toLowerCase() !=
        'enabled') {
      return;
    }
    final scheduled = await context.read<NotificationService>().createReminder(
          triggerTime: end,
          message:
              'Focus session complete. Take your planned sip when you’re ready.',
          priority: 1,
          requestPermissionIfNeeded: true,
        );
    if (scheduled.reminder != null && mounted) {
      await _save({'timerReminderId': scheduled.reminder!.id});
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? child;

  const _Section({required this.title, this.body, this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HydrionSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              child ?? Text(body ?? ''),
            ],
          ),
        ),
      );
}

class _ChallengeParameterField extends StatefulWidget {
  final String parameterKey;
  final TextEditingController controller;
  final HydrionVolumeUnit unit;
  final int? savedContainerMl;

  const _ChallengeParameterField({
    required this.parameterKey,
    required this.controller,
    required this.unit,
    required this.savedContainerMl,
  });

  @override
  State<_ChallengeParameterField> createState() =>
      _ChallengeParameterFieldState();
}

class _ChallengeParameterFieldState extends State<_ChallengeParameterField> {
  @override
  Widget build(BuildContext context) {
    final choices = _parameterChoices(widget.parameterKey);
    final decoration = InputDecoration(
      labelText: _parameterLabel(widget.parameterKey, widget.unit),
      helperText: _parameterHelp(widget.parameterKey),
    );
    if (choices.isNotEmpty) {
      final current = choices.contains(widget.controller.text)
          ? widget.controller.text
          : choices.first;
      widget.controller.text = current;
      return DropdownButtonFormField<String>(
        key: Key('challenge-parameter-${widget.parameterKey}'),
        initialValue: current,
        decoration: decoration,
        items: [
          for (final choice in choices)
            DropdownMenuItem(value: choice, child: Text(_choiceLabel(choice))),
        ],
        onChanged: (value) {
          if (value != null) widget.controller.text = value;
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: Key('challenge-parameter-${widget.parameterKey}'),
          controller: widget.controller,
          keyboardType: _isNumeric(widget.parameterKey)
              ? TextInputType.number
              : TextInputType.text,
          decoration: decoration,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Required before joining'
              : _validateParameter(
                  widget.parameterKey,
                  value,
                  widget.unit,
                ),
        ),
        if (widget.parameterKey == 'amountMl' &&
            widget.savedContainerMl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                widget.controller.text =
                    HydrationVolumeFormatter.fromMilliliters(
                            widget.savedContainerMl!, widget.unit)
                        .toStringAsFixed(
                  widget.unit == HydrionVolumeUnit.ounces ? 1 : 0,
                );
                setState(() {});
              },
              icon: const Icon(Icons.local_drink_outlined),
              label: Text(
                'Use saved container (${HydrationVolumeFormatter.format(widget.savedContainerMl!, widget.unit)})',
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final String title;
  final int valueMl;
  final int targetMl;
  final HydrionVolumeUnit unit;

  const _ProgressSection(
      {required this.title,
      required this.valueMl,
      required this.targetMl,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    final progress = targetMl <= 0 ? 0.0 : (valueMl / targetMl).clamp(0.0, 1.0);
    return _Section(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 320),
            builder: (_, value, __) =>
                LinearProgressIndicator(value: value, minHeight: 10),
          ),
          const SizedBox(height: 8),
          Text(
              '${HydrationVolumeFormatter.format(valueMl, unit)} / ${HydrationVolumeFormatter.format(targetMl, unit)}'),
        ],
      ),
    );
  }
}

bool _isNumeric(String key) => const {
      'amountMl',
      'cutoffHour',
      'targetPercent',
      'sessionMinutes',
      'sessionsPerDay',
      'shortBreakMinutes',
      'challengeDurationDays'
    }.contains(key);

List<String> _parameterChoices(String key) => switch (key) {
      'noAddedSugar' => const ['confirmed'],
      'weatherOrdering' ||
      'notifications' ||
      'autoStartNext' ||
      'reminderPreference' =>
        const ['enabled', 'disabled'],
      'meal' => const ['breakfast', 'lunch', 'dinner', 'snack'],
      'difficulty' => const ['gentle', 'balanced', 'active'],
      'sessionMinutes' => const ['15', '25', '45'],
      'sessionsPerDay' => const ['1', '2', '3', '4', '6', '8'],
      'shortBreakMinutes' => const ['3', '5', '10', '15'],
      'challengeDurationDays' => const ['1', '3', '5', '7', '14'],
      'cutoffHour' => const ['11', '12', '13', '14'],
      _ => const [],
    };

String _defaultParameterValue(String key, HydrionVolumeUnit unit) =>
    switch (key) {
      'amountMl' => unit == HydrionVolumeUnit.ounces ? '8.5' : '250',
      'noAddedSugar' => 'confirmed',
      'weatherOrdering' => 'enabled',
      'meal' => 'lunch',
      'food' => 'cucumber',
      'sessionMinutes' => '25',
      'sessionsPerDay' => '4',
      'shortBreakMinutes' => '5',
      'notifications' => 'enabled',
      'autoStartNext' => 'disabled',
      'challengeDurationDays' => '5',
      'cutoffHour' => '12',
      'difficulty' => 'balanced',
      'reminderPreference' => 'enabled',
      'cue' => 'Water your plant or check your bottle station',
      _ => '',
    };

String _choiceLabel(String value) => switch (value) {
      'enabled' => 'Enabled',
      'disabled' => 'Disabled',
      'confirmed' => 'Confirmed — no added sugar',
      _ => '${value[0].toUpperCase()}${value.substring(1)}',
    };

String _parameterLabel(String key, [HydrionVolumeUnit? unit]) => switch (key) {
      'amountMl' =>
        unit == HydrionVolumeUnit.ounces ? 'Amount in oz' : 'Amount in ml',
      'noAddedSugar' => 'No-added-sugar confirmation',
      'weatherOrdering' => 'Weather ordering (enabled or disabled)',
      'meal' => 'Meal',
      'food' => 'Water-rich food',
      'cutoffHour' => 'Cutoff hour (0–23)',
      'targetPercent' => 'Early target percent (10–60)',
      'sessionMinutes' => 'Focus-session minutes (10–90)',
      'sessionsPerDay' => 'Planned sessions (1–8)',
      'shortBreakMinutes' => 'Short break minutes (1–30)',
      'notifications' => 'Session reminder (enabled or disabled)',
      'autoStartNext' => 'Auto-start next session (enabled or disabled)',
      'challengeDurationDays' => 'Challenge duration (1–14 days)',
      'difficulty' => 'Difficulty (gentle, balanced, or active)',
      'reminderPreference' => 'Bingo reminder (enabled or disabled)',
      'cue' => 'Plant-care cue',
      _ => key,
    };

String _parameterHelp(String key) => switch (key) {
      'noAddedSugar' => 'Enter confirmed to accept this challenge rule.',
      'weatherOrdering' =>
        'Enter enabled or disabled. The standard plan remains available.',
      'meal' => 'Breakfast, lunch, dinner, or snack.',
      'notifications' => 'A reminder appears when a focus session ends.',
      'autoStartNext' =>
        'Choose whether the next session starts after the sip.',
      'difficulty' => 'Choose gentle, balanced, or active.',
      _ => 'Required challenge configuration.',
    };

String? _validateParameter(
  String key,
  String raw,
  HydrionVolumeUnit unit,
) {
  if (key == 'noAddedSugar' && raw.toLowerCase() != 'confirmed') {
    return 'Enter confirmed to accept this rule';
  }
  if (key == 'weatherOrdering' &&
      !const {'enabled', 'disabled'}.contains(raw.toLowerCase())) {
    return 'Enter enabled or disabled';
  }
  if (const {'notifications', 'autoStartNext', 'reminderPreference'}
          .contains(key) &&
      !const {'enabled', 'disabled'}.contains(raw.toLowerCase())) {
    return 'Enter enabled or disabled';
  }
  if (key == 'difficulty' &&
      !const {'gentle', 'balanced', 'active'}.contains(raw.toLowerCase())) {
    return 'Enter gentle, balanced, or active';
  }
  if (!_isNumeric(key)) {
    return null;
  }
  final value = key == 'amountMl' ? double.tryParse(raw) : int.tryParse(raw);
  if (value == null) {
    return 'Enter a whole number';
  }
  if (key == 'amountMl') {
    final ml = HydrationVolumeFormatter.toMilliliters(value, unit);
    if (ml < 50 || ml > 2000) {
      return unit == HydrionVolumeUnit.ounces
          ? 'Enter about 1.7–67.6 oz'
          : 'Enter 50–2000 ml';
    }
  }
  if (key == 'cutoffHour' && (value < 0 || value > 23)) {
    return 'Enter an hour from 0–23';
  }
  if (key == 'targetPercent' && (value < 10 || value > 60)) {
    return 'Enter 10–60 percent';
  }
  if (key == 'sessionMinutes' && (value < 10 || value > 90)) {
    return 'Enter 10–90 minutes';
  }
  if (key == 'sessionsPerDay' && (value < 1 || value > 8)) {
    return 'Enter 1–8 sessions';
  }
  if (key == 'shortBreakMinutes' && (value < 1 || value > 30)) {
    return 'Enter 1–30 minutes';
  }
  if (key == 'challengeDurationDays' && (value < 1 || value > 14)) {
    return 'Enter 1–14 days';
  }
  return null;
}

String _parameterSummary(
  String key,
  Object? value,
  HydrionVolumeUnit unit,
) {
  if (key == 'amountMl' && value is num) {
    return '${_parameterLabel(key, unit)}: ${HydrationVolumeFormatter.format(value, unit)}';
  }
  if (key == 'temperatureSchedule' && value is List) {
    return 'Temperature schedule: ${value.join(', ')}';
  }
  return '${_parameterLabel(key, unit)}: $value';
}
