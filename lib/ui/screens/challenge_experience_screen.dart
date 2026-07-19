import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_experience.dart';
import '../../domain/bottle_bingo.dart';
import '../../domain/challenge_visual_registry.dart';
import '../../domain/hydration_contracts.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/app_refresh_controller.dart';
import '../../services/weather_goal_service.dart';
import '../../services/notifications.dart';
import '../components/intake_ring.dart';
import '../components/guided_tour_overlay.dart';
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
  final _tutorialPrimaryTarget = GlobalKey();
  final _tutorialSecondaryTarget = GlobalKey();
  final _tutorialProgressTarget = GlobalKey();
  final _tutorialHelpTarget = GlobalKey();

  ChallengeExperienceDefinition get definition =>
      HydrionChallengeExperiences.byId(widget.challenge.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context
        .read<ChallengeRepository>()
        .activeChallengeFor(widget.challenge.id);
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
    final active = challengeRepository.activeChallengeFor(widget.challenge.id);
    JoinedChallenge? latestHistory;
    for (final item in challengeRepository.challengeHistory) {
      if (item.id == widget.challenge.id) {
        latestHistory = item;
        break;
      }
    }
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.name),
        actions: [
          if (active != null)
            PopupMenuButton<String>(
              key: const Key('challenge-overflow-menu'),
              tooltip: 'Challenge options',
              onSelected: (value) {
                if (value == 'settings') {
                  _showChallengeSettings(context, active);
                } else if (value == 'pause') {
                  _pauseChallenge(context, active);
                } else if (value == 'leave') {
                  _leaveChallenge(context, active);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Challenge settings'),
                ),
                PopupMenuItem(value: 'pause', child: Text('Pause')),
                PopupMenuItem(value: 'leave', child: Text('Leave')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        key: Key('challenge-dashboard-refresh-${widget.challenge.id}'),
        onRefresh: () => refreshHydrionData(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: active != null && !active.needsSetup
              ? _dashboard(context, active)
              : latestHistory?.lifecycleStatus ==
                      ChallengeLifecycleStatus.paused
                  ? _pausedView(context, latestHistory!)
                  : latestHistory?.lifecycleStatus ==
                              ChallengeLifecycleStatus.completed ||
                          latestHistory?.lifecycleStatus ==
                              ChallengeLifecycleStatus.archived
                      ? _completionView(context, latestHistory!)
                      : _previewAndSetup(context),
        ),
      ),
    );
    final tutorial = _contextualTutorial(active);
    if (active == null || active.needsSetup || tutorial == null) {
      return scaffold;
    }
    return ContextualGuidedTourOverlay(
      tourId: tutorial.id,
      semanticsLabel: '${widget.challenge.name} tutorial',
      steps: tutorial.steps,
      child: scaffold,
    );
  }

  _ContextualTutorial? _contextualTutorial(JoinedChallenge? active) {
    if (active == null) return null;
    final id = '${active.id}:release18-v1';
    return switch (active.id) {
      'bottle-bingo' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: 'Open a tile',
            body: 'Open any tile to see exactly what it requires.',
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: 'Automatic tiles',
            body:
                'Some tiles update automatically from your normal hydration logs.',
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: 'Actions and check-ins',
            body: 'Other tiles ask for a measured drink or a simple check-in.',
          ),
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: 'Make Bingo',
            body:
                'Complete five tiles in a row, column, or diagonal to make Bingo.',
          ),
        ]),
      'pomodoro-sip' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: 'Start a focus session',
            body: 'Start the timer when you begin a focus session.',
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: 'Choose after the timer',
            body: 'When it ends, confirm a sip or log a measured drink.',
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: 'Sip check-ins add no water',
            body: 'A sip check-in never adds a guessed hydration amount.',
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: 'Measured drinks count normally',
            body:
                'A measured drink updates normal hydration and may qualify another active challenge.',
          ),
        ]),
      'temperature-roulette' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: "Today's temperature",
            body: "Review today's assigned temperature style.",
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: 'Weather assistance',
            body:
                'When enabled, local weather may influence the recommendation.',
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: 'Log with context',
            body:
                'Use the challenge action or add temperature details when logging from Home.',
          ),
        ]),
      'around-the-world-infusion-week' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: "Today's infusion",
            body: "Review today's infusion theme.",
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: 'Prepare without added sugar',
            body: 'Use the theme without adding sugar.',
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: 'Log what you drink',
            body: 'Record the measured amount you actually drink.',
          ),
        ]),
      _ => null,
    };
  }

  List<Widget> _previewAndSetup(BuildContext context) {
    final repository = context.watch<ChallengeRepository>();
    final active = repository.activeChallengeFor(widget.challenge.id);
    final completingSetup = active != null;
    final joinBlocked =
        !completingSetup && !repository.hasRoomForAnotherChallenge;
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
                onPressed: joinBlocked ? null : () => _activate(context),
                icon: const Icon(Icons.play_arrow),
                label: Text(!joinBlocked
                    ? completingSetup
                        ? 'Complete setup'
                        : 'Join challenge'
                    : 'Pause or leave one challenge first'),
              ),
              if (joinBlocked) ...[
                const SizedBox(height: 8),
                const Text(
                  'You already have two active challenges. Pause or leave one before starting another.',
                ),
                const SizedBox(height: 8),
                for (final activeChallenge in repository.activeChallenges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(activeChallenge.name),
                    trailing: TextButton(
                      onPressed: () =>
                          _pauseChallenge(context, activeChallenge),
                      child: const Text('Pause'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _pausedView(BuildContext context, JoinedChallenge paused) {
    return [
      _ChallengeImageHero(
        challengeName: widget.challenge.name,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
        sex: context.read<UserSettingsRepository>().settings.sex,
      ),
      const _Section(
        title: 'Challenge paused',
        body:
            'Your progress and hydration history are safe. This challenge is not evaluating new hydration while paused.',
      ),
      HydrionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('challenge-resume'),
              onPressed:
                  context.read<ChallengeRepository>().hasRoomForAnotherChallenge
                      ? () async {
                          final resumed = await context
                              .read<ChallengeRepository>()
                              .resumeChallenge(paused.instanceId);
                          if (!resumed.changed && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pause or leave an active challenge before resuming this one.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume challenge'),
            ),
            TextButton(
              onPressed: () => _leavePausedChallenge(context, paused),
              child: const Text('Leave challenge'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _completionView(
    BuildContext context,
    JoinedChallenge completed,
  ) {
    final hydration = context.watch<HydrationRepository>();
    final repository = context.read<ChallengeRepository>();
    final settings = context.read<UserSettingsRepository>().settings;
    final end = completed.endedAt ?? DateTime.now();
    final contribution = hydration.logs
        .where((log) =>
            !log.timestamp.isBefore(completed.joinedAt) &&
            !log.timestamp.isAfter(end) &&
            repository.hydrationLogQualifies(completed, log))
        .fold<int>(0, (sum, log) => sum + log.volumeMl);
    final summary = completed.id == 'bottle-bingo'
        ? () {
            final board = BottleBingoBoard.forInstance(
              completed.joinedAt.microsecondsSinceEpoch,
            );
            final indexes = repository.bottleBingoCompletedIndexes(
              hydration,
              challenge: completed,
              now: end,
              dailyGoalMl: settings.dailyGoalMl,
            );
            final lines = board.completedLines(indexes);
            return 'You completed ${indexes.length} tiles and ${lines.length} Bingo ${lines.length == 1 ? 'line' : 'lines'}.';
          }()
        : _completionSummary(completed);
    return [
      _ChallengeImageHero(
        challengeName: widget.challenge.name,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
        sex: settings.sex,
      ),
      _Section(
        title: 'Challenge complete',
        body: summary,
      ),
      if (contribution > 0)
        _Section(
          title: 'Measured hydration contribution',
          body: HydrationVolumeFormatter.format(
            contribution,
            settings.volumeUnit,
          ),
        ),
      HydrionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('challenge-repeat'),
              onPressed: repository.hasRoomForAnotherChallenge
                  ? () => repository.repeatChallenge(completed.instanceId)
                  : null,
              icon: const Icon(Icons.replay),
              label: const Text('Repeat challenge'),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore another challenge'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ];
  }

  String _completionSummary(JoinedChallenge challenge) {
    return switch (challenge.id) {
      'temperature-roulette' =>
        'You completed ${challenge.durationDays} days of assigned temperature styles.',
      'around-the-world-infusion-week' =>
        'You completed the infusion themes in this attempt.',
      'eat-your-water-day' => 'You completed the water-rich food task.',
      'pomodoro-sip' =>
        'You completed focus sessions and recorded ${challenge.completedActionIds.length} sip check-ins.',
      'bottle-bingo' => 'You completed this Bottle Bingo board.',
      _ => 'You completed this challenge attempt.',
    };
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
      challengeId: active.id,
    );
    final instruction = _instruction(active, day);
    if (widget.challenge.id == 'bottle-bingo') {
      return _bottleBingoDashboard(
        context,
        active: active,
        hydration: hydration,
        settings: settings,
        repository: repository,
        todayTotalMl: total,
      );
    }
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
          key: _tutorialPrimaryTarget,
          active: active,
          day: day,
          fallbackSchedule: definition.schedule,
        ),
      if (widget.challenge.id == 'around-the-world-infusion-week')
        _InfusionJourneyPanel(
          key: _tutorialPrimaryTarget,
          active: active,
          day: day,
          schedule: definition.schedule,
          unit: settings.volumeUnit,
        ),
      if (widget.challenge.id == 'eat-your-water-day')
        _EatYourWaterPanel(active: active),
      if (widget.challenge.id == 'plant-twin-challenge')
        _PlantCuePanel(active: active),
      if (widget.challenge.id == 'pomodoro-sip')
        _PomodoroTimerCard(key: _tutorialPrimaryTarget, active: active),
      KeyedSubtree(
        key: _tutorialSecondaryTarget,
        child: _Section(
          title: "Today's parameters",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: active.parameters.entries
                .where((entry) => const {
                      'amountMl',
                      'noAddedSugar',
                      'weatherOrdering',
                      'meal',
                      'food',
                      'cutoffHour',
                      'targetPercent',
                      'sessionMinutes',
                      'sessionsPerDay',
                      'shortBreakMinutes',
                      'notifications',
                      'autoStartNext',
                      'challengeDurationDays',
                      'difficulty',
                      'reminderPreference',
                      'cue',
                    }.contains(entry.key))
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
      ),
      _ProgressSection(
        title: "Today's total hydration",
        valueMl: total,
        targetMl: settings.dailyGoalMl,
        unit: settings.volumeUnit,
      ),
      if (definition.actionKind != ChallengeActionKind.checkIn ||
          widget.challenge.id == 'pomodoro-sip')
        KeyedSubtree(
          key: _tutorialProgressTarget,
          child: _ProgressSection(
            title: 'Challenge-qualified hydration',
            valueMl: qualified.todayMl,
            targetMl: qualified.targetMl,
            unit: settings.volumeUnit,
          ),
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
            hydrationLogQualifies: (log) =>
                repository.hydrationLogQualifies(active, log),
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
            if (widget.challenge.id == 'pomodoro-sip') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: _challengeOutlinedStyle(context),
                key: const Key('pomodoro-log-measured-drink'),
                onPressed: challengeComplete
                    ? null
                    : () => _logPomodoroMeasuredDrink(context, active, day),
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(_pomodoroMeasuredDrinkLabel(active)),
              ),
            ],
          ],
        ),
      ),
      _Section(
        title: 'Challenge settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Small preferences can apply now or tomorrow. Structural changes create a new attempt and keep hydration history.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: _tutorialHelpTarget,
              onPressed: _contextualTutorial(active) == null
                  ? null
                  : () => context
                      .read<GuidedTourRepository>()
                      .replayContextualTour(_contextualTutorial(active)!.id),
              icon: const Icon(Icons.help_outline),
              label: const Text('How it works'),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: Key('challenge-edit-settings-${active.id}'),
              onPressed: () => _showChallengeSettings(context, active),
              icon: const Icon(Icons.tune),
              label: const Text('Edit challenge settings'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _bottleBingoDashboard(
    BuildContext context, {
    required JoinedChallenge active,
    required HydrationRepository hydration,
    required UserSettings settings,
    required ChallengeRepository repository,
    required int todayTotalMl,
  }) {
    final board = BottleBingoBoard.forInstance(
      active.joinedAt.microsecondsSinceEpoch,
    );
    final completed = repository.bottleBingoCompletedIndexes(
      hydration,
      challenge: active,
      dailyGoalMl: settings.dailyGoalMl,
    );
    final lines = board.completedLines(completed);
    final history = ChallengeHistoryPresenter.present(
      challenge: active,
      hydrationLogs: hydration.logs,
      unit: settings.volumeUnit,
      hydrationLogQualifies: (log) =>
          repository.hydrationLogQualifies(active, log),
    );
    final recent = history.take(4).toList(growable: false);
    return [
      _BottleBingoDashboardHero(
        asset: ChallengeVisualRegistry.forId('bottle-bingo')
            .dashboardAssetFor(settings.sex)!,
        completedTiles: completed.length,
        completedLines: lines.length,
      ),
      _BottleBingoMetrics(
        completedTiles: completed.length,
        completedLines: lines.length,
        todayMl: todayTotalMl,
        unit: settings.volumeUnit,
      ),
      _LiveBingoBoard(
        key: _tutorialPrimaryTarget,
        active: active,
        repository: repository,
        hydrationRepository: hydration,
        settings: settings,
        onConfigureAmount: () => _showChallengeSettings(context, active),
      ),
      _Section(
        title: 'Recent activity',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChallengeHistoryView(items: recent),
            if (history.length > recent.length)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('bottle-bingo-see-all-activity'),
                  onPressed: () => _showAllBingoActivity(context, history),
                  icon: const Icon(Icons.history),
                  label: const Text('See all activity'),
                ),
              ),
          ],
        ),
      ),
      const _BottleBingoInformation(),
      _Section(
        title: 'Challenge settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: _tutorialHelpTarget,
              onPressed: () => context
                  .read<GuidedTourRepository>()
                  .replayContextualTour(_contextualTutorial(active)!.id),
              icon: const Icon(Icons.help_outline),
              label: const Text('Replay board guide'),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: Key('challenge-edit-settings-${active.id}'),
              onPressed: () => _showChallengeSettings(context, active),
              icon: const Icon(Icons.tune),
              label: const Text('Edit challenge settings'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pause or leave this challenge from the options menu above. Your hydration records remain intact.',
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _showAllBingoActivity(
    BuildContext context,
    List<ChallengeHistoryItem> history,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bottle Bingo activity',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ChallengeHistoryView(items: history),
              ],
            ),
          ),
        ),
      ),
    );
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
        if (!context.mounted) return;
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
          final updated = forecast.retrievedAt.toLocal();
          final localizations = MaterialLocalizations.of(context);
          final updatedLabel = '${localizations.formatMediumDate(updated)} at '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(updated))}';
          contextText = '${schedule.first} is recommended today. '
              '${forecast.condition}, '
              '${forecast.temperatureC.toStringAsFixed(1)}°C'
              '${forecast.humidityPercent == null ? '' : ', ${forecast.humidityPercent!.round()}% humidity'}. '
              'Updated $updatedLabel.';
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
    if (repository.activeChallengeFor(widget.challenge.id) != null) {
      await repository.updateParameters(
        parameters,
        challengeId: widget.challenge.id,
      );
      return;
    }
    final joined = await repository.join(
      id: widget.challenge.id,
      name: widget.challenge.name,
      description: widget.challenge.description,
      targetMl: settingsRepository.settings.dailyGoalMl,
      durationDays: widget.challenge.id == 'pomodoro-sip'
          ? parameters['challengeDurationDays'] as int
          : widget.challenge.durationDays,
      parameters: parameters,
    );
    if (!joined && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'You already have two active challenges. Pause or leave one before starting another.',
          ),
        ),
      );
    }
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
      final completed =
          await repository.completeCheckIn(key, challengeId: active.id);
      if (completed &&
          widget.challenge.id == 'pomodoro-sip' &&
          context.mounted) {
        await _setPomodoroComplete(context, active);
      }
      if (completed && context.mounted) {
        await _completeIfFinished(context, active.id);
      }
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
      challengeId: active.id,
      metadata: _metadataForChallengeAction(active, day),
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
        final latest = repository.activeChallengeFor(active.id) ?? active;
        await repository.updateParameters({
          ...latest.parameters,
          'timerSession': next,
          'timerStatus': autoStart ? 'running' : 'stopped',
          'timerStartedAt': autoStart ? now.toIso8601String() : '',
          'timerEndsAt': autoStart ? nextEnd.toIso8601String() : '',
          'timerReminderId': '',
        }, challengeId: active.id);
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
            final latest = repository.activeChallengeFor(active.id) ?? active;
            await repository.updateParameters({
              ...latest.parameters,
              'timerReminderId': scheduled.reminder!.id,
            }, challengeId: active.id);
          }
        }
      } else {
        final latest = repository.activeChallengeFor(active.id) ?? active;
        await repository.updateParameters({
          ...latest.parameters,
          'timerStatus': 'complete',
          'timerEndsAt': '',
        }, challengeId: active.id);
      }
    }
    if (log != null && context.mounted) {
      await _completeIfFinished(context, active.id);
    }
  }

  Future<void> _logPomodoroMeasuredDrink(
    BuildContext context,
    JoinedChallenge active,
    int day,
  ) async {
    final amount = active.parameters['amountMl'];
    if (amount is! int || amount <= 0) return;
    final now = DateTime.now();
    final localDay = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final actionKey =
        '$localDay:day-${day + 1}-${widget.challenge.id}-measured-${active.completedActionIds.length + 1}';
    final metadata = await _promptPomodoroDrinkContext(context, now);
    if (metadata == null || !context.mounted) return;
    final log =
        await context.read<ChallengeRepository>().completeHydrationAction(
              hydrationRepository: context.read<HydrationRepository>(),
              volumeMl: amount,
              actionKey: actionKey,
              challengeId: active.id,
              metadata: metadata,
            );
    if (log != null && context.mounted) {
      await _setPomodoroComplete(context, active);
      if (!context.mounted) return;
      await _completeIfFinished(context, active.id);
    }
  }

  Future<HydrationMetadata?> _promptPomodoroDrinkContext(
    BuildContext context,
    DateTime now,
  ) async {
    final repository = context.read<ChallengeRepository>();
    final temperature = repository.temperatureForDay(
      'temperature-roulette',
      now,
    );
    final infusion = repository.infusionThemeForDay(
      'around-the-world-infusion-week',
      now,
    );
    if (temperature == null && infusion == null) {
      return const HydrationMetadata();
    }
    var matchesTemperature = false;
    var matchesInfusion = false;
    return showDialog<HydrationMetadata>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add drink details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The measured drink counts once. Confirm only details that apply so another active challenge can recognize it.',
              ),
              if (temperature != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: matchesTemperature,
                  onChanged: (value) => setDialogState(
                    () => matchesTemperature = value == true,
                  ),
                  title: Text('Matches today’s $temperature temperature'),
                ),
              if (infusion != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: matchesInfusion,
                  onChanged: (value) => setDialogState(
                    () => matchesInfusion = value == true,
                  ),
                  title: Text('$infusion infusion with no added sugar'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                HydrationMetadata(
                  temperatureStyle: matchesTemperature ? temperature : null,
                  infusionTheme: matchesInfusion ? infusion : null,
                  noAddedSugar: matchesInfusion ? true : null,
                ),
              ),
              child: const Text('Log measured drink'),
            ),
          ],
        ),
      ),
    );
  }

  HydrationMetadata _metadataForChallengeAction(
    JoinedChallenge active,
    int day,
  ) {
    if (active.id == 'temperature-roulette') {
      final schedule = (active.parameters['temperatureSchedule'] as List?) ??
          definition.schedule;
      return HydrationMetadata(
        temperatureStyle: schedule[day % schedule.length].toString(),
      );
    }
    if (active.id == 'around-the-world-infusion-week') {
      return HydrationMetadata(
        infusionTheme: definition.schedule[day % definition.schedule.length],
        noAddedSugar: true,
      );
    }
    return const HydrationMetadata();
  }

  Future<void> _completeIfFinished(
    BuildContext context,
    String challengeId,
  ) async {
    final repository = context.read<ChallengeRepository>();
    final hydration = context.read<HydrationRepository>();
    final notifications = context.read<NotificationService>();
    final goal = context.read<UserSettingsRepository>().settings.dailyGoalMl;
    if (!repository.isChallengeComplete(
      challengeId,
      hydration,
      dailyGoalMl: goal,
    )) {
      return;
    }
    final change = await repository.completeChallenge(challengeId);
    for (final reminderId in change.obsoleteReminderIds) {
      await notifications.deleteReminder(reminderId);
    }
  }

  Future<void> _setPomodoroComplete(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final repository = context.read<ChallengeRepository>();
    final latest = repository.activeChallengeFor(active.id) ?? active;
    await repository.updateParameters({
      ...latest.parameters,
      'timerStatus': 'complete',
      'timerEndsAt': '',
      'timerReminderId': '',
    }, challengeId: active.id);
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
        'After each ${active.parameters['sessionMinutes']}-minute focus session, choose Took a sip for a check-in or log a measured $amountText drink.',
      'bottle-bingo' =>
        'Review a Bingo tile, follow its exact amount or check-in rule, and complete it once.',
      _ =>
        'Complete today’s ${active.parameters['cue']} cue and confirm it locally. Log consumed water separately.',
    };
  }

  String _primaryActionLabel(JoinedChallenge active) {
    if (definition.actionKind == ChallengeActionKind.checkIn) {
      return widget.challenge.id == 'pomodoro-sip'
          ? 'Took a sip'
          : 'Confirm task complete';
    }
    if (definition.actionKind == ChallengeActionKind.automaticQualification) {
      return 'Review qualifying rule';
    }
    final amount = active.parameters['amountMl'];
    return amount is int
        ? 'Log ${HydrationVolumeFormatter.format(amount, context.read<UserSettingsRepository>().settings.volumeUnit)}'
        : 'Choose amount';
  }

  String _pomodoroMeasuredDrinkLabel(JoinedChallenge active) {
    final amount = active.parameters['amountMl'];
    return amount is int
        ? 'Log measured drink · ${HydrationVolumeFormatter.format(amount, context.read<UserSettingsRepository>().settings.volumeUnit)}'
        : 'Log a measured drink';
  }

  Future<void> _showChallengeSettings(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final notificationsEnabled =
            active.parameters['notifications']?.toString() == 'enabled';
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Challenge settings',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('challenge-edit-notifications'),
                  contentPadding: EdgeInsets.zero,
                  value: notificationsEnabled,
                  title: const Text('Session notifications'),
                  subtitle: const Text('Applies immediately'),
                  onChanged: (enabled) async {
                    final repository = context.read<ChallengeRepository>();
                    final notifications = context.read<NotificationService>();
                    await repository.editParameter(
                      challengeId: active.id,
                      key: 'notifications',
                      value: enabled ? 'enabled' : 'disabled',
                    );
                    if (!enabled) {
                      for (final key in const [
                        'timerReminderId',
                        'challengeReminderId',
                        'dailyReminderId',
                      ]) {
                        final id = active.parameters[key]?.toString();
                        if (id != null && id.isNotEmpty) {
                          await notifications.deleteReminder(id);
                        }
                      }
                    }
                    await notifications.reconcileSchedules();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  key: const Key('challenge-edit-serving'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_drink_outlined),
                  title: const Text('Future serving amount'),
                  subtitle: const Text(
                    'Applies next local day. Today\u2019s progress stays the same.',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _editFutureAmount(context, active);
                  },
                ),
                ListTile(
                  key: const Key('challenge-restart-attempt'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Restart challenge attempt'),
                  subtitle: const Text(
                    'Keeps hydration history and starts challenge progress again.',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmRestart(context, active);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editFutureAmount(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final unit = context.read<UserSettingsRepository>().settings.volumeUnit;
    final current = ((active.parameters['amountMl'] as num?) ?? 250).round();
    final controller = TextEditingController(
      text: HydrationVolumeFormatter.fromMilliliters(current, unit)
          .toStringAsFixed(unit == HydrionVolumeUnit.ounces ? 1 : 0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Future serving amount'),
        content: TextField(
          key: const Key('challenge-future-amount-field'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit == HydrionVolumeUnit.ounces ? 'fl oz' : 'ml',
            helperText:
                'This change starts tomorrow. Today\u2019s progress will stay the same.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('challenge-save-future-amount'),
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text),
            ),
            child: const Text('Save for tomorrow'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value <= 0 || !context.mounted) return;
    final result = await context.read<ChallengeRepository>().editParameter(
          challengeId: active.id,
          key: 'amountMl',
          value: HydrationVolumeFormatter.toMilliliters(value, unit),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _confirmRestart(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restart this challenge?'),
        content: const Text(
          'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge\u2019s progress will begin again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current attempt'),
          ),
          FilledButton(
            key: const Key('challenge-confirm-restart'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repeated = await context
        .read<ChallengeRepository>()
        .repeatChallenge(active.instanceId);
    if (repeated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new challenge attempt has started.')),
      );
    }
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
    final change = await repository.leaveChallengeWithHistory(active.id);
    for (final reminderId in change.obsoleteReminderIds) {
      await notifications.deleteReminder(reminderId);
    }
    if (mounted) navigator.pop();
  }

  Future<void> _pauseChallenge(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pause this challenge?'),
        content: const Text(
          'Progress and hydration history will stay. New hydration will not qualify until you resume.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            key: const Key('challenge-confirm-pause'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Pause'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = context.read<ChallengeRepository>();
    final notifications = context.read<NotificationService>();
    final change = await repository.pauseChallenge(active.id);
    for (final reminderId in change.obsoleteReminderIds) {
      await notifications.deleteReminder(reminderId);
    }
  }

  Future<void> _leavePausedChallenge(
    BuildContext context,
    JoinedChallenge paused,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this paused challenge?'),
        content: const Text(
          'Hydration history stays. This attempt will remain in challenge history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep paused'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context
        .read<ChallengeRepository>()
        .leavePausedChallenge(paused.instanceId);
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
    super.key,
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
              'Weather guidance is off. Today\u2019s standard schedule is active.'),
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
    super.key,
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

class _BottleBingoDashboardHero extends StatelessWidget {
  final String asset;
  final int completedTiles;
  final int completedLines;

  const _BottleBingoDashboardHero({
    required this.asset,
    required this.completedTiles,
    required this.completedLines,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shortViewport = MediaQuery.sizeOf(context).height < 500;
    final compactWidth = MediaQuery.sizeOf(context).width < 380;
    final largeText = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: const Key('bottle-bingo-dashboard-hero'),
        height: shortViewport ? 166 : 224,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HydrionRadii.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF073B55),
              colors.primary,
              const Color(0xFF49B9AC),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              key: const Key('bottle-bingo-dashboard-artwork'),
              top: -26,
              right: -6,
              bottom: -28,
              width: shortViewport ? 180 : 214,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                cacheWidth: 640,
                excludeFromSemantics: true,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: const [0, 0.62, 1],
                  colors: [
                    const Color(0xFF04243A).withValues(alpha: 0.96),
                    const Color(0xFF126E82).withValues(alpha: 0.72),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                child: Padding(
                  padding: EdgeInsets.all(shortViewport ? 14 : 20),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: LayoutBuilder(
                      builder: (context, constraints) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bottle Bingo',
                                style: (largeText
                                        ? Theme.of(context).textTheme.titleLarge
                                        : Theme.of(context)
                                            .textTheme
                                            .headlineSmall)
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (!shortViewport && !largeText) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'Complete hydration habits. Build a line. Keep the board moving.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                largeText
                                    ? '$completedTiles/25 tiles · $completedLines/12 lines'
                                    : '$completedTiles of 25 tiles · $completedLines of 12 lines',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              if (!largeText && !compactWidth) ...[
                                const SizedBox(height: 6),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_outlined,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Flexible(
                                        child: Text('Choose a tile below')),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottleBingoMetrics extends StatelessWidget {
  final int completedTiles;
  final int completedLines;
  final int todayMl;
  final HydrionVolumeUnit unit;

  const _BottleBingoMetrics({
    required this.completedTiles,
    required this.completedLines,
    required this.todayMl,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          liveRegion: true,
          label:
              '$completedTiles of 25 tiles, $completedLines of 12 lines, ${HydrationVolumeFormatter.format(todayMl, unit)} today',
          child: HydrionSurface(
            key: const Key('bottle-bingo-metrics'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _BingoMetric(
                  key: const Key('bottle-bingo-tiles-metric'),
                  icon: Icons.grid_view_rounded,
                  label: 'Tiles',
                  value: '$completedTiles / 25',
                ),
                _BingoMetric(
                  key: const Key('bottle-bingo-lines-metric'),
                  icon: Icons.linear_scale,
                  label: 'Lines',
                  value: '$completedLines / 12',
                ),
                _BingoMetric(
                  key: const Key('bottle-bingo-today-metric'),
                  icon: Icons.water_drop_outlined,
                  label: 'Today',
                  value: HydrationVolumeFormatter.format(todayMl, unit),
                ),
              ],
            ),
          ),
        ),
      );
}

class _BingoMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BingoMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      );
}

class _BottleBingoInformation extends StatelessWidget {
  const _BottleBingoInformation();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: HydrionSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ExpansionTile(
                key: Key('bottle-bingo-how-it-works'),
                leading: Icon(Icons.info_outline),
                title: Text('How it works'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatic tiles respond to normal hydration logs. Measured-drink tiles add one canonical hydration record. Habit check-ins never add water.',
                  ),
                ],
              ),
              Divider(height: 1),
              ExpansionTile(
                key: Key('bottle-bingo-rules'),
                leading: Icon(Icons.rule_outlined),
                title: Text('Rules'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The board has 25 tiles with one completed Free Drop in the center. Complete five across a row, column, or diagonal to build a line.',
                  ),
                ],
              ),
              Divider(height: 1),
              ExpansionTile(
                key: Key('bottle-bingo-safety'),
                leading: Icon(Icons.health_and_safety_outlined),
                title: Text('Hydration safety'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep intake comfortable. Do not force fluids to finish a tile or line, and stop if you feel unwell.',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _LiveBingoBoard extends StatefulWidget {
  final JoinedChallenge active;
  final ChallengeRepository repository;
  final HydrationRepository hydrationRepository;
  final UserSettings settings;
  final Future<void> Function() onConfigureAmount;

  const _LiveBingoBoard({
    super.key,
    required this.active,
    required this.repository,
    required this.hydrationRepository,
    required this.settings,
    required this.onConfigureAmount,
  });

  @override
  State<_LiveBingoBoard> createState() => _LiveBingoBoardState();
}

class _LiveBingoBoardState extends State<_LiveBingoBoard> {
  int _selectedIndex = 0;

  BottleBingoBoard get _board => BottleBingoBoard.forInstance(
        widget.active.joinedAt.microsecondsSinceEpoch,
      );

  Set<int> get _completed => widget.repository.bottleBingoCompletedIndexes(
        widget.hydrationRepository,
        challenge: widget.active,
        dailyGoalMl: widget.settings.dailyGoalMl,
      );

  @override
  Widget build(BuildContext context) {
    final board = _board;
    final completed = _completed;
    final completedLines = board.completedLines(completed);
    final todayLogs = _todayLogs;
    final lineTiles = <int>{
      for (final line in completedLines) ...BottleBingoBoard.lineIndexes[line],
    };
    final selectedTile = board.tiles[_selectedIndex];
    final selectedProgress = _progressFor(
      selectedTile,
      _selectedIndex,
      completed,
      todayLogs,
    );
    return _Section(
      title: 'Live board',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expanded = constraints.maxWidth >= 640;
          final grid = _buildGrid(
            context,
            board: board,
            completed: completed,
            lineTiles: lineTiles,
            todayLogs: todayLogs,
            expanded: expanded,
          );
          final details = _BingoTileDetails(
            key: const Key('bottle-bingo-selected-tile-details'),
            tile: selectedTile,
            progress: selectedProgress,
            amountMl: _configuredAmount,
            unit: widget.settings.volumeUnit,
            onAction: selectedTile.kind == BingoTileKind.automatic ||
                    selectedTile.kind == BingoTileKind.free ||
                    selectedProgress.state == _BingoTileState.completed
                ? null
                : selectedProgress.state == _BingoTileState.needsSetup
                    ? widget.onConfigureAmount
                    : () => _performTileAction(
                          selectedTile,
                          _selectedIndex,
                        ),
          );
          if (!expanded) return grid;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: grid),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context, {
    required BottleBingoBoard board,
    required Set<int> completed,
    required Set<int> lineTiles,
    required List<HydrationLog> todayLogs,
    required bool expanded,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            key: const Key('live-bottle-bingo-board'),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final tile = board.tiles[index];
              final progress = _progressFor(tile, index, completed, todayLogs);
              final inLine = lineTiles.contains(index);
              return _BottleBingoCell(
                key: Key('live-bingo-tile-$index'),
                tile: tile,
                progress: progress,
                selected: expanded && index == _selectedIndex,
                inCompletedLine: inLine,
                onTap: tile.kind == BingoTileKind.free
                    ? null
                    : () {
                        if (expanded) {
                          setState(() => _selectedIndex = index);
                        } else {
                          _showTileSheet(context, tile, index, progress);
                        }
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  int get _configuredAmount =>
      ((widget.active.parameters['amountMl'] as num?) ?? 0).round();

  List<HydrationLog> get _todayLogs {
    final now = DateTime.now();
    return widget.hydrationRepository.logs
        .where((log) =>
            log.timestamp.year == now.year &&
            log.timestamp.month == now.month &&
            log.timestamp.day == now.day)
        .toList(growable: false);
  }

  _BingoTileProgress _progressFor(
    BingoTileDefinition tile,
    int index,
    Set<int> completed,
    List<HydrationLog> logs,
  ) {
    if (tile.kind == BingoTileKind.free) {
      return const _BingoTileProgress(
        state: _BingoTileState.free,
        compactLabel: 'Free',
        detailLabel: 'Free center tile · completed',
      );
    }
    if (completed.contains(index)) {
      return const _BingoTileProgress(
        state: _BingoTileState.completed,
        compactLabel: 'Done',
        detailLabel: 'Completed',
      );
    }
    if (tile.kind == BingoTileKind.hydrationAction && _configuredAmount <= 0) {
      return const _BingoTileProgress(
        state: _BingoTileState.needsSetup,
        compactLabel: 'Set up',
        detailLabel: 'Needs a measured drink amount',
      );
    }
    if (tile.goalFraction != null) {
      final total = logs.fold<int>(0, (sum, log) => sum + log.volumeMl);
      final target = (widget.settings.dailyGoalMl * tile.goalFraction!).round();
      final label =
          '${HydrationVolumeFormatter.format(total, widget.settings.volumeUnit)} / ${HydrationVolumeFormatter.format(target, widget.settings.volumeUnit)}';
      return _BingoTileProgress(
        state:
            total > 0 ? _BingoTileState.inProgress : _BingoTileState.available,
        compactLabel: total > 0
            ? '${((total / target) * 100).clamp(0, 99).round()}%'
            : '${(tile.goalFraction! * 100).round()}%',
        detailLabel: label,
      );
    }
    if (tile.logCount != null) {
      final count = logs.length.clamp(0, tile.logCount!);
      return _BingoTileProgress(
        state:
            count > 0 ? _BingoTileState.inProgress : _BingoTileState.available,
        compactLabel: '$count / ${tile.logCount}',
        detailLabel: '$count of ${tile.logCount} hydration logs today',
      );
    }
    final now = DateTime.now();
    final cutoff =
        ((widget.active.parameters['cutoffHour'] as num?) ?? 12).round();
    if (tile.id == 'afternoon-water') {
      final missed = now.hour >= 17;
      return _BingoTileProgress(
        state: missed ? _BingoTileState.missed : _BingoTileState.available,
        compactLabel: missed ? 'Missed' : '12–5',
        detailLabel: missed
            ? 'Today’s noon-to-5 PM window has ended'
            : 'Available from noon to 5 PM',
      );
    }
    if (tile.id == 'before-lunch' || tile.id == 'morning-water') {
      final endHour = tile.id == 'morning-water' ? 12 : cutoff;
      final missed = now.hour >= endHour;
      return _BingoTileProgress(
        state: missed ? _BingoTileState.missed : _BingoTileState.available,
        compactLabel: missed ? 'Missed' : 'Before $endHour',
        detailLabel: missed
            ? 'Today’s time window has ended'
            : 'Available before ${TimeOfDay(hour: endHour, minute: 0).format(context)}',
      );
    }
    return const _BingoTileProgress(
      state: _BingoTileState.available,
      compactLabel: 'Ready',
      detailLabel: 'Available',
    );
  }

  Future<void> _showTileSheet(
    BuildContext context,
    BingoTileDefinition tile,
    int index,
    _BingoTileProgress progress,
  ) async {
    setState(() => _selectedIndex = index);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: _BingoTileDetails(
            tile: tile,
            progress: progress,
            amountMl: _configuredAmount,
            unit: widget.settings.volumeUnit,
            onAction: tile.kind == BingoTileKind.automatic ||
                    progress.state == _BingoTileState.completed
                ? null
                : progress.state == _BingoTileState.needsSetup
                    ? () async {
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        await widget.onConfigureAmount();
                      }
                    : () async {
                        await _performTileAction(tile, index);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
          ),
        ),
      ),
    );
  }

  Future<void> _performTileAction(
    BingoTileDefinition tile,
    int index,
  ) async {
    final beforeLines = _board.completedLines(_completed);
    var changed = false;
    if (tile.kind == BingoTileKind.checkIn) {
      changed = await widget.repository.toggleBottleBingoTile(index);
    } else if (tile.kind == BingoTileKind.hydrationAction &&
        _configuredAmount > 0) {
      final log = await widget.repository.completeHydrationAction(
        hydrationRepository: widget.hydrationRepository,
        volumeMl: _configuredAmount,
        actionKey: tile.id,
        challengeId: widget.active.id,
        metadata: HydrationMetadata(
          bingoTileSource: tile.id,
          mealContext: tile.id == 'meal-drink' ? 'with meal' : null,
          timeWindow: tile.id == 'evening-sip' ? 'evening' : null,
        ),
      );
      changed = log != null;
    }
    if (!changed || !mounted) return;
    final afterLines = _board.completedLines(_completed);
    final newLineCount = afterLines.difference(beforeLines).length;
    final complete = widget.repository.isChallengeComplete(
      widget.active.id,
      widget.hydrationRepository,
      dailyGoalMl: widget.settings.dailyGoalMl,
    );
    if (complete) {
      final notifications = context.read<NotificationService>();
      final change =
          await widget.repository.completeChallenge(widget.active.id);
      for (final reminderId in change.obsoleteReminderIds) {
        await notifications.deleteReminder(reminderId);
      }
    }
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    final message = newLineCount > 0
        ? 'Bingo! ${newLineCount == 1 ? 'A new line is complete.' : '$newLineCount new lines are complete.'}'
        : tile.kind == BingoTileKind.hydrationAction
            ? '${tile.title} completed and added once to hydration.'
            : '${tile.title} completed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {});
  }
}

enum _BingoTileState {
  free,
  available,
  inProgress,
  completed,
  needsSetup,
  missed,
}

class _BingoTileProgress {
  final _BingoTileState state;
  final String compactLabel;
  final String detailLabel;

  const _BingoTileProgress({
    required this.state,
    required this.compactLabel,
    required this.detailLabel,
  });
}

class _BottleBingoCell extends StatelessWidget {
  final BingoTileDefinition tile;
  final _BingoTileProgress progress;
  final bool selected;
  final bool inCompletedLine;
  final VoidCallback? onTap;

  const _BottleBingoCell({
    super.key,
    required this.tile,
    required this.progress,
    required this.selected,
    required this.inCompletedLine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stateColor = switch (progress.state) {
      _BingoTileState.free => colors.tertiary,
      _BingoTileState.completed => colors.primary,
      _BingoTileState.inProgress => colors.secondary,
      _BingoTileState.needsSetup => colors.error,
      _BingoTileState.missed => colors.outline,
      _BingoTileState.available => colors.outlineVariant,
    };
    final fill = switch (progress.state) {
      _BingoTileState.free => colors.tertiaryContainer,
      _BingoTileState.completed => colors.primaryContainer,
      _BingoTileState.inProgress => colors.secondaryContainer,
      _BingoTileState.needsSetup => colors.errorContainer,
      _BingoTileState.missed => colors.surfaceContainerHighest,
      _BingoTileState.available => colors.surfaceContainerHigh,
    };
    final icon = switch (progress.state) {
      _BingoTileState.free => Icons.water_drop,
      _BingoTileState.completed => Icons.check_circle,
      _BingoTileState.inProgress => Icons.timelapse,
      _BingoTileState.needsSetup => Icons.build_circle_outlined,
      _BingoTileState.missed => Icons.schedule,
      _BingoTileState.available => _iconForTile(tile),
    };
    final largeText = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.2;
    final status = _stateLabel(progress.state);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label:
          '${tile.title}. $status. ${progress.detailLabel}.${inCompletedLine ? ' Part of a completed Bingo line.' : ''}${onTap == null ? '' : ' Double tap for details.'}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: inCompletedLine
                    ? colors.tertiary
                    : selected
                        ? colors.primary
                        : stateColor,
                width: inCompletedLine || selected ? 2.5 : 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dense = constraints.maxHeight < 60 || largeText;
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!dense) Icon(icon, size: 16, color: colors.onSurface),
                      if (!dense) const SizedBox(height: 2),
                      Text(
                        _shortTitle(tile),
                        textAlign: TextAlign.center,
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                      ),
                      if (progress.state != _BingoTileState.available) ...[
                        const SizedBox(height: 1),
                        Text(
                          progress.compactLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                  ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BingoTileDetails extends StatelessWidget {
  final BingoTileDefinition tile;
  final _BingoTileProgress progress;
  final int amountMl;
  final HydrionVolumeUnit unit;
  final Future<void> Function()? onAction;

  const _BingoTileDetails({
    super.key,
    required this.tile,
    required this.progress,
    required this.amountMl,
    required this.unit,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress.state == _BingoTileState.completed ||
        progress.state == _BingoTileState.free;
    return Semantics(
      container: true,
      label: '${tile.title} details',
      child: HydrionSurface(
        key: const Key('bottle-bingo-tile-detail-surface'),
        padding: const EdgeInsets.all(14),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(_iconForTile(tile))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        key: const Key('bottle-bingo-selected-tile-title'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        avatar: Icon(_stateIcon(progress.state), size: 18),
                        label: Text(_stateLabel(progress.state)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BingoDetailLine(label: 'What to do', value: tile.instruction),
            _BingoDetailLine(
              label: 'Why it counts',
              value: _whyItCounts(tile),
            ),
            _BingoDetailLine(
              label: 'Home hydration',
              value: tile.kind == BingoTileKind.automatic
                  ? 'Can satisfy this tile automatically.'
                  : 'Does not directly complete this tile.',
            ),
            _BingoDetailLine(
              label: 'Adds hydration',
              value: tile.kind == BingoTileKind.hydrationAction
                  ? amountMl > 0
                      ? 'Yes · ${HydrationVolumeFormatter.format(amountMl, unit)} is recorded once.'
                      : 'Set a measured challenge amount before logging.'
                  : 'No new hydration record is added.',
            ),
            if (_timeWindow(tile) != null)
              _BingoDetailLine(
                label: 'Time window',
                value: _timeWindow(tile)!,
              ),
            _BingoDetailLine(
              label: 'Current progress',
              value: progress.detailLabel,
            ),
            if (!completed && onAction != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('bottle-bingo-tile-primary-action'),
                onPressed: onAction,
                icon: Icon(tile.kind == BingoTileKind.hydrationAction
                    ? progress.state == _BingoTileState.needsSetup
                        ? Icons.tune
                        : Icons.water_drop_outlined
                    : Icons.check_circle_outline),
                label: Text(
                  progress.state == _BingoTileState.needsSetup
                      ? 'Set up challenge amount'
                      : tile.kind == BingoTileKind.hydrationAction
                          ? 'Log ${HydrationVolumeFormatter.format(amountMl, unit)}'
                          : 'Complete check-in',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BingoDetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _BingoDetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(value),
          ],
        ),
      );
}

String _shortTitle(BingoTileDefinition tile) => switch (tile.id) {
      'goal-25' => 'First quarter',
      'goal-50' => 'Halfway',
      'goal-75' => 'Three quarters',
      'goal-100' => 'Goal reached',
      'logs-2' => 'Two logs',
      'logs-3' => 'Three logs',
      'logs-4' => 'Four logs',
      'morning-water' => 'Morning',
      'afternoon-water' => 'Afternoon',
      'meal-drink' => 'Meal drink',
      'water-rich-food' => 'Water-rich food',
      _ => tile.title,
    };

IconData _iconForTile(BingoTileDefinition tile) => switch (tile.id) {
      'free-drop' => Icons.water_drop,
      'goal-25' || 'goal-50' || 'goal-75' || 'goal-100' => Icons.donut_large,
      'logs-2' || 'logs-3' || 'logs-4' => Icons.format_list_numbered,
      'before-lunch' || 'morning-water' => Icons.wb_twilight_outlined,
      'afternoon-water' => Icons.wb_sunny_outlined,
      'meal-drink' || 'food' || 'meal-plan' => Icons.restaurant_outlined,
      'evening-sip' => Icons.nightlight_outlined,
      'refill' ||
      'bottle-visible' ||
      'wash-bottle' ||
      'bottle-check' =>
        Icons.local_drink_outlined,
      'prepare-infusion' => Icons.local_florist_outlined,
      'review' => Icons.insights_outlined,
      'desk-reset' => Icons.table_restaurant_outlined,
      'plan-tomorrow' => Icons.event_available_outlined,
      _ => tile.kind == BingoTileKind.hydrationAction
          ? Icons.water_drop_outlined
          : Icons.check_circle_outline,
    };

IconData _stateIcon(_BingoTileState state) => switch (state) {
      _BingoTileState.free => Icons.water_drop,
      _BingoTileState.available => Icons.radio_button_unchecked,
      _BingoTileState.inProgress => Icons.timelapse,
      _BingoTileState.completed => Icons.check_circle,
      _BingoTileState.needsSetup => Icons.build_circle_outlined,
      _BingoTileState.missed => Icons.schedule,
    };

String _stateLabel(_BingoTileState state) => switch (state) {
      _BingoTileState.free => 'Free · completed',
      _BingoTileState.available => 'Available',
      _BingoTileState.inProgress => 'In progress',
      _BingoTileState.completed => 'Completed',
      _BingoTileState.needsSetup => 'Needs setup',
      _BingoTileState.missed => 'Missed today',
    };

String _whyItCounts(BingoTileDefinition tile) => switch (tile.kind) {
      BingoTileKind.automatic =>
        'It recognizes qualifying hydration you already logged without duplicating it.',
      BingoTileKind.hydrationAction =>
        'It records the measured drink once and links that evidence to this tile.',
      BingoTileKind.checkIn =>
        'It confirms a real-world hydration habit without inventing water.',
      BingoTileKind.free =>
        'The center Free Drop starts complete for every board.',
    };

String? _timeWindow(BingoTileDefinition tile) => switch (tile.id) {
      'before-lunch' => 'Before your configured lunch cutoff.',
      'morning-water' => 'Before noon.',
      'afternoon-water' => 'Between noon and 5 PM.',
      'evening-sip' => 'During your comfortable evening routine.',
      _ => null,
    };

class _PomodoroTimerCard extends StatefulWidget {
  final JoinedChallenge active;

  const _PomodoroTimerCard({super.key, required this.active});

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
                  style: _challengeOutlinedStyle(context),
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
                  style: _challengeOutlinedStyle(context),
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

class _ContextualTutorial {
  final String id;
  final List<GuidedTourStep> steps;

  const _ContextualTutorial(this.id, this.steps);
}

ButtonStyle _challengeOutlinedStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return OutlinedButton.styleFrom(
    foregroundColor: colors.onSurface,
    side: BorderSide(color: colors.outline),
  );
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
      'amountMl' => unit == HydrionVolumeUnit.ounces
          ? 'Drink amount in oz'
          : 'Drink amount',
      'noAddedSugar' => 'No added sugar',
      'weatherOrdering' => 'Weather-guided plan',
      'meal' => 'Meal',
      'food' => 'Water-rich food',
      'cutoffHour' => 'Before-lunch cutoff',
      'targetPercent' => 'Early target',
      'sessionMinutes' => 'Focus session',
      'sessionsPerDay' => 'Daily sessions',
      'shortBreakMinutes' => 'Short break',
      'notifications' => 'Session reminder',
      'autoStartNext' => 'Auto-start next session',
      'challengeDurationDays' => 'Challenge length',
      'difficulty' => 'Difficulty',
      'reminderPreference' => 'Bingo reminder',
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
    return 'Drink amount  ${HydrationVolumeFormatter.format(value, unit)}';
  }
  if (key == 'temperatureSchedule' && value is List) {
    return 'Temperature schedule: ${value.join(', ')}';
  }
  if (key == 'sessionMinutes') return 'Focus session  $value min';
  if (key == 'sessionsPerDay') return 'Daily sessions  $value';
  if (key == 'shortBreakMinutes') return 'Short break  $value min';
  if (key == 'challengeDurationDays') return 'Challenge length  $value days';
  if (key == 'cutoffHour') return 'Before-lunch cutoff  $value:00';
  if (const {
    'weatherOrdering',
    'notifications',
    'autoStartNext',
    'reminderPreference',
  }.contains(key)) {
    final on = value.toString().toLowerCase() == 'enabled';
    return '${_parameterLabel(key, unit)}  ${on ? 'On' : 'Off'}';
  }
  if (key == 'noAddedSugar') return 'No added sugar  Confirmed';
  final text = value.toString();
  final friendly =
      text.isEmpty ? 'Not set' : '${text[0].toUpperCase()}${text.substring(1)}';
  return '${_parameterLabel(key, unit)}  $friendly';
}
