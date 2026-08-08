import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/challenge_catalog.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/asset_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../presentation/app_refresh_presenter.dart';
import '../components/intake_ring.dart';
import '../components/recognition_moment.dart';
import '../components/hydrion_viewport.dart';
import '../components/voice_input_widget.dart';
import '../theme/hydrion_design.dart';

class HomeScreen extends StatefulWidget {
  final bool showRouteShortcuts;
  final Key? hydrationTargetKey;
  final Key? logTargetKey;
  final Key? historyTargetKey;

  const HomeScreen({
    super.key,
    this.showRouteShortcuts = true,
    this.hydrationTargetKey,
    this.logTargetKey,
    this.historyTargetKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedVolumeMl = 250;
  bool _isLogging = false;
  HydrationMetadata _pendingMetadata = const HydrationMetadata();
  Future<void> _logWater(int volumeMl) async {
    if (_isLogging) {
      return;
    }
    setState(() => _isLogging = true);
    final repository = context.read<HydrationRepository>();
    final settingsRepository = context.read<UserSettingsRepository>();
    final now = DateTime.now();
    final beforeMl = repository.totalForDay(now);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final volumeUnit =
        context.read<UserSettingsRepository>().settings.volumeUnit;
    var succeeded = false;
    try {
      await repository.addLog(
        volumeMl: volumeMl,
        timestamp: DateTime.now(),
        source: 'quick-add',
        metadata: _pendingMetadata,
      );
      succeeded = true;
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.waterNotLoggedRetry)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
          if (succeeded) _pendingMetadata = const HydrationMetadata();
        });
      }
    }
    if (!mounted || !succeeded) {
      return;
    }
    final goal = settingsRepository.settings.dailyGoalMl;
    final afterMl = repository.totalForDay(now);
    if (beforeMl < goal && afterMl >= goal) {
      final day = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await RecognitionMoment.showOnce(
        context,
        repository: settingsRepository,
        eventId: 'daily-goal:$day',
        message: l10n.dailyGoalReachedRecognition,
      );
      if (_goalStreakDays(repository, goal, now) >= 7 && mounted) {
        await RecognitionMoment.showOnce(
          context,
          repository: settingsRepository,
          eventId: 'hydration-streak:7',
          message: l10n.sevenDayStreakRecognition,
        );
      }
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          volumeUnit == HydrionVolumeUnit.milliliters
              ? l10n.loggedVolume(volumeMl: volumeMl)
              : l10n.loggedFormattedVolume(
                  amount: HydrationVolumeFormatter.format(
                    volumeMl,
                    volumeUnit,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final settings = context.watch<UserSettingsRepository>().settings;
    final hydrationRepository = context.watch<HydrationRepository>();
    final challengeRepository = context.watch<ChallengeRepository>();
    final now = DateTime.now();
    final todayMl = hydrationRepository.totalForDay(now);
    final targetMl = settings.dailyGoalMl;
    final percent = targetMl <= 0 ? 0.0 : (todayMl / targetMl * 100);
    final remainingMl = math.max(0, targetMl - todayMl);
    final todayLogs = hydrationRepository.fetch(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 1),
    );
    final hydrationStatus = _hydrationStatus(
      l10n,
      hydrationPercent: percent,
      entryCount: todayLogs.length,
      now: now,
      mostRecentLog: todayLogs.isEmpty ? null : todayLogs.first,
      remainingMl: remainingMl,
      containerSizeMl: settings.usableContainerSizeMl,
      volumeUnit: settings.volumeUnit,
    );
    final profileAvatar = HydrionAvatarManifest.byId(settings.avatarId);
    final progress = (percent / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        key: const Key('home-appbar'),
        toolbarHeight: HydrionViewport.headerHeight(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydrion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              _greeting(l10n, settings, now),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('home-settings-action'),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings),
          ),
          PopupMenuButton<String>(
            key: const Key('home-avatar-menu'),
            tooltip: l10n.profileMenu,
            icon: CircleAvatar(
              backgroundImage: AssetImage(profileAvatar.assetPath),
              radius: 18,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
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
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text(l10n.viewProfile)),
              PopupMenuItem(
                value: 'settings',
                child: Text(l10n.settingsTitle),
              ),
              PopupMenuItem(value: 'support', child: Text(l10n.support)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        key: const Key('home-refresh-indicator'),
        onRefresh: () => refreshHydrionData(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: HydrionViewport.scrollPadding(
            context,
            top: 16,
            bottom: 24,
            includeSystemBottom: false,
          ),
          children: [
            _HeroHydrationScene(
              targetKey: widget.hydrationTargetKey,
              avatar: profileAvatar,
              statusText: hydrationStatus,
              consumedMl: todayMl,
              targetMl: targetMl,
              remainingMl: remainingMl,
              progress: progress,
              settings: settings,
            ),
            const SizedBox(height: 16),
            _QuickLogPanel(
              logTargetKey: widget.logTargetKey,
              title: l10n.logHydration,
              logLabel: settings.volumeUnit == HydrionVolumeUnit.milliliters
                  ? l10n.logVolume(volumeMl: _selectedVolumeMl)
                  : '${l10n.logHydration} ${HydrationVolumeFormatter.format(_selectedVolumeMl, settings.volumeUnit)}',
              selectedVolumeMl: _selectedVolumeMl,
              defaultContainerSizeMl: settings.usableContainerSizeMl,
              volumeUnit: settings.volumeUnit,
              onVolumeChanged: (value) =>
                  setState(() => _selectedVolumeMl = value),
              onLog: () => _logWater(_selectedVolumeMl),
              historyTargetKey: widget.historyTargetKey,
              onHistory: () => Navigator.of(context).pushNamed('/log'),
            ),
            if (challengeRepository.activeChallenges.any((challenge) =>
                challenge.id == 'temperature-roulette' ||
                challenge.id == 'around-the-world-infusion-week')) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('home-challenge-context'),
                onPressed: () => _editChallengeContext(challengeRepository),
                icon: const Icon(Icons.tune),
                label: Text(_pendingMetadata.isEmpty
                    ? l10n.addChallengeDetails
                    : l10n.challengeDetailsAdded),
              ),
              Text(
                l10n.challengeDetailsHelp,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            _TodayMomentumGrid(
              entryCount: todayLogs.length,
              challengeRepository: challengeRepository,
              targetMl: targetMl,
            ),
            const SizedBox(height: 16),
            _HomeLifestyleMoment(settings: settings),
            if (widget.showRouteShortcuts) ...[
              const SizedBox(height: 16),
              _LegacyRouteShortcuts(capabilities: capabilities),
            ],
          ],
        ),
      ),
      floatingActionButton: capabilities.voiceInput
          ? VoiceInputWidget(
              onCommandParsed: (command) {
                final intent = command['intent'] ?? 'unknown_command';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.voiceIntent(intent: intent))),
                );
              },
            )
          : null,
    );
  }

  Future<void> _editChallengeContext(
    ChallengeRepository challengeRepository,
  ) async {
    final l10n = AppLocalizations.of(context);
    final temperature =
        challengeRepository.activeChallengeFor('temperature-roulette');
    final infusion = challengeRepository
        .activeChallengeFor('around-the-world-infusion-week');
    final today = DateTime.now();
    var selectedTemperature = _pendingMetadata.temperatureStyle ??
        (temperature == null
            ? null
            : challengeRepository.temperatureForDay(temperature.id, today));
    var selectedInfusion = _pendingMetadata.infusionTheme ??
        (infusion == null
            ? null
            : challengeRepository.infusionThemeForDay(infusion.id, today));
    var noAddedSugar = _pendingMetadata.noAddedSugar ?? false;
    final metadata = await showDialog<HydrationMetadata>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.challengeDetailsTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (temperature != null)
                  DropdownButtonFormField<String>(
                    key: const Key('home-temperature-context'),
                    initialValue: selectedTemperature,
                    decoration:
                        InputDecoration(labelText: l10n.temperatureStyle),
                    items: [
                      DropdownMenuItem(
                        value: 'Cool',
                        child: Text(l10n.temperatureCool),
                      ),
                      DropdownMenuItem(
                        value: 'Room temperature',
                        child: Text(l10n.temperatureRoom),
                      ),
                      DropdownMenuItem(
                        value: 'Comfortably warm',
                        child: Text(l10n.temperatureWarm),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selectedTemperature = value),
                  ),
                if (infusion != null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('home-infusion-context'),
                    initialValue: selectedInfusion,
                    decoration: InputDecoration(labelText: l10n.infusionTheme),
                    onChanged: (value) => selectedInfusion = value.trim(),
                  ),
                  CheckboxListTile(
                    key: const Key('home-no-added-sugar-context'),
                    contentPadding: EdgeInsets.zero,
                    value: noAddedSugar,
                    title: Text(l10n.noAddedSugar),
                    onChanged: (value) => setDialogState(
                      () => noAddedSugar = value ?? false,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('home-save-challenge-context'),
              onPressed: () => Navigator.pop(
                dialogContext,
                HydrationMetadata(
                  temperatureStyle: selectedTemperature,
                  infusionTheme: selectedInfusion,
                  noAddedSugar: infusion == null ? null : noAddedSugar,
                ),
              ),
              child: Text(l10n.useDetails),
            ),
          ],
        ),
      ),
    );
    if (metadata != null && mounted) {
      setState(() => _pendingMetadata = metadata);
    }
  }
}

class _HomeLifestyleMoment extends StatelessWidget {
  final UserSettings settings;

  const _HomeLifestyleMoment({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scene = HydrionLifestyleArtResolver.sceneFor(
      surface: HydrionLifestyleSurface.homePrimary,
      sex: settings.sex,
    );
    return HydrionSurface(
      key: const Key('home-lifestyle-moment'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final art = SizedBox(
            width: 96,
            height: 112,
            child: Image.asset(
              scene.assetPath,
              key: const Key('home-profile-art'),
              fit: BoxFit.contain,
              cacheWidth: 256,
              semanticLabel:
                  AppLocalizations.of(context).sceneDescription(scene),
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.routineFitsDay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(l10n.routineFitsDayBody),
            ],
          );
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.4) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: art),
                const SizedBox(height: 10),
                copy,
              ],
            );
          }
          return Row(
            children: [
              art,
              const SizedBox(width: 14),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _HeroHydrationScene extends StatelessWidget {
  final Key? targetKey;
  final HydrionAvatar avatar;
  final String statusText;
  final int consumedMl;
  final int targetMl;
  final int remainingMl;
  final double progress;
  final UserSettings settings;

  const _HeroHydrationScene({
    this.targetKey,
    required this.avatar,
    required this.statusText,
    required this.consumedMl,
    required this.targetMl,
    required this.remainingMl,
    required this.progress,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (progress * 100).round();
    final remainingLabel = HydrationVolumeFormatter.format(
      remainingMl,
      settings.volumeUnit,
    );
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KeyedSubtree(
                        key: targetKey,
                        child: Text(
                          _hydrationStatusTitle(l10n, consumedMl, targetMl),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill('$percent%'),
                          _HeroPill(l10n.amountLeft(amount: remainingLabel)),
                          _HeroPill(
                            settings.weatherAdjustedGoalActive
                                ? l10n.weatherAdjusted
                                : l10n.standardGoalLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipOval(
                  child: SizedBox.square(
                    dimension: 116,
                    child: Image.asset(
                      avatar.assetPath,
                      key: const Key('home-logo'),
                      fit: BoxFit.cover,
                      semanticLabel: avatar.displayName,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(320.0, constraints.maxWidth);
                  return HydrationProgressGauge(
                    consumedMl: consumedMl.toDouble(),
                    targetMl: targetMl.toDouble(),
                    volumeUnit: settings.volumeUnit,
                    width: width,
                    height: 178,
                    onDarkBackground: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogPanel extends StatelessWidget {
  final String title;
  final String logLabel;
  final int selectedVolumeMl;
  final int? defaultContainerSizeMl;
  final HydrionVolumeUnit volumeUnit;
  final ValueChanged<int> onVolumeChanged;
  final VoidCallback onLog;
  final VoidCallback onHistory;
  final Key? historyTargetKey;
  final Key? logTargetKey;

  const _QuickLogPanel({
    required this.title,
    required this.logLabel,
    required this.selectedVolumeMl,
    required this.defaultContainerSizeMl,
    required this.volumeUnit,
    required this.onVolumeChanged,
    required this.onLog,
    required this.onHistory,
    this.historyTargetKey,
    this.logTargetKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = <int>{
      150,
      250,
      350,
      500,
      750,
      1000,
      if (defaultContainerSizeMl case final amount?) amount,
    }.toList()
      ..sort();
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              KeyedSubtree(
                key: historyTargetKey,
                child: TextButton.icon(
                  key: const Key('home-log-history'),
                  onPressed: onHistory,
                  icon: const Icon(Icons.history),
                  label: Text(l10n.history),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final amount in favorites)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('quick-volume-$amount'),
                      selected: selectedVolumeMl == amount,
                      label: Text(
                        HydrationVolumeFormatter.format(amount, volumeUnit),
                      ),
                      onSelected: (_) => onVolumeChanged(amount),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            defaultContainerSizeMl == null
                ? l10n.noReusableContainerSaved
                : l10n.savedContainerHelp(
                    amount: HydrationVolumeFormatter.format(
                      defaultContainerSizeMl!,
                      volumeUnit,
                    ),
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const Key('volume-picker'),
            initialValue: selectedVolumeMl,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.customAmount,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: favorites
                .map(
                  (amount) => DropdownMenuItem<int>(
                    value: amount,
                    child: Text(
                      HydrationVolumeFormatter.format(amount, volumeUnit),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onVolumeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: KeyedSubtree(
              key: logTargetKey,
              child: FilledButton.icon(
                key: const Key('log-water-button'),
                onPressed: onLog,
                icon: const Icon(Icons.water_drop),
                label: Text(logLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMomentumGrid extends StatelessWidget {
  final int entryCount;
  final ChallengeRepository challengeRepository;
  final int targetMl;

  const _TodayMomentumGrid({
    required this.entryCount,
    required this.challengeRepository,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challenge = challengeRepository.activeChallenge;
    final catalogChallenge = challenge == null
        ? HydrionChallengeCatalog.byId('bottle-bingo')
        : HydrionChallengeCatalog.byId(challenge.id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 430;
        final children = [
          _MiniModule(
            icon: Icons.bolt,
            title: l10n.momentum,
            value: entryCount == 0
                ? l10n.firstLogWaiting
                : l10n.logCount(count: entryCount),
            body: entryCount == 0
                ? l10n.momentumEmptyBody
                : l10n.momentumDataBody,
          ),
          _MiniModule(
            icon: Icons.emoji_events_outlined,
            title:
                challenge == null ? l10n.challengePick : l10n.activeChallenge,
            value: catalogChallenge.name,
            body: challenge == null
                ? l10n.bottleBingoReady
                : l10n.activeChallengeGentle,
          ),
        ];
        if (!twoColumns) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MiniModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String body;

  const _MiniModule({
    required this.icon,
    required this.title,
    required this.value,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill(this.label);

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

class _LegacyRouteShortcuts extends StatelessWidget {
  final AppCapabilities capabilities;

  const _LegacyRouteShortcuts({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _RouteButton(
            label: l10n.progress, icon: Icons.insights, route: '/analytics'),
        _RouteButton(
            label: l10n.logHistory, icon: Icons.list_alt, route: '/log'),
        _RouteButton(
            label: l10n.challengesTitle,
            icon: Icons.emoji_events,
            route: '/challenges'),
        if (capabilities.osNotifications)
          _RouteButton(
            label: l10n.remindersTitle,
            icon: Icons.notifications_none,
            route: '/reminders',
          ),
      ],
    );
  }
}

class _RouteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _RouteButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: Key('route-$route'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}

int _goalStreakDays(HydrationRepository repository, int goalMl, DateTime now) {
  var streak = 0;
  for (var offset = 0; offset < 365; offset++) {
    final day = DateTime(now.year, now.month, now.day - offset);
    if (repository.totalForDay(day) < goalMl) break;
    streak++;
  }
  return streak;
}

String _greeting(
  AppLocalizations l10n,
  UserSettings settings,
  DateTime now,
) {
  final name = settings.nickname?.trim();
  final displayName =
      name == null || name.isEmpty ? l10n.greetingFallbackName : name;
  if (now.hour < 12) return l10n.greetingMorning(name: displayName);
  if (now.hour < 18) return l10n.greetingAfternoon(name: displayName);
  return l10n.greetingEvening(name: displayName);
}

String _hydrationStatus(
  AppLocalizations l10n, {
  required double hydrationPercent,
  required int entryCount,
  required DateTime now,
  required HydrationLog? mostRecentLog,
  required int remainingMl,
  required int? containerSizeMl,
  required HydrionVolumeUnit volumeUnit,
}) {
  final hydration = hydrationPercent.clamp(0.0, 100.0);
  if (hydration >= 100) return l10n.homeAdviceGoalReached;

  if (mostRecentLog != null &&
      now.difference(mostRecentLog.timestamp).abs() <=
          const Duration(minutes: 30)) {
    return l10n.recentLogCounted(
      amount: HydrationVolumeFormatter.format(
        mostRecentLog.volumeMl,
        volumeUnit,
      ),
    );
  }
  if (hydration >= 85) return l10n.homeAdviceStrong;
  if (hydration >= 65) return l10n.homeAdviceClose;

  if (entryCount == 0) {
    return now.hour < 12 ? l10n.homeAdviceStart : l10n.noWaterLoggedToday;
  }

  final remaining = HydrationVolumeFormatter.format(remainingMl, volumeUnit);
  if (containerSizeMl == null) {
    return l10n.todayLogSummary(count: entryCount, remaining: remaining);
  }
  return l10n.todayLogSummaryWithContainer(
    count: entryCount,
    remaining: remaining,
    container: HydrationVolumeFormatter.format(containerSizeMl, volumeUnit),
  );
}

String _hydrationStatusTitle(
  AppLocalizations l10n,
  int consumedMl,
  int targetMl,
) {
  if (targetMl > 0 && consumedMl >= targetMl) return l10n.goalCompleted;
  if (consumedMl == 0) return l10n.noHydrationLoggedToday;
  return l10n.todaysHydration;
}
