import 'package:flutter/material.dart';

import '../../domain/bottle_bingo.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../components/intake_ring.dart';

class ChallengeHistoryItem {
  final String description;
  final DateTime timestamp;

  const ChallengeHistoryItem(
      {required this.description, required this.timestamp});
}

class ChallengeHistoryPresenter {
  const ChallengeHistoryPresenter._();

  static List<ChallengeHistoryItem> present({
    required JoinedChallenge challenge,
    required Iterable<HydrationLog> hydrationLogs,
    required HydrionVolumeUnit unit,
  }) {
    final logsByAction = <String, HydrationLog>{
      for (final log in hydrationLogs)
        if (log.actionId != null) log.actionId!: log,
    };
    final items = <ChallengeHistoryItem>[
      for (final action in challenge.completedActionIds)
        _actionItem(challenge, action, logsByAction[action], unit),
    ];

    if (challenge.id == 'bottle-bingo') {
      final board = BottleBingoBoard.forInstance(
          challenge.joinedAt.microsecondsSinceEpoch);
      final recordedIndexes = <int>{};
      for (final action in challenge.completedActionIds) {
        final index = int.tryParse(
            RegExp(r'tile-(\d+)$').firstMatch(action)?.group(1) ?? '');
        if (index != null) {
          recordedIndexes.add(index);
        }
      }
      for (final index in challenge.bottleBingoCompletedTiles) {
        if (index < 0 ||
            index >= board.tiles.length ||
            recordedIndexes.contains(index)) {
          continue;
        }
        items.add(ChallengeHistoryItem(
          description: 'Completed ${board.tiles[index].title}',
          timestamp: challenge.joinedAt,
        ));
      }
      final completed = <int>{
        BottleBingoBoard.centerIndex,
        ...challenge.bottleBingoCompletedTiles,
        ...recordedIndexes
      };
      for (final line in board.completedLines(completed)) {
        items.add(ChallengeHistoryItem(
          description: 'Completed Bottle Bingo line ${line + 1}',
          timestamp: challenge.joinedAt,
        ));
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(items);
  }

  static ChallengeHistoryItem _actionItem(
    JoinedChallenge challenge,
    String action,
    HydrationLog? log,
    HydrionVolumeUnit unit,
  ) {
    final timestamp = log?.timestamp ?? _dateFrom(action) ?? challenge.joinedAt;
    final amount = log == null
        ? ''
        : ' · ${HydrationVolumeFormatter.format(log.volumeMl, unit)}';
    String description;
    switch (challenge.id) {
      case 'temperature-roulette':
        final schedule = challenge.parameters['temperatureSchedule'];
        final style = schedule is List && schedule.isNotEmpty
            ? schedule[
                    _dayIndex(challenge.joinedAt, timestamp) % schedule.length]
                .toString()
            : 'assigned temperature';
        description = 'Logged a $style drink$amount';
      case 'around-the-world-infusion-week':
        const themes = [
          'Citrus',
          'Berry',
          'Herbal',
          'Cucumber',
          'Tropical',
          'Spice',
          'Favorite'
        ];
        final theme =
            themes[_dayIndex(challenge.joinedAt, timestamp) % themes.length];
        description = 'Tried the $theme infusion$amount';
      case 'pomodoro-sip':
        final session = RegExp(r'session-(\d+)').firstMatch(action)?.group(1);
        description = session == null
            ? 'Completed a Pomodoro focus session$amount'
            : 'Completed Pomodoro session $session$amount';
      case 'eat-your-water-day':
        final meal = _friendlyValue(challenge.parameters['meal'], 'meal');
        final food =
            _friendlyValue(challenge.parameters['food'], 'water-rich food');
        description = 'Added $food to $meal';
      case 'plant-twin-challenge':
        final cue =
            _friendlyValue(challenge.parameters['cue'], 'plant-care cue');
        description = 'Completed the $cue';
      case 'bottle-bingo':
        final tile = _bingoTile(action, challenge.joinedAt);
        description = log == null
            ? 'Completed ${tile?.title ?? 'a Bottle Bingo tile'}'
            : 'Logged ${tile?.title ?? 'a Bottle Bingo drink'}$amount';
      default:
        description = log == null
            ? 'Completed a challenge task'
            : 'Logged a challenge drink$amount';
    }
    return ChallengeHistoryItem(description: description, timestamp: timestamp);
  }

  static BingoTileDefinition? _bingoTile(String action, DateTime joinedAt) {
    final board = BottleBingoBoard.forInstance(joinedAt.microsecondsSinceEpoch);
    final index =
        int.tryParse(RegExp(r'tile-(\d+)$').firstMatch(action)?.group(1) ?? '');
    if (index != null && index >= 0 && index < board.tiles.length) {
      return board.tiles[index];
    }
    for (final tile in board.tiles) {
      if (action.endsWith(':${tile.id}') || action.endsWith(tile.id)) {
        return tile;
      }
    }
    return null;
  }

  static int _dayIndex(DateTime start, DateTime timestamp) {
    final first = DateTime(start.year, start.month, start.day);
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return day.difference(first).inDays.clamp(0, 1000000);
  }

  static DateTime? _dateFrom(String action) {
    final match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(action);
    if (match == null) return null;
    return DateTime.tryParse(
        '${match.group(1)}-${match.group(2)!.padLeft(2, '0')}-${match.group(3)!.padLeft(2, '0')}');
  }

  static String _friendlyValue(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class ChallengeHistoryView extends StatelessWidget {
  final List<ChallengeHistoryItem> items;

  const ChallengeHistoryView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No challenge actions recorded yet.');
    }
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                Text(
                  '${localizations.formatMediumDate(item.timestamp)} · '
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(item.timestamp))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
