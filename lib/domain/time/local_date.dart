/// A civil calendar date: a year, month and day with no time of day and no
/// time zone.
///
/// Arithmetic is done on the proleptic Gregorian calendar through UTC, so a
/// day is always exactly one step regardless of daylight-saving transitions
/// in the device's zone. Use this instead of `DateTime.difference().inDays`
/// or fixed 24-hour arithmetic whenever the question is "which calendar day"
/// or "how many calendar days apart".
///
/// This is the seed of the clock and calendar authority (blueprint K1); later
/// waves extend it rather than adding date helpers elsewhere.
final class LocalDate implements Comparable<LocalDate> {
  final int year;
  final int month;
  final int day;

  const LocalDate._(this.year, this.month, this.day);

  /// Creates a validated civil date. Throws [ArgumentError] for dates that do
  /// not exist, such as February 30.
  factory LocalDate(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('Invalid civil date: $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  /// The civil date shown by [value]'s own fields.
  ///
  /// A local [DateTime] yields its local calendar day and a UTC [DateTime]
  /// yields its UTC calendar day; no zone conversion is applied here.
  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate._(value.year, value.month, value.day);

  DateTime get _utcMidnight => DateTime.utc(year, month, day);

  /// The civil date [days] calendar days after this one (negative for
  /// earlier dates).
  LocalDate addDays(int days) {
    final shifted = DateTime.utc(year, month, day + days);
    return LocalDate._(shifted.year, shifted.month, shifted.day);
  }

  /// The number of calendar days from this date to [other]: positive when
  /// [other] is later, zero for the same date, negative when earlier.
  int daysUntil(LocalDate other) =>
      other._utcMidnight.difference(_utcMidnight).inDays;

  /// The stored `yyyy-MM-dd` key used by existing day-keyed records.
  String get key => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}
