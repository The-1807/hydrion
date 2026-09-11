import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_experience.dart';
import '../../domain/challenge_activity.dart';
import '../../domain/bottle_bingo.dart';
import '../../domain/challenge_visual_registry.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/pomodoro_session.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../presentation/app_refresh_presenter.dart';
import '../../services/weather_goal_service.dart';
import '../../services/notifications.dart';
import '../../services/pomodoro_session_service.dart';
import '../../services/timed_session_notification_service.dart';
import '../components/intake_ring.dart';
import '../components/challenge_artwork.dart';
import '../components/guided_tour_overlay.dart';
import '../components/hydrion_viewport.dart';
import '../components/recognition_moment.dart';
import '../presentation/challenge_history_presenter.dart';
import '../presentation/challenge_copy.dart';
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
    final l10n = AppLocalizations.of(context);
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
              : storedValue?.toString() ??
                  _defaultParameterValue(l10n, key, unit),
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
    final l10n = AppLocalizations.of(context);
    final copy = ChallengeCopy.forChallenge(context, widget.challenge);
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
        toolbarHeight: HydrionViewport.headerHeight(context),
        title: Text(
          copy.title,
          maxLines: 2,
          overflow: TextOverflow.fade,
        ),
        actions: [
          if (active != null)
            PopupMenuButton<String>(
              key: const Key('challenge-overflow-menu'),
              tooltip: l10n.challengeOptions,
              onSelected: (value) {
                if (value == 'settings') {
                  _showChallengeSettings(context, active);
                } else if (value == 'pause') {
                  _pauseChallenge(context, active);
                } else if (value == 'leave') {
                  _leaveChallenge(context, active);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Text(l10n.challengeSettings),
                ),
                PopupMenuItem(value: 'pause', child: Text(l10n.pauseAction)),
                PopupMenuItem(value: 'leave', child: Text(l10n.leaveAction)),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        key: Key('challenge-dashboard-refresh-${widget.challenge.id}'),
        onRefresh: () => refreshHydrionData(context),
        child: ListView(
          key: Key('challenge-scroll-${widget.challenge.id}'),
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: HydrionViewport.scrollPadding(
            context,
            bottom: 32,
          ),
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
    final tutorial = _contextualTutorial(context, active);
    if (active == null || active.needsSetup || tutorial == null) {
      return scaffold;
    }
    return ContextualGuidedTourOverlay(
      tourId: tutorial.id,
      semanticsLabel: l10n.challengeTutorialSemantics(title: copy.title),
      steps: tutorial.steps,
      child: scaffold,
    );
  }

  _ContextualTutorial? _contextualTutorial(
    BuildContext context,
    JoinedChallenge? active,
  ) {
    if (active == null) return null;
    final l10n = AppLocalizations.of(context);
    final id = '${active.id}:release18-v1';
    return switch (active.id) {
      'bottle-bingo' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: l10n.tourOpenTile,
            body: l10n.tourOpenTileBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: l10n.tourAutomaticTiles,
            body: l10n.tourAutomaticTilesBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: l10n.tourActionsCheckIns,
            body: l10n.tourActionsCheckInsBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: l10n.tourMakeBingo,
            body: l10n.tourMakeBingoBody,
          ),
        ]),
      'pomodoro-sip' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: l10n.tourStartFocus,
            body: l10n.tourStartFocusBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: l10n.tourChooseAfterTimer,
            body: l10n.tourChooseAfterTimerBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: l10n.tourSipNoWater,
            body: l10n.tourSipNoWaterBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: l10n.tourMeasuredDrinks,
            body: l10n.tourMeasuredDrinksBody,
          ),
        ]),
      'temperature-roulette' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: l10n.tourTodaysTemperature,
            body: l10n.tourTodaysTemperatureBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: l10n.weatherAssistance,
            body: l10n.tourWeatherBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: l10n.tourLogWithContext,
            body: l10n.tourLogWithContextBody,
          ),
        ]),
      'around-the-world-infusion-week' => _ContextualTutorial(id, [
          GuidedTourStep(
            targetKey: _tutorialPrimaryTarget,
            title: l10n.tourTodaysInfusion,
            body: l10n.tourTodaysInfusionBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialSecondaryTarget,
            title: l10n.tourPrepareNoSugar,
            body: l10n.tourPrepareNoSugarBody,
          ),
          GuidedTourStep(
            targetKey: _tutorialProgressTarget,
            title: l10n.tourLogWhatYouDrink,
            body: l10n.tourLogWhatYouDrinkBody,
          ),
        ]),
      _ => null,
    };
  }

  List<Widget> _previewAndSetup(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = l10n.challengeCopy(widget.challenge.id);
    final repository = context.watch<ChallengeRepository>();
    final active = repository.activeChallengeFor(widget.challenge.id);
    final completingSetup = active != null;
    final joinBlocked =
        !completingSetup && !repository.hasRoomForAnotherChallenge;
    return [
      _ChallengeImageHero(
        challengeName: copy.title,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
      ),
      _Section(
        title: l10n.whatChallengeIs,
        body: l10n.challengeText(definition.purpose),
      ),
      _Section(
        title: l10n.whatYouWillDo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < definition.actions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(l10n.challengeNumbered(
                  i + 1,
                  l10n.challengeText(definition.actions[i]),
                )),
              ),
          ],
        ),
      ),
      _Section(
        title: l10n.whatCounts,
        body: l10n.challengeText(definition.whatCounts),
      ),
      _Section(
        title: l10n.whatDoesNotCount,
        body: l10n.challengeText(definition.whatDoesNotCount),
      ),
      _Section(
        title: l10n.duration,
        body: l10n.challengeDurationHelp(days: widget.challenge.durationDays),
      ),
      if (definition.schedule.isNotEmpty)
        _Section(
          title: l10n.completeSchedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < definition.schedule.length; i++)
                Text(l10n.challengeScheduleDay(
                  day: i + 1,
                  item: l10n.challengeText(definition.schedule[i]),
                )),
            ],
          ),
        ),
      _Section(
        title: l10n.howItWorks,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(l10n.hydrationProgressPrivacy),
          children: [
            Text(l10n.hydrationProgressPrivacyBody),
          ],
        ),
      ),
      HydrionSurface(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.requiredSetup,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.requiredSetupHelp),
              const SizedBox(height: 12),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: Key('activate-challenge-${widget.challenge.id}'),
                  onPressed: joinBlocked ? null : () => _activate(context),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    !joinBlocked
                        ? completingSetup
                            ? l10n.challengeText('Complete setup')
                            : l10n.challengeText('Join challenge')
                        : l10n.challengeText(
                            'Pause or leave one challenge first',
                          ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (joinBlocked) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.challengeText(
                    'You already have two active challenges. Pause or leave one before starting another.',
                  ),
                ),
                const SizedBox(height: 8),
                for (final activeChallenge in repository.activeChallenges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(l10n.challengeCopy(activeChallenge.id).title),
                    trailing: TextButton(
                      onPressed: () =>
                          _pauseChallenge(context, activeChallenge),
                      child: Text(l10n.challengeText('Pause')),
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
    final l10n = AppLocalizations.of(context);
    final copy = l10n.challengeCopy(paused.id);
    return [
      _ChallengeImageHero(
        challengeName: copy.title,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
      ),
      _Section(
        title: l10n.challengeText('Challenge paused'),
        body: l10n.challengeText(
          'Your progress and hydration history are safe. This challenge is not evaluating new hydration while paused.',
        ),
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
                              SnackBar(
                                content: Text(
                                  l10n.challengeText(
                                    'Pause or leave an active challenge before resuming this one.',
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.challengeText('Resume challenge')),
            ),
            TextButton(
              onPressed: () => _leavePausedChallenge(context, paused),
              child: Text(l10n.challengeText('Leave challenge')),
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
    final l10n = AppLocalizations.of(context);
    final copy = l10n.challengeCopy(completed.id);
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
            return l10n.challengeBingoCompletion(indexes.length, lines.length);
          }()
        : _completionSummary(l10n, completed);
    return [
      _ChallengeImageHero(
        challengeName: copy.title,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
      ),
      _Section(
        title: l10n.challengeText('Challenge complete'),
        body: summary,
      ),
      if (contribution > 0)
        _Section(
          title: l10n.challengeText('Measured hydration contribution'),
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
              label: Text(l10n.challengeText('Repeat challenge')),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined),
              label: Text(l10n.challengeText('Explore another challenge')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.challengeText('Close')),
            ),
          ],
        ),
      ),
    ];
  }

  String _completionSummary(
    AppLocalizations l10n,
    JoinedChallenge challenge,
  ) {
    return switch (challenge.id) {
      'temperature-roulette' =>
        l10n.challengeTemperatureCompletion(challenge.durationDays),
      'around-the-world-infusion-week' => l10n
          .challengeText('You completed the infusion themes in this attempt.'),
      'eat-your-water-day' =>
        l10n.challengeText('You completed the water-rich food task.'),
      'pomodoro-sip' =>
        l10n.challengePomodoroCompletion(challenge.completedActionIds.length),
      'bottle-bingo' =>
        l10n.challengeText('You completed this Bottle Bingo board.'),
      _ => l10n.challengeText('You completed this challenge attempt.'),
    };
  }

  List<Widget> _dashboard(BuildContext context, JoinedChallenge active) {
    final l10n = AppLocalizations.of(context);
    final localizedChallenge = l10n.challengeCopy(active.id);
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
    final instruction = _instruction(l10n, active, day);
    final activityDefinition = HydrionChallengeActivities.forId(active.id);
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
        challengeName: localizedChallenge.title,
        identity: ChallengeVisualRegistry.forId(widget.challenge.id),
      ),
      _Section(
        title: challengeComplete
            ? l10n.challengeCompletedStatus(active.durationDays)
            : l10n.challengeActiveStatus(day + 1, active.durationDays),
        body: localizedChallenge.description,
      ),
      _Section(
        title: l10n.challengeText("Today's instruction"),
        body: instruction,
      ),
      if (activityDefinition != null)
        _ChallengeActivityPanel(
          definition: activityDefinition,
          active: active,
          onProgress: () => _completeIfFinished(context, active.id),
          onOpenLog: () => Navigator.pushNamed(context, '/log'),
        ),
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
      if (active.parameters.entries.any(_isVisibleParameter))
        KeyedSubtree(
          key: _tutorialSecondaryTarget,
          child: _Section(
            title: l10n.challengeText("Today's parameters"),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: active.parameters.entries
                  .where(_isVisibleParameter)
                  .map((entry) => Chip(
                        label: Text(_parameterSummary(
                          context,
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
        title: l10n.challengeText(
          "Today's hydration toward your current daily goal",
        ),
        valueMl: total,
        targetMl: settings.dailyGoalMl,
        unit: settings.volumeUnit,
      ),
      if (definition.actionKind != ChallengeActionKind.checkIn ||
          widget.challenge.id == 'pomodoro-sip')
        KeyedSubtree(
          key: _tutorialProgressTarget,
          child: _ProgressSection(
            title: l10n.challengeText('Challenge-qualified hydration'),
            valueMl: qualified.todayMl,
            targetMl: qualified.targetMl,
            unit: settings.volumeUnit,
          ),
        ),
      _Section(
        title: l10n.challengeText('Challenge progress'),
        body: l10n.challengeProgressSummary(
          qualified.completedDays,
          qualified.durationDays,
          active.completedActionIds.length,
        ),
      ),
      _Section(
        title: l10n.challengeText('History'),
        child: ChallengeHistoryView(
          items: ChallengeHistoryPresenter.present(
            l10n: l10n,
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
            if (activityDefinition == null)
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
        title: l10n.challengeText('Challenge settings'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.challengeText(
                'Small preferences can apply now or tomorrow. Schedule changes begin with the next activity, while your hydration history stays intact.',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: _tutorialHelpTarget,
              onPressed: _contextualTutorial(context, active) == null
                  ? null
                  : () =>
                      context.read<GuidedTourRepository>().replayContextualTour(
                            _contextualTutorial(context, active)!.id,
                          ),
              icon: const Icon(Icons.help_outline),
              label: Text(l10n.challengeText('How it works')),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: Key('challenge-edit-settings-${active.id}'),
              onPressed: () => _showChallengeSettings(context, active),
              icon: const Icon(Icons.tune),
              label: Text(l10n.challengeText('Edit challenge settings')),
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
    final l10n = AppLocalizations.of(context);
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
      l10n: l10n,
      challenge: active,
      hydrationLogs: hydration.logs,
      unit: settings.volumeUnit,
      hydrationLogQualifies: (log) =>
          repository.hydrationLogQualifies(active, log),
    );
    final recent = history.take(4).toList(growable: false);
    return [
      _BottleBingoDashboardHero(
        identity: ChallengeVisualRegistry.forId('bottle-bingo'),
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
        title: l10n.challengeText('Recent activity'),
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
                  label: Text(l10n.challengeText('See all activity')),
                ),
              ),
          ],
        ),
      ),
      const _BottleBingoInformation(),
      _Section(
        title: l10n.challengeText('Challenge settings'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: _tutorialHelpTarget,
              onPressed: () =>
                  context.read<GuidedTourRepository>().replayContextualTour(
                        _contextualTutorial(context, active)!.id,
                      ),
              icon: const Icon(Icons.help_outline),
              label: Text(l10n.challengeText('Replay board guide')),
            ),
            OutlinedButton.icon(
              style: _challengeOutlinedStyle(context),
              key: Key('challenge-edit-settings-${active.id}'),
              onPressed: () => _showChallengeSettings(context, active),
              icon: const Icon(Icons.tune),
              label: Text(l10n.challengeText('Edit challenge settings')),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.challengeText(
                'Pause or leave this challenge from the options menu above. Your hydration records remain intact.',
              ),
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.challengeText('Bottle Bingo activity'),
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
    final messenger = ScaffoldMessenger.of(context);
    final unit = settingsRepository.settings.volumeUnit;
    final existing = repository.activeChallengeFor(widget.challenge.id);
    final parameters = <String, Object?>{
      ...?existing?.parameters,
    };
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).challengeText(
                'Choose a smaller sip amount or fewer sessions so the plan does not exceed your normal goal.',
              ),
            ),
          ),
        );
        return;
      }
      parameters['timerStatus'] = 'stopped';
      parameters['timerSession'] = 1;
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
      final assignmentSource = !weatherEnabled
          ? 'weatherDisabled'
          : contextText.startsWith('Weather is unavailable')
              ? 'weatherUnavailableFallback'
              : schedule.first == definition.schedule.first
                  ? 'weatherMatchedStandard'
                  : 'weatherRecommendation';
      if (assignmentSource == 'weatherMatchedStandard') {
        contextText =
            'Weather also recommends ${schedule.first} today; the standard assignment already matched. $contextText';
      } else if (assignmentSource == 'weatherRecommendation') {
        contextText =
            'Weather recommends ${schedule.first} today, replacing the standard ${definition.schedule.first} assignment. $contextText';
      }
      parameters['temperatureSchedule'] = schedule;
      parameters['temperatureAssignmentSource'] = assignmentSource;
      parameters['weatherContext'] = contextText;
    }
    if (widget.challenge.id == 'bottle-bingo') {
      parameters['bingoBoardVersion'] = 2;
    }
    if (existing != null) {
      final notifications = context.read<NotificationService>();
      for (final reminderId in _activityReminderIds(existing)) {
        await notifications.deleteReminder(reminderId);
      }
      await repository.updateParameters(
        parameters,
        challengeId: widget.challenge.id,
      );
      if (!context.mounted) return;
      await _scheduleActivityReminders(context, parameters);
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
      profileAge: settingsRepository.settings.age,
      parameters: parameters,
    );
    if (!joined && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).challengeText(
              'You already have two active challenges. Pause or leave one before starting another.',
            ),
          ),
        ),
      );
    } else if (joined &&
        widget.challenge.id == 'pomodoro-sip' &&
        context.mounted) {
      await context.read<PomodoroSessionService>().start();
    } else if (joined && context.mounted) {
      await _scheduleActivityReminders(context, parameters);
    }
  }

  List<String> _activityReminderIds(JoinedChallenge challenge) => [
        for (final key in const [
          'lunchReminderId',
          'shiftStartReminderId',
          'shiftMidpointReminderId',
          'shiftEndReminderId',
          'reviewReminderId',
        ])
          if ((challenge.parameters[key]?.toString().trim() ?? '').isNotEmpty)
            challenge.parameters[key]!.toString(),
      ];

  Future<void> _scheduleActivityReminders(
    BuildContext context,
    Map<String, Object?> parameters,
  ) async {
    final id = widget.challenge.id;
    if (!const {
      'lunch-break-refill',
      'shift-hydration-check',
      'evening-goal-review',
    }.contains(id)) {
      return;
    }
    if (id == 'lunch-break-refill' &&
        parameters['reminderEnabled'] != 'enabled') {
      return;
    }
    final notifications = context.read<NotificationService>();
    final now = DateTime.now();
    DateTime nextAtMinutes(int minutes) {
      var next = DateTime(
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      return next;
    }

    final requests = <(String, int, String)>[];
    if (id == 'lunch-break-refill') {
      requests.add((
        'lunchReminderId',
        ((parameters['windowStartHour'] as num).round() * 60),
        'Lunch Break Refill is ready for a bottle check.',
      ));
    } else if (id == 'evening-goal-review') {
      requests.add((
        'reviewReminderId',
        ((parameters['reviewHour'] as num).round() * 60),
        'Evening Goal Review is ready when you are.',
      ));
    } else {
      final start = (parameters['shiftStartMinutes'] as num).round();
      final duration = (parameters['shiftDurationMinutes'] as num).round();
      requests.addAll([
        (
          'shiftStartReminderId',
          start % (24 * 60),
          'Your Shift Hydration start check is ready.',
        ),
        (
          'shiftMidpointReminderId',
          (start + duration ~/ 2) % (24 * 60),
          'Your Shift Hydration midpoint check is ready.',
        ),
        (
          'shiftEndReminderId',
          (start + duration) % (24 * 60),
          'Your Shift Hydration end review is ready.',
        ),
      ]);
    }

    final reminderParameters = <String, Object?>{...parameters};
    for (final request in requests) {
      final result = await notifications.createReminder(
        triggerTime: nextAtMinutes(request.$2),
        message: request.$3,
        priority: 1,
        requestPermissionIfNeeded: true,
        challengeId: id,
      );
      if (result.reminder != null) {
        reminderParameters[request.$1] = result.reminder!.id;
      }
    }
    if (!context.mounted) return;
    await context.read<ChallengeRepository>().updateParameters(
          reminderParameters,
          challengeId: id,
        );
  }

  Future<void> _performPrimaryAction(
    BuildContext context,
    JoinedChallenge active,
    int day,
  ) async {
    final repository = context.read<ChallengeRepository>();
    if (widget.challenge.id == 'pomodoro-sip') {
      final sessions = context.read<PomodoroSessionService>();
      final state = await sessions.reconcile();
      if (!context.mounted) return;
      if (state?.lifecycle != PomodoroSessionLifecycle.completed ||
          state?.completionCommitted != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).challengeText(
                'Complete this focus session before confirming your sip.',
              ),
            ),
          ),
        );
        return;
      }
      final log = await sessions.recordSip(
        hydrationRepository: context.read<HydrationRepository>(),
      );
      if (!context.mounted) return;
      if (log == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).challengeText(
                'That sip was already recorded or could not be saved. Check your history before trying again.',
              ),
            ),
          ),
        );
        return;
      }
      await _completeIfFinished(context, active.id);
      return;
    }
    final now = DateTime.now();
    final localDay = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final key = '$localDay:day-${day + 1}-${widget.challenge.id}';
    if (definition.actionKind == ChallengeActionKind.checkIn) {
      final completed =
          await repository.completeCheckIn(key, challengeId: active.id);
      if (completed && context.mounted) {
        await _completeIfFinished(context, active.id);
      }
      return;
    }
    if (definition.actionKind == ChallengeActionKind.automaticQualification) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).challengeText(
              'Log water normally; qualifying records update this challenge automatically.',
            ),
          ),
        ),
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
    if (log != null && context.mounted) {
      await _completeIfFinished(context, active.id);
    }
  }

  Future<void> _logPomodoroMeasuredDrink(
    BuildContext context,
    JoinedChallenge active,
    int _,
  ) async {
    final amount = active.parameters['amountMl'];
    if (amount is! int || amount <= 0) return;
    final now = DateTime.now();
    final metadata = await _promptPomodoroDrinkContext(context, now);
    if (metadata == null || !context.mounted) return;
    final log =
        await context.read<PomodoroSessionService>().recordMeasuredDrink(
              hydrationRepository: context.read<HydrationRepository>(),
              amountMl: amount,
              metadata: metadata,
            );
    if (log != null && context.mounted) {
      await _completeIfFinished(context, active.id);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).challengeText(
              'Complete the focus session first, or check whether this drink was already recorded.',
            ),
          ),
        ),
      );
    }
  }

  Future<HydrationMetadata?> _promptPomodoroDrinkContext(
    BuildContext context,
    DateTime now,
  ) async {
    final l10n = AppLocalizations.of(context);
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
          title: Text(l10n.challengeText('Add drink details')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.challengeText(
                  'The measured drink counts once. Confirm only details that apply so another active challenge can recognize it.',
                ),
              ),
              if (temperature != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: matchesTemperature,
                  onChanged: (value) => setDialogState(
                    () => matchesTemperature = value == true,
                  ),
                  title: Text(l10n.challengeMatchesTemperature(
                    l10n.challengeText(temperature),
                  )),
                ),
              if (infusion != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: matchesInfusion,
                  onChanged: (value) => setDialogState(
                    () => matchesInfusion = value == true,
                  ),
                  title: Text(l10n.challengeMatchesInfusion(
                    l10n.challengeText(infusion),
                  )),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.challengeText('Cancel')),
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
              child: Text(l10n.challengeText('Log measured drink')),
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
    if (change.changed && context.mounted) {
      await RecognitionMoment.showOnce(
        context,
        repository: context.read<UserSettingsRepository>(),
        eventId:
            'challenge-complete:${change.challenge?.instanceId ?? challengeId}',
        message: AppLocalizations.of(context).challengeText(
          'Challenge complete. Your steady effort counted.',
        ),
      );
    }
  }

  String _instruction(
    AppLocalizations l10n,
    JoinedChallenge active,
    int day,
  ) {
    final amount = active.parameters['amountMl'];
    final cue = active.parameters['cue']?.toString().trim();
    final amountText = amount is int
        ? HydrationVolumeFormatter.format(
            amount, context.read<UserSettingsRepository>().settings.volumeUnit)
        : 'your chosen amount';
    return switch (widget.challenge.id) {
      'around-the-world-infusion-week' =>
        l10n.challengeInfusionDailyInstruction(
          l10n.challengeText(
            definition.schedule[day % definition.schedule.length],
          ),
          amountText,
        ),
      'temperature-roulette' => l10n.challengeTemperatureDailyInstruction(
          l10n.challengeText(
            ((active.parameters['temperatureSchedule'] as List?) ??
                    definition.schedule)[day % definition.schedule.length]
                .toString(),
          ),
          amountText,
          l10n.challengeText(
            active.parameters['weatherContext']?.toString() ??
                'Today’s standard temperature plan is in use.',
          ),
        ),
      'eat-your-water-day' => l10n.challengeFoodDailyInstruction(
          active.parameters['food'].toString(),
          active.parameters['meal'].toString(),
        ),
      'pomodoro-sip' => l10n.challengePomodoroDailyInstruction(
          (active.parameters['sessionMinutes'] as num).round(),
          amountText,
        ),
      'bottle-bingo' => l10n.challengeText(
          'Review a Bingo tile, follow its exact amount or check-in rule, and complete it once.',
        ),
      _ when cue != null && cue.isNotEmpty =>
        l10n.challengeCueDailyInstruction(cue),
      _ => l10n.challengeText(
          'Complete today’s activity, then mark it complete. Log measured water separately.',
        ),
    };
  }

  String _primaryActionLabel(JoinedChallenge active) {
    if (definition.actionKind == ChallengeActionKind.checkIn) {
      return widget.challenge.id == 'pomodoro-sip'
          ? 'Took a sip'
          : 'Confirm task complete';
    }
    if (definition.actionKind == ChallengeActionKind.automaticQualification) {
      return AppLocalizations.of(context)
          .challengeText('Review qualifying rule');
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.challengeText('Challenge settings'),
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('challenge-edit-notifications'),
                  contentPadding: EdgeInsets.zero,
                  value: notificationsEnabled,
                  title: Text(l10n.challengeText('Session notifications')),
                  subtitle: Text(l10n.challengeText('Applies immediately')),
                  onChanged: (enabled) async {
                    final repository = context.read<ChallengeRepository>();
                    final notifications = context.read<NotificationService>();
                    final pomodoroSessions =
                        context.read<PomodoroSessionService>();
                    await repository.editParameter(
                      challengeId: active.id,
                      key: 'notifications',
                      value: enabled ? 'enabled' : 'disabled',
                    );
                    if (active.id == PomodoroSessionService.challengeId) {
                      await pomodoroSessions.syncReminderPreference();
                    } else if (!enabled) {
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
                  title: Text(l10n.challengeText('Future serving amount')),
                  subtitle: Text(
                    l10n.challengeText(
                      'Applies next local day. Today\u2019s progress stays the same.',
                    ),
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
                  title: Text(l10n.challengeText('Restart challenge attempt')),
                  subtitle: Text(
                    l10n.challengeText(
                      'Keeps hydration history and starts challenge progress again.',
                    ),
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
    final l10n = AppLocalizations.of(context);
    final unit = context.read<UserSettingsRepository>().settings.volumeUnit;
    final current = ((active.parameters['amountMl'] as num?) ?? 250).round();
    final controller = TextEditingController(
      text: HydrationVolumeFormatter.fromMilliliters(current, unit)
          .toStringAsFixed(unit == HydrionVolumeUnit.ounces ? 1 : 0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.challengeText('Future serving amount')),
        content: TextField(
          key: const Key('challenge-future-amount-field'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit == HydrionVolumeUnit.ounces ? 'fl oz' : 'ml',
            helperText: l10n.challengeText(
              'This change starts tomorrow. Today\u2019s progress will stay the same.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.challengeText('Cancel')),
          ),
          FilledButton(
            key: const Key('challenge-save-future-amount'),
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text),
            ),
            child: Text(l10n.challengeText('Save for tomorrow')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(challengeEditMessage(l10n, result.messageCode)),
      ));
    }
  }

  Future<void> _confirmRestart(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.challengeText('Restart this challenge?')),
        content: Text(
          l10n.challengeText(
            'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge\u2019s progress will begin again.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.challengeText('Keep current attempt')),
          ),
          FilledButton(
            key: const Key('challenge-confirm-restart'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.challengeText('Restart')),
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
        SnackBar(
          content: Text(
            l10n.challengeText('A new challenge attempt has started.'),
          ),
        ),
      );
    }
  }

  Future<void> _leaveChallenge(
    BuildContext screenContext,
    JoinedChallenge active,
  ) async {
    final l10n = AppLocalizations.of(screenContext);
    final repository = screenContext.read<ChallengeRepository>();
    final notifications = screenContext.read<NotificationService>();
    final timedNotifications =
        screenContext.read<TimedSessionNotificationService>();
    final navigator = Navigator.of(screenContext);
    final confirmed = await showDialog<bool>(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.challengeText('Leave this challenge?')),
        content: Text(
          l10n.challengeText(
            'Your hydration history stays intact. Challenge setup and unfinished task progress will be removed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.challengeText('Keep challenge')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.challengeText('Leave challenge')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final change = await repository.leaveChallengeWithHistory(active.id);
    for (final reminderId in change.obsoleteReminderIds) {
      await notifications.deleteReminder(reminderId);
    }
    await _cancelTimedNotification(timedNotifications, active.id);
    if (mounted) navigator.pop();
  }

  Future<void> _pauseChallenge(
    BuildContext context,
    JoinedChallenge active,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.challengeText('Pause this challenge?')),
        content: Text(
          l10n.challengeText(
            'Progress and hydration history will stay. New hydration will not qualify until you resume.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.challengeText('Keep active')),
          ),
          FilledButton(
            key: const Key('challenge-confirm-pause'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.challengeText('Pause')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = context.read<ChallengeRepository>();
    final notifications = context.read<NotificationService>();
    final timedNotifications = context.read<TimedSessionNotificationService>();
    final change = await repository.pauseChallenge(active.id);
    for (final reminderId in change.obsoleteReminderIds) {
      await notifications.deleteReminder(reminderId);
    }
    await _cancelTimedNotification(timedNotifications, active.id);
  }

  Future<void> _leavePausedChallenge(
    BuildContext context,
    JoinedChallenge paused,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.challengeText('Leave this paused challenge?')),
        content: Text(
          l10n.challengeText(
            'Hydration history stays. This attempt will remain in challenge history.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.challengeText('Keep paused')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.challengeText('Leave')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final timedNotifications = context.read<TimedSessionNotificationService>();
    await context
        .read<ChallengeRepository>()
        .leavePausedChallenge(paused.instanceId);
    await _cancelTimedNotification(timedNotifications, paused.id);
  }

  Future<void> _cancelTimedNotification(
    TimedSessionNotificationService notifications,
    String challengeId,
  ) async {
    final kind = switch (challengeId) {
      'pomodoro-sip' => HydrionTimedSessionKind.pomodoro,
      'homework-hydration' => HydrionTimedSessionKind.homework,
      _ => null,
    };
    if (kind != null) {
      await notifications.cancel(kind);
    }
  }
}

class _ChallengeImageHero extends StatelessWidget {
  final String challengeName;
  final ChallengeVisualIdentity identity;

  const _ChallengeImageHero({
    required this.challengeName,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: AppLocalizations.of(context)
            .challengeIllustrationSemantics(challengeName),
        image: true,
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              ChallengeArtwork(
                key: const Key('challenge-dashboard-art'),
                identity: identity,
                profileValue:
                    context.watch<UserSettingsRepository>().settings.sex,
                cacheWidth: 720,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    final l10n = AppLocalizations.of(context);
    final stored = active.parameters['temperatureSchedule'];
    final schedule = stored is List && stored.isNotEmpty
        ? stored.map((item) => item.toString()).toList()
        : fallbackSchedule;
    final assigned = schedule[day % schedule.length];
    const styles = ['Cool', 'Room temperature', 'Comfortably warm'];
    return _Section(
      title: l10n.challengeText('Temperature Roulette'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: l10n.challengeTemperatureAssigned(
              l10n.challengeText(assigned),
            ),
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
                            l10n.challengeText(style),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (style == assigned)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(l10n.challengeText('TODAY')),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.challengeText(
            active.parameters['weatherContext']?.toString() ??
                'Weather guidance is off. Today\u2019s standard schedule is active.',
          )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var index = 0; index < schedule.length; index++)
                Chip(
                  avatar:
                      index == day ? const Icon(Icons.today, size: 18) : null,
                  label: Text(l10n.challengeScheduleItem(
                    index + 1,
                    l10n.challengeText(schedule[index]),
                  )),
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
    final l10n = AppLocalizations.of(context);
    final amount = ((active.parameters['amountMl'] as num?) ?? 0).round();
    return _Section(
      title: l10n.challengeText('Seven-day infusion journey'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.challengeTodayTheme(
              l10n.challengeText(schedule[day % schedule.length]),
            ),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.challengeInfusionInstruction(
              amount > 0 ? HydrationVolumeFormatter.format(amount, unit) : null,
            ),
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
                  label: Text(l10n.challengeNumbered(
                    index + 1,
                    l10n.challengeText(schedule[index]),
                  )),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final food = active.parameters['food']?.toString().trim();
    final meal = active.parameters['meal']?.toString().trim();
    return _Section(
      title: l10n.challengeText('Meal check-in'),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(food?.isNotEmpty == true
            ? food!
            : l10n.challengeText('Water-rich food')),
        subtitle: Text(l10n.challengeMealInstruction(
          meal?.isNotEmpty == true ? meal : null,
        )),
      ),
    );
  }
}

class _PlantCuePanel extends StatelessWidget {
  final JoinedChallenge active;

  const _PlantCuePanel({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.challengeText('Today’s real-world cue'),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.local_florist)),
        title: Text(
          active.parameters['cue']?.toString().trim().isNotEmpty == true
              ? active.parameters['cue'].toString()
              : l10n.challengeText('Check your plant or bottle station'),
        ),
        subtitle: Text(
          l10n.challengeText(
            'Complete the cue, then check it in. Any water you drink is logged normally and never fabricated.',
          ),
        ),
      ),
    );
  }
}

class _BottleBingoDashboardHero extends StatelessWidget {
  final ChallengeVisualIdentity identity;
  final int completedTiles;
  final int completedLines;

  const _BottleBingoDashboardHero({
    required this.identity,
    required this.completedTiles,
    required this.completedLines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              child: ChallengeArtwork(
                identity: identity,
                profileValue:
                    context.watch<UserSettingsRepository>().settings.sex,
                cacheWidth: 640,
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
                                l10n.challengeCopy('bottle-bingo').title,
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
                                Text(
                                  l10n.challengeText(
                                    'Complete hydration habits. Build a line. Keep the board moving.',
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                l10n.challengeBingoHeroProgress(
                                  completedTiles,
                                  completedLines,
                                  compact: largeText,
                                ),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              if (!largeText && !compactWidth) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_outlined,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(l10n.challengeText(
                                            'Choose a tile below'))),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        label: l10n.challengeBingoMetricsSemantics(
          completedTiles,
          completedLines,
          HydrationVolumeFormatter.format(todayMl, unit),
        ),
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
                label: l10n.challengeText('Tiles'),
                value: '$completedTiles / 25',
              ),
              _BingoMetric(
                key: const Key('bottle-bingo-lines-metric'),
                icon: Icons.linear_scale,
                label: l10n.challengeText('Lines'),
                value: '$completedLines / 12',
              ),
              _BingoMetric(
                key: const Key('bottle-bingo-today-metric'),
                icon: Icons.water_drop_outlined,
                label: l10n.challengeText('Today'),
                value: HydrationVolumeFormatter.format(todayMl, unit),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HydrionSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ExpansionTile(
              key: const Key('bottle-bingo-how-it-works'),
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.challengeText('How it works')),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.challengeText(
                    'Automatic tiles respond to normal hydration logs. Measured-drink tiles add one canonical hydration record. Habit check-ins never add water.',
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ExpansionTile(
              key: const Key('bottle-bingo-rules'),
              leading: const Icon(Icons.rule_outlined),
              title: Text(l10n.challengeText('Rules')),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.challengeText(
                    'The board has 25 tiles with one completed Free Drop in the center. Complete five across a row, column, or diagonal to build a line.',
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ExpansionTile(
              key: const Key('bottle-bingo-safety'),
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(l10n.challengeText('Hydration safety')),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.challengeText(
                    'Keep intake comfortable. Do not force fluids to finish a tile or line, and stop if you feel unwell.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
    final l10n = AppLocalizations.of(context);
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
      title: l10n.challengeText('Live board'),
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
    final l10n = AppLocalizations.of(context);
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
    final status = _stateLabel(l10n, progress.state);
    final title = l10n.challengeText(tile.title);
    final detail = l10n.challengeText(progress.detailLabel);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: l10n.challengeBingoTileSemantics(
        title,
        status,
        detail,
        inCompletedLine,
        onTap != null,
      ),
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
                        _shortTitle(l10n, tile),
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
                          l10n.challengeText(progress.compactLabel),
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
    final l10n = AppLocalizations.of(context);
    final title = l10n.challengeText(tile.title);
    final completed = progress.state == _BingoTileState.completed ||
        progress.state == _BingoTileState.free;
    return Semantics(
      container: true,
      label: l10n.challengeBingoDetailsSemantics(title),
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
                        title,
                        key: const Key('bottle-bingo-selected-tile-title'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        avatar: Icon(_stateIcon(progress.state), size: 18),
                        label: Text(_stateLabel(l10n, progress.state)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BingoDetailLine(
              label: l10n.challengeText('What to do'),
              value: l10n.challengeText(tile.instruction),
            ),
            _BingoDetailLine(
              label: l10n.challengeText('Why it counts'),
              value: _whyItCounts(l10n, tile),
            ),
            _BingoDetailLine(
              label: l10n.challengeText('Home hydration'),
              value: tile.kind == BingoTileKind.automatic
                  ? 'Can satisfy this tile automatically.'
                  : 'Does not directly complete this tile.',
            ),
            _BingoDetailLine(
              label: l10n.challengeText('Adds hydration'),
              value: tile.kind == BingoTileKind.hydrationAction
                  ? amountMl > 0
                      ? 'Yes · ${HydrationVolumeFormatter.format(amountMl, unit)} is recorded once.'
                      : 'Set a measured challenge amount before logging.'
                  : 'No new hydration record is added.',
            ),
            if (_timeWindow(l10n, tile) != null)
              _BingoDetailLine(
                label: l10n.challengeText('Time window'),
                value: _timeWindow(l10n, tile)!,
              ),
            _BingoDetailLine(
              label: l10n.challengeText('Current progress'),
              value: l10n.challengeText(progress.detailLabel),
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
                      ? l10n.challengeText('Set up challenge amount')
                      : tile.kind == BingoTileKind.hydrationAction
                          ? l10n.challengeLogAmount(
                              HydrationVolumeFormatter.format(amountMl, unit),
                            )
                          : l10n.challengeText('Complete check-in'),
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

String _shortTitle(AppLocalizations l10n, BingoTileDefinition tile) =>
    l10n.challengeText(switch (tile.id) {
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
    });

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

String _stateLabel(AppLocalizations l10n, _BingoTileState state) =>
    l10n.challengeText(switch (state) {
      _BingoTileState.free => 'Free · completed',
      _BingoTileState.available => 'Available',
      _BingoTileState.inProgress => 'In progress',
      _BingoTileState.completed => 'Completed',
      _BingoTileState.needsSetup => 'Needs setup',
      _BingoTileState.missed => 'Missed today',
    });

String _whyItCounts(AppLocalizations l10n, BingoTileDefinition tile) =>
    l10n.challengeText(switch (tile.kind) {
      BingoTileKind.automatic =>
        'It recognizes qualifying hydration you already logged without duplicating it.',
      BingoTileKind.hydrationAction =>
        'It records the measured drink once and links that evidence to this tile.',
      BingoTileKind.checkIn =>
        'It confirms a real-world hydration habit without inventing water.',
      BingoTileKind.free =>
        'The center Free Drop starts complete for every board.',
    });

String? _timeWindow(AppLocalizations l10n, BingoTileDefinition tile) {
  final value = switch (tile.id) {
    'before-lunch' => 'Before your configured lunch cutoff.',
    'morning-water' => 'Before noon.',
    'afternoon-water' => 'Between noon and 5 PM.',
    'evening-sip' => 'During your comfortable evening routine.',
    _ => null,
  };
  return value == null ? null : l10n.challengeText(value);
}

class _ChallengeActivityPanel extends StatefulWidget {
  final ChallengeActivityDefinition definition;
  final JoinedChallenge active;
  final Future<void> Function() onProgress;
  final VoidCallback onOpenLog;

  const _ChallengeActivityPanel({
    required this.definition,
    required this.active,
    required this.onProgress,
    required this.onOpenLog,
  });

  @override
  State<_ChallengeActivityPanel> createState() =>
      _ChallengeActivityPanelState();
}

class _ChallengeActivityPanelState extends State<_ChallengeActivityPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _ChallengeActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.watch<ChallengeRepository>();
    final active =
        repository.activeChallengeFor(widget.active.id) ?? widget.active;
    final sessionStatus =
        active.parameters['activitySessionStatus']?.toString() ?? 'stopped';
    final elapsed = repository.activitySessionElapsed(active.id);
    final elapsedLabel = '${elapsed.inMinutes.toString().padLeft(2, '0')}:'
        '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    final completed = widget.definition.checkpoints
        .where(
          (checkpoint) => repository.activityCheckpointComplete(
            active.id,
            checkpoint.id,
          ),
        )
        .length;

    return _Section(
      title: l10n.challengeText('Current activity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.challengeText(widget.definition.setupSummary)),
          if (widget.definition.safetyMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Semantics(
              label: l10n.challengeText(widget.definition.safetyMessage),
              child: Text(
                l10n.challengeText(widget.definition.safetyMessage),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (widget.definition.sessionMode !=
              ChallengeActivitySessionMode.none) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              label: l10n.challengeActivitySemantics(
                sessionStatus,
                elapsedLabel,
                _sessionStatusLabel(sessionStatus),
              ),
              child: Text(
                '$elapsedLabel · ${_sessionStatusLabel(sessionStatus)}',
                key: Key('activity-session-status-${active.id}'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sessionStatus == 'stopped')
                  FilledButton.icon(
                    key: Key('activity-start-${active.id}'),
                    onPressed: () async {
                      await repository.startActivitySession(active.id);
                      await _syncHomeworkNotification(repository, active.id);
                      _syncTicker();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.challengeText('Start activity')),
                  ),
                if (sessionStatus == 'running')
                  OutlinedButton.icon(
                    key: Key('activity-pause-${active.id}'),
                    onPressed: () async {
                      await repository.pauseActivitySession(active.id);
                      await _syncHomeworkNotification(repository, active.id);
                      _syncTicker();
                    },
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.challengeText('Pause')),
                  ),
                if (sessionStatus == 'paused')
                  FilledButton.icon(
                    key: Key('activity-resume-${active.id}'),
                    onPressed: () async {
                      await repository.startActivitySession(active.id);
                      await _syncHomeworkNotification(repository, active.id);
                      _syncTicker();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.challengeText('Resume')),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.challengeActivityProgress(
              completed,
              widget.definition.checkpoints.length,
            ),
            key: Key('activity-progress-${active.id}'),
          ),
          const SizedBox(height: 8),
          for (var index = 0;
              index < widget.definition.checkpoints.length;
              index++) ...[
            _checkpointTile(
              repository,
              active,
              widget.definition.checkpoints[index],
              index,
            ),
            if (index != widget.definition.checkpoints.length - 1)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: Key('activity-open-log-${active.id}'),
            onPressed: widget.onOpenLog,
            icon: const Icon(Icons.water_drop_outlined),
            label: Text(l10n.challengeText('Open normal drink logging')),
          ),
          Text(
            l10n.challengeText(
              'Opening drink logging does not complete this activity or add water.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkpointTile(
    ChallengeRepository repository,
    JoinedChallenge active,
    ChallengeActivityCheckpoint checkpoint,
    int index,
  ) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.challengeText(checkpoint.title);
    final description = l10n.challengeText(checkpoint.description);
    final done =
        repository.activityCheckpointComplete(active.id, checkpoint.id);
    final previousDone = index == 0 ||
        repository.activityCheckpointComplete(
          active.id,
          widget.definition.checkpoints[index - 1].id,
        );
    final sessionStatus =
        active.parameters['activitySessionStatus']?.toString() ?? 'stopped';
    final needsSession =
        widget.definition.sessionMode != ChallengeActivitySessionMode.none;
    final enabled = !done &&
        previousDone &&
        (!needsSession ||
            sessionStatus == 'running' ||
            sessionStatus == 'paused');
    return Semantics(
      label: l10n.challengeCheckpointSemantics(
        title,
        done
            ? 'Completed'
            : enabled
                ? 'Available'
                : 'Waiting',
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(HydrionRadii.md),
          border: Border.all(
            color: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(l10n.challengeText(done
                      ? 'Completed'
                      : enabled
                          ? 'Available'
                          : 'Waiting')),
                ],
              ),
              const SizedBox(height: 4),
              Text(description),
              if (!done) ...[
                const SizedBox(height: 8),
                if (active.id == 'backpack-bottle-check')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final outcome in const [
                        ('ready', 'Ready'),
                        ('packed', 'Packed'),
                        ('needsAttention', 'Needs attention'),
                      ])
                        OutlinedButton(
                          onPressed: enabled
                              ? () => _complete(
                                    repository,
                                    active,
                                    checkpoint,
                                    outcome: outcome.$1,
                                  )
                              : null,
                          child: Text(l10n.challengeText(outcome.$2)),
                        ),
                    ],
                  )
                else if (active.id == 'lunch-break-refill')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: enabled
                            ? () => _complete(
                                  repository,
                                  active,
                                  checkpoint,
                                  outcome: 'bottleChecked',
                                )
                            : null,
                        child: Text(l10n.challengeText('Bottle checked')),
                      ),
                      OutlinedButton(
                        onPressed: enabled
                            ? () => _complete(
                                  repository,
                                  active,
                                  checkpoint,
                                  outcome: 'refilled',
                                )
                            : null,
                        child: Text(l10n.challengeText('Refilled')),
                      ),
                    ],
                  )
                else
                  FilledButton(
                    key: Key(
                      'activity-checkpoint-${active.id}-${checkpoint.id}',
                    ),
                    onPressed: enabled
                        ? () => _complete(repository, active, checkpoint)
                        : null,
                    child: Text(l10n.challengeCompleteCheckpoint(title)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(
    ChallengeRepository repository,
    JoinedChallenge active,
    ChallengeActivityCheckpoint checkpoint, {
    String? outcome,
  }) async {
    final completed = await repository.completeActivityCheckpoint(
      challengeId: active.id,
      checkpointId: checkpoint.id,
      outcome: outcome,
    );
    if (!mounted) return;
    if (completed) {
      final dailyComplete =
          checkpoint.id == widget.definition.checkpoints.last.id;
      if (dailyComplete) {
        final notifications = context.read<NotificationService>();
        await repository.resetActivitySession(active.id);
        if (active.id == 'homework-hydration' && mounted) {
          await context
              .read<TimedSessionNotificationService>()
              .cancel(HydrionTimedSessionKind.homework);
        }
        if (!mounted) return;
        final latest = repository.activeChallengeFor(active.id);
        if (latest != null) {
          final keys = switch (active.id) {
            'lunch-break-refill' => const ['lunchReminderId'],
            'evening-goal-review' => const ['reviewReminderId'],
            'shift-hydration-check' => const [
                'shiftStartReminderId',
                'shiftMidpointReminderId',
                'shiftEndReminderId',
              ],
            _ => const <String>[],
          };
          final nextParameters = <String, Object?>{...latest.parameters};
          for (final key in keys) {
            final reminderId = nextParameters[key]?.toString() ?? '';
            if (reminderId.isNotEmpty) {
              await notifications.deleteReminder(reminderId);
              nextParameters[key] = '';
            }
          }
          await repository.updateParameters(
            nextParameters,
            challengeId: active.id,
          );
        }
      }
      await widget.onProgress();
      if (!mounted) return;
      if (dailyComplete) {
        final now = DateTime.now();
        final day = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        await RecognitionMoment.showOnce(
          context,
          repository: context.read<UserSettingsRepository>(),
          eventId: 'challenge-day:${active.instanceId}:$day',
          message: AppLocalizations.of(context).challengeText(
            'Today’s challenge activity is complete.',
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dailyComplete
                ? AppLocalizations.of(context)
                    .challengeText('Today’s challenge activity is complete.')
                : AppLocalizations.of(context).challengeCheckpointCompleted(
                    AppLocalizations.of(context)
                        .challengeText(checkpoint.title),
                  ),
          ),
        ),
      );
    }
  }

  void _syncTicker() {
    if (!mounted) return;
    _ticker?.cancel();
    final repository = context.read<ChallengeRepository>();
    final active = repository.activeChallengeFor(widget.active.id);
    if (active?.parameters['activitySessionStatus'] != 'running') return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _syncHomeworkNotification(
    ChallengeRepository repository,
    String challengeId,
  ) async {
    if (challengeId != 'homework-hydration' || !mounted) return;
    final challenge = repository.activeChallengeFor(challengeId);
    if (challenge == null) return;
    final status = challenge.parameters['activitySessionStatus']?.toString();
    final totalMinutes =
        ((challenge.parameters['sessionMinutes'] as num?) ?? 25)
            .round()
            .clamp(1, 1440);
    final remaining = Duration(minutes: totalMinutes) -
        repository.activitySessionElapsed(challengeId);
    final lifecycle = switch (status) {
      'running' => HydrionTimedSessionLifecycle.running,
      'paused' => HydrionTimedSessionLifecycle.paused,
      _ => HydrionTimedSessionLifecycle.stopped,
    };
    await context.read<TimedSessionNotificationService>().sync(
          HydrionTimedSessionNotification(
            kind: HydrionTimedSessionKind.homework,
            lifecycle: lifecycle,
            remaining: remaining.isNegative ? Duration.zero : remaining,
            completionAt: lifecycle == HydrionTimedSessionLifecycle.running
                ? DateTime.now().add(
                    remaining.isNegative ? Duration.zero : remaining,
                  )
                : null,
          ),
        );
  }

  String _sessionStatusLabel(String status) => switch (status) {
        'running' => AppLocalizations.of(context).challengeText('Active'),
        'paused' => AppLocalizations.of(context).challengeText('Paused'),
        _ => AppLocalizations.of(context).challengeText('Ready'),
      };
}

class _PomodoroTimerCard extends StatefulWidget {
  final JoinedChallenge active;

  const _PomodoroTimerCard({super.key, required this.active});

  @override
  State<_PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<_PomodoroTimerCard>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _reconciling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcile();
    });
  }

  @override
  void didUpdateWidget(covariant _PomodoroTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcile();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sessionState =
        context.read<PomodoroSessionService>().stateFor(widget.active);
    final snapshot = sessionState.snapshot(DateTime.now());
    final complete = snapshot.isCompleted ||
        snapshot.isRunning && snapshot.remainingDuration == Duration.zero;
    final minutes =
        snapshot.remainingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (snapshot.remainingDuration.inSeconds % 60).toString().padLeft(2, '0');
    final session = sessionState.sessionNumber;
    final planned =
        ((widget.active.parameters['sessionsPerDay'] as num?) ?? 1).round();
    return _Section(
      title: l10n.challengeFocusTimerTitle(session, planned),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            label: complete
                ? l10n.challengeText('Focus session complete')
                : l10n.challengeFocusRemaining(minutes, seconds),
            child: Text(
              complete ? l10n.challengeText('Sip ready') : '$minutes:$seconds',
              key: const Key('pomodoro-countdown'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.challengeFocusProgress(
              (snapshot.progress * 100).round(),
            ),
            child: LinearProgressIndicator(
              key: const Key('pomodoro-meter'),
              value: snapshot.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (snapshot.isRunning && !complete)
                OutlinedButton.icon(
                  key: const Key('pomodoro-pause'),
                  style: _challengeOutlinedStyle(context),
                  onPressed: _pause,
                  icon: const Icon(Icons.pause),
                  label: Text(l10n.challengeText('Pause')),
                ),
              if (snapshot.isPaused)
                FilledButton.icon(
                  key: const Key('pomodoro-resume'),
                  onPressed: _resume,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.challengeText('Resume')),
                ),
              if (snapshot.lifecycle == PomodoroSessionLifecycle.stopped ||
                  snapshot.lifecycle == PomodoroSessionLifecycle.notStarted)
                FilledButton.icon(
                  key: const Key('pomodoro-start'),
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.challengeText('Start next focus session')),
                ),
              if (snapshot.lifecycle != PomodoroSessionLifecycle.stopped &&
                  snapshot.lifecycle != PomodoroSessionLifecycle.notStarted)
                OutlinedButton(
                  key: const Key('pomodoro-restart'),
                  style: _challengeOutlinedStyle(context),
                  onPressed: _restart,
                  child: Text(l10n.challengeText('Restart session')),
                ),
              if (!complete && snapshot.isRunning)
                TextButton(
                  key: const Key('pomodoro-end-early'),
                  onPressed: _endEarly,
                  child: Text(l10n.challengeText('End early')),
                ),
              TextButton(
                key: const Key('pomodoro-stop'),
                onPressed: _stop,
                child: Text(l10n.challengeText('Stop today’s plan')),
              ),
            ],
          ),
          if (complete) ...[
            const SizedBox(height: 8),
            Text(
              l10n.challengeText(
                'Focus session complete. No water has been added. Confirm Took a sip or log a measured drink when you actually drink.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _start() async {
    await context.read<PomodoroSessionService>().start();
    _syncTicker();
  }

  Future<void> _pause() async {
    await context.read<PomodoroSessionService>().pause();
    _syncTicker();
  }

  Future<void> _resume() async {
    await context.read<PomodoroSessionService>().resume();
    _syncTicker();
  }

  Future<void> _restart() async {
    await context.read<PomodoroSessionService>().restart();
    _syncTicker();
  }

  Future<void> _endEarly() async {
    await context.read<PomodoroSessionService>().completeEarly();
    _syncTicker();
  }

  Future<void> _stop() async {
    await context.read<PomodoroSessionService>().stop();
    _syncTicker();
  }

  void _syncTicker() {
    if (!mounted) return;
    final state =
        context.read<PomodoroSessionService>().stateFor(widget.active);
    if (state.lifecycle != PomodoroSessionLifecycle.running) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    if (_ticker?.isActive == true) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final snapshot = context
          .read<PomodoroSessionService>()
          .stateFor(widget.active)
          .snapshot(DateTime.now());
      setState(() {});
      if (snapshot.remainingDuration == Duration.zero) {
        _reconcile();
      }
    });
  }

  Future<void> _reconcile() async {
    if (!mounted || _reconciling) return;
    _reconciling = true;
    try {
      await context.read<PomodoroSessionService>().reconcile();
      if (mounted) {
        setState(() {});
        _syncTicker();
      }
    } finally {
      _reconciling = false;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? child;

  const _Section({required this.title, this.body, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null && (body == null || body!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
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
    final l10n = AppLocalizations.of(context);
    final choices = _parameterChoices(widget.parameterKey);
    final decoration = InputDecoration(
      labelText: _parameterLabel(l10n, widget.parameterKey, widget.unit),
      helperText: _parameterHelp(l10n, widget.parameterKey),
      helperMaxLines: 3,
    );
    if (choices.isNotEmpty) {
      final current = choices.contains(widget.controller.text)
          ? widget.controller.text
          : choices.first;
      widget.controller.text = current;
      return DropdownButtonFormField<String>(
        key: Key('challenge-parameter-${widget.parameterKey}'),
        initialValue: current,
        isExpanded: true,
        decoration: decoration,
        items: [
          for (final choice in choices)
            DropdownMenuItem(
              value: choice,
              child: Text(
                _choiceLabel(l10n, choice),
                softWrap: true,
              ),
            ),
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
              ? l10n.challengeText('Required before joining')
              : _validateParameter(
                  l10n,
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
                '${l10n.challengeText('Use saved container')} (${HydrationVolumeFormatter.format(widget.savedContainerMl!, widget.unit)})',
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
      'challengeDurationDays',
      'windowStartHour',
      'preparationHour',
      'travelStartHour',
      'reviewHour',
      'blockMinutes',
      'resetFrequencyMinutes',
      'shiftStartMinutes',
      'shiftDurationMinutes',
    }.contains(key);

List<String> _parameterChoices(String key) => switch (key) {
      'noAddedSugar' => const ['confirmed'],
      'weatherOrdering' ||
      'notifications' ||
      'autoStartNext' ||
      'reminderPreference' ||
      'reminderEnabled' =>
        const ['enabled', 'disabled'],
      'meal' => const ['breakfast', 'lunch', 'dinner', 'snack'],
      'difficulty' => const ['gentle', 'balanced', 'active'],
      'sessionMinutes' => const ['15', '25', '45'],
      'sessionsPerDay' => const ['1', '2', '3', '4', '6', '8'],
      'shortBreakMinutes' => const ['3', '5', '10', '15'],
      'challengeDurationDays' => const ['1', '3', '5', '7', '14'],
      'cutoffHour' => const ['11', '12', '13', '14'],
      'windowStartHour' => const ['11', '12', '13', '14', '15', '16', '17'],
      'preparationHour' => const ['6', '7', '8', '17', '18', '19', '20'],
      'travelStartHour' => const ['7', '8', '9', '16', '17', '18', '19'],
      'reviewHour' => const ['18', '19', '20', '21'],
      'blockMinutes' => const ['30', '45', '60', '90'],
      'resetFrequencyMinutes' => const ['30', '45', '60', '90'],
      'shiftStartMinutes' => const ['420', '480', '540', '960', '1200', '1380'],
      'shiftDurationMinutes' => const ['360', '480', '600', '720'],
      'checkpointPattern' => const ['midpoint', 'two-checkpoints'],
      _ => const [],
    };

String _defaultParameterValue(
        AppLocalizations l10n, String key, HydrionVolumeUnit unit) =>
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
      'cue' =>
        l10n.challengeText('Water your plant or check your bottle station'),
      'windowStartHour' => '12',
      'preparationHour' => '19',
      'travelStartHour' => '8',
      'reviewHour' => '20',
      'blockMinutes' => '60',
      'resetFrequencyMinutes' => '45',
      'shiftStartMinutes' => '480',
      'shiftDurationMinutes' => '480',
      'checkpointPattern' => 'midpoint',
      'reminderEnabled' => 'disabled',
      _ => '',
    };

String _choiceLabel(AppLocalizations l10n, String value) => l10n.challengeText(
      switch (value) {
        'enabled' => 'Enabled',
        'disabled' => 'Disabled',
        'confirmed' => 'Confirmed — no added sugar',
        _ => '${value[0].toUpperCase()}${value.substring(1)}',
      },
    );

String _parameterLabel(
  AppLocalizations l10n,
  String key, [
  HydrionVolumeUnit? unit,
]) =>
    l10n.challengeText(switch (key) {
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
      'windowStartHour' => 'Routine window',
      'preparationHour' => 'Preparation time',
      'travelStartHour' => 'Travel begins',
      'reviewHour' => 'Evening review time',
      'blockMinutes' => 'Seated-work block',
      'resetFrequencyMinutes' => 'Reset frequency',
      'shiftStartMinutes' => 'Shift start',
      'shiftDurationMinutes' => 'Expected shift duration',
      'checkpointPattern' => 'Checkpoint pattern',
      'reminderEnabled' => 'Optional reminder',
      _ => key,
    });

String? _parameterHelp(AppLocalizations l10n, String key) {
  final value = switch (key) {
    'noAddedSugar' => 'Enter confirmed to accept this challenge rule.',
    'weatherOrdering' =>
      'Enter enabled or disabled. The standard plan remains available.',
    'meal' => 'Breakfast, lunch, dinner, or snack.',
    'notifications' => 'A reminder appears when a focus session ends.',
    'autoStartNext' => 'Choose whether the next session starts after the sip.',
    'difficulty' => 'Choose gentle, balanced, or active.',
    'shiftStartMinutes' =>
      'Minutes after midnight. Overnight shifts are supported.',
    'shiftDurationMinutes' => 'The shift may cross local midnight.',
    'travelStartHour' =>
      'The preparation action is disabled once this travel hour begins.',
    'reminderEnabled' => 'Enable only after this setup is saved.',
    _ => null,
  };
  return value == null ? null : l10n.challengeText(value);
}

String? _validateParameter(
  AppLocalizations l10n,
  String key,
  String raw,
  HydrionVolumeUnit unit,
) {
  if (key == 'noAddedSugar' && raw.toLowerCase() != 'confirmed') {
    return l10n.challengeText('Enter confirmed to accept this rule');
  }
  if (key == 'weatherOrdering' &&
      !const {'enabled', 'disabled'}.contains(raw.toLowerCase())) {
    return l10n.challengeText('Enter enabled or disabled');
  }
  if (const {
        'notifications',
        'autoStartNext',
        'reminderPreference',
        'reminderEnabled',
      }.contains(key) &&
      !const {'enabled', 'disabled'}.contains(raw.toLowerCase())) {
    return l10n.challengeText('Enter enabled or disabled');
  }
  if (key == 'difficulty' &&
      !const {'gentle', 'balanced', 'active'}.contains(raw.toLowerCase())) {
    return l10n.challengeText('Enter gentle, balanced, or active');
  }
  if (!_isNumeric(key)) {
    return null;
  }
  final value = key == 'amountMl' ? double.tryParse(raw) : int.tryParse(raw);
  if (value == null) {
    return l10n.challengeText('Enter a whole number');
  }
  if (key == 'amountMl') {
    final ml = HydrationVolumeFormatter.toMilliliters(value, unit);
    if (ml < 50 || ml > 2000) {
      return unit == HydrionVolumeUnit.ounces
          ? l10n.challengeText('Enter about 1.7–67.6 oz')
          : l10n.challengeText('Enter 50–2000 ml');
    }
  }
  if (key == 'cutoffHour' && (value < 0 || value > 23)) {
    return l10n.challengeText('Enter an hour from 0–23');
  }
  if (key == 'targetPercent' && (value < 10 || value > 60)) {
    return l10n.challengeText('Enter 10–60 percent');
  }
  if (key == 'sessionMinutes' && (value < 10 || value > 90)) {
    return l10n.challengeText('Enter 10–90 minutes');
  }
  if (key == 'sessionsPerDay' && (value < 1 || value > 8)) {
    return l10n.challengeText('Enter 1–8 sessions');
  }
  if (key == 'shortBreakMinutes' && (value < 1 || value > 30)) {
    return l10n.challengeText('Enter 1–30 minutes');
  }
  if (key == 'challengeDurationDays' && (value < 1 || value > 14)) {
    return l10n.challengeText('Enter 1–14 days');
  }
  return null;
}

String _parameterSummary(
  BuildContext context,
  String key,
  Object? value,
  HydrionVolumeUnit unit,
) {
  final l10n = AppLocalizations.of(context);
  if (key == 'amountMl' && value is num) {
    return '${l10n.challengeText('Drink amount')}  ${HydrationVolumeFormatter.format(value, unit)}';
  }
  if (key == 'temperatureSchedule' && value is List) {
    return '${l10n.challengeText('Temperature schedule')}: ${value.map((item) => l10n.challengeText(item.toString())).join(', ')}';
  }
  if (key == 'sessionMinutes') {
    return '${l10n.challengeText('Focus session')}  $value min';
  }
  if (key == 'sessionsPerDay') {
    return '${l10n.challengeText('Daily sessions')}  $value';
  }
  if (key == 'shortBreakMinutes') {
    return '${l10n.challengeText('Short break')}  $value min';
  }
  if (key == 'challengeDurationDays') {
    return '${l10n.challengeText('Challenge length')}  $value ${l10n.challengeText('days')}';
  }
  if (key == 'cutoffHour') {
    return '${l10n.challengeText('Before-lunch cutoff')}  ${_formatHour(context, value)}';
  }
  if (const {
    'windowStartHour',
    'preparationHour',
    'travelStartHour',
    'reviewHour',
  }.contains(key)) {
    return '${_parameterLabel(l10n, key, unit)}  ${_formatHour(context, value)}';
  }
  if (key == 'shiftStartMinutes' && value is num) {
    final minutes = value.round();
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return '${l10n.challengeText('Shift start')}  ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute))}';
  }
  if (key == 'shiftDurationMinutes') {
    return '${l10n.challengeText('Expected shift duration')}  ${((value as num).round() / 60).toStringAsFixed(1)} ${l10n.challengeText('hours')}';
  }
  if (key == 'blockMinutes' || key == 'resetFrequencyMinutes') {
    return '${_parameterLabel(l10n, key, unit)}  $value min';
  }
  if (const {
    'weatherOrdering',
    'notifications',
    'autoStartNext',
    'reminderPreference',
    'reminderEnabled',
  }.contains(key)) {
    final on = value.toString().toLowerCase() == 'enabled';
    return '${_parameterLabel(l10n, key, unit)}  ${l10n.challengeText(on ? 'On' : 'Off')}';
  }
  if (key == 'noAddedSugar') {
    return '${l10n.challengeText('No added sugar')}  ${l10n.challengeText('Confirmed')}';
  }
  final text = value.toString();
  final friendly =
      text.isEmpty ? l10n.challengeText('Not set') : _choiceLabel(l10n, text);
  return '${_parameterLabel(l10n, key, unit)}  $friendly';
}

bool _isVisibleParameter(MapEntry<String, Object?> entry) =>
    const {
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
      'windowStartHour',
      'preparationHour',
      'travelStartHour',
      'reviewHour',
      'blockMinutes',
      'resetFrequencyMinutes',
      'shiftStartMinutes',
      'shiftDurationMinutes',
    }.contains(entry.key) &&
    entry.value != null &&
    entry.value.toString().trim().isNotEmpty;

String _formatHour(BuildContext context, Object? value) {
  final hour = int.tryParse(value?.toString() ?? '');
  if (hour == null || hour < 0 || hour > 23) {
    return AppLocalizations.of(context).challengeText('Not set');
  }
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: hour, minute: 0),
  );
}
