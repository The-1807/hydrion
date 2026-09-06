import '../repositories/hydration_repository.dart';

enum HydrationReportFrequency { weekly, monthly, quarterly, yearly }

class HydrationReportPeriod {
  final HydrationReportFrequency frequency;
  final DateTime start;
  final DateTime endExclusive;

  const HydrationReportPeriod(
      {required this.frequency,
      required this.start,
      required this.endExclusive});

  DateTime get end =>
      DateTime(endExclusive.year, endExclusive.month, endExclusive.day - 1);
  int get dayCount => calendarDays(start, endExclusive).length;

  /// Rolling windows end on [localToday], inclusively. Month-based windows use
  /// a same-day anchor clamped to the destination month's last valid day, then
  /// begin on the following day. This produces N complete rolling months.
  static HydrationReportPeriod endingOn(
      HydrationReportFrequency frequency, DateTime localToday) {
    final end = localDate(localToday);
    final start = switch (frequency) {
      HydrationReportFrequency.weekly =>
        DateTime(end.year, end.month, end.day - 6),
      HydrationReportFrequency.monthly =>
        nextLocalDate(addMonthsClamped(end, -1)),
      HydrationReportFrequency.quarterly =>
        nextLocalDate(addMonthsClamped(end, -3)),
      HydrationReportFrequency.yearly =>
        nextLocalDate(addMonthsClamped(end, -12)),
    };
    return HydrationReportPeriod(
        frequency: frequency, start: start, endExclusive: nextLocalDate(end));
  }
}

DateTime localDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime nextLocalDate(DateTime value) =>
    DateTime(value.year, value.month, value.day + 1);

DateTime addMonthsClamped(DateTime value, int months) {
  final monthIndex = value.year * 12 + value.month - 1 + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex.remainder(12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, value.day.clamp(1, lastDay));
}

class HydrationReportTargetChange {
  final DateTime effectiveDate;
  final int targetMl;
  const HydrationReportTargetChange(
      {required this.effectiveDate, required this.targetMl});
}

class HydrationReportDay {
  final DateTime date;
  final int? recordedMl;
  final int? targetMl;
  const HydrationReportDay(
      {required this.date, required this.recordedMl, required this.targetMl});
  bool get tracked => recordedMl != null;
  bool get targetMet =>
      targetMl != null && recordedMl != null && recordedMl! >= targetMl!;
}

enum HydrationGraphResolution { daily, weekly, monthly }

enum HydrationTargetCoverage { complete, partial, unavailable }

class HydrationGraphPoint {
  final DateTime start;
  final DateTime end;
  final int? recordedMl;
  final int trackedDays;
  final int? targetMl;
  final HydrationTargetCoverage targetCoverage;
  const HydrationGraphPoint({
    required this.start,
    required this.end,
    required this.recordedMl,
    required this.trackedDays,
    required this.targetMl,
    required this.targetCoverage,
  });
}

class HydrationReportGraph {
  final HydrationGraphResolution resolution;
  final List<HydrationGraphPoint> points;
  const HydrationReportGraph({required this.resolution, required this.points});
  int get recordedTotalMl =>
      points.fold(0, (sum, point) => sum + (point.recordedMl ?? 0));
}

class HydrationReport {
  final HydrationReportPeriod period;
  final DateTime generatedAt;
  final String displayLabel;
  final List<HydrationReportDay> days;
  final HydrationReportGraph graph;
  const HydrationReport({
    required this.period,
    required this.generatedAt,
    required this.displayLabel,
    required this.days,
    required this.graph,
  });
  int get totalRecordedMl =>
      days.fold(0, (sum, day) => sum + (day.recordedMl ?? 0));
  int get trackedDays => days.where((day) => day.tracked).length;
  int get averageRecordedMl =>
      trackedDays == 0 ? 0 : (totalRecordedMl / trackedDays).round();
  int get daysTargetMet => days.where((day) => day.targetMet).length;
  int get daysWithKnownTarget =>
      days.where((day) => day.targetMl != null).length;
  double get trackedPercent =>
      days.isEmpty ? 0 : trackedDays * 100 / days.length;
  double get targetMetPercent =>
      daysWithKnownTarget == 0 ? 0 : daysTargetMet * 100 / daysWithKnownTarget;
  bool get isEmpty => trackedDays == 0;
  bool get isPartial => generatedAt.isBefore(period.endExclusive);
}

class HydrationReportCalculator {
  const HydrationReportCalculator();
  HydrationReport calculate({
    required HydrationReportPeriod period,
    required List<HydrationLog> logs,
    required DateTime generatedAt,
    required String displayLabel,
    List<HydrationReportTargetChange> targetChanges = const [],
  }) {
    final totals = <String, int>{};
    for (final log in logs) {
      final timestamp = log.timestamp.toLocal();
      if (timestamp.isBefore(period.start) ||
          !timestamp.isBefore(period.endExclusive)) {
        continue;
      }
      final key = localDateKey(timestamp);
      totals[key] = ((totals[key] ?? 0) + log.volumeMl).clamp(0, 0x7fffffff);
    }
    final changes = targetChanges
        .where((change) => change.targetMl > 0)
        .map((change) => HydrationReportTargetChange(
              effectiveDate: localDate(change.effectiveDate),
              targetMl: change.targetMl,
            ))
        .toList(growable: false)
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    final days = calendarDays(period.start, period.endExclusive)
        .map((date) => HydrationReportDay(
              date: date,
              recordedMl: totals[localDateKey(date)],
              targetMl: _targetFor(date, changes),
            ))
        .toList(growable: false);
    final graph = buildHydrationReportGraph(period.frequency, days);
    return HydrationReport(
      period: period,
      generatedAt: generatedAt,
      displayLabel:
          displayLabel.trim().isEmpty ? 'Hydrion user' : displayLabel.trim(),
      days: days,
      graph: graph,
    );
  }
}

HydrationReportGraph buildHydrationReportGraph(
    HydrationReportFrequency frequency, List<HydrationReportDay> days) {
  final resolution = switch (frequency) {
    HydrationReportFrequency.weekly ||
    HydrationReportFrequency.monthly =>
      HydrationGraphResolution.daily,
    HydrationReportFrequency.quarterly => HydrationGraphResolution.weekly,
    HydrationReportFrequency.yearly => HydrationGraphResolution.monthly,
  };
  final groups = <List<HydrationReportDay>>[];
  if (resolution == HydrationGraphResolution.daily) {
    groups.addAll(days.map((day) => [day]));
  } else if (resolution == HydrationGraphResolution.weekly) {
    for (var index = 0; index < days.length; index += 7) {
      groups.add(days.skip(index).take(7).toList(growable: false));
    }
  } else {
    for (final day in days) {
      if (groups.isEmpty ||
          groups.last.last.date.year != day.date.year ||
          groups.last.last.date.month != day.date.month) {
        groups.add([day]);
      } else {
        groups.last.add(day);
      }
    }
  }
  return HydrationReportGraph(
      resolution: resolution,
      points: groups.map(_graphPoint).toList(growable: false));
}

HydrationGraphPoint _graphPoint(List<HydrationReportDay> days) {
  final tracked = days.where((day) => day.tracked).toList(growable: false);
  final knownTargets =
      days.where((day) => day.targetMl != null).toList(growable: false);
  final coverage = knownTargets.isEmpty
      ? HydrationTargetCoverage.unavailable
      : knownTargets.length == days.length
          ? HydrationTargetCoverage.complete
          : HydrationTargetCoverage.partial;
  return HydrationGraphPoint(
    start: days.first.date,
    end: days.last.date,
    recordedMl: tracked.isEmpty
        ? null
        : tracked.fold<int>(0, (sum, day) => sum + day.recordedMl!),
    trackedDays: tracked.length,
    targetMl: coverage == HydrationTargetCoverage.complete
        ? knownTargets.fold<int>(0, (sum, day) => sum + day.targetMl!)
        : null,
    targetCoverage: coverage,
  );
}

int? _targetFor(DateTime date, List<HydrationReportTargetChange> changes) {
  int? result;
  for (final change in changes) {
    if (change.effectiveDate.isAfter(date)) break;
    result = change.targetMl;
  }
  return result;
}

List<DateTime> calendarDays(DateTime start, DateTime endExclusive) {
  final result = <DateTime>[];
  var cursor = DateTime(start.year, start.month, start.day);
  while (cursor.isBefore(endExclusive)) {
    result.add(cursor);
    cursor = nextLocalDate(cursor);
  }
  return result;
}

String localDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
