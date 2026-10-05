import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/time/local_date.dart';

void main() {
  group('LocalDate', () {
    test('fromDateTime keeps the value\'s own calendar fields', () {
      expect(LocalDate.fromDateTime(DateTime(2025, 3, 9, 23, 59)),
          LocalDate(2025, 3, 9));
      expect(LocalDate.fromDateTime(DateTime.utc(2025, 11, 2, 0, 1)),
          LocalDate(2025, 11, 2));
    });

    test('key keeps the stored yyyy-MM-dd format byte for byte', () {
      expect(LocalDate(2026, 7, 4).key, '2026-07-04');
      expect(LocalDate(987, 1, 9).key, '0987-01-09');
      expect(LocalDate(2026, 12, 31).toString(), '2026-12-31');
    });

    test('rejects dates that do not exist', () {
      expect(() => LocalDate(2025, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2025, 13, 1), throwsArgumentError);
      expect(LocalDate(2024, 2, 29).key, '2024-02-29');
    });

    test('addDays crosses month, year and leap boundaries', () {
      expect(LocalDate(2025, 12, 31).addDays(1), LocalDate(2026, 1, 1));
      expect(LocalDate(2024, 3, 1).addDays(-1), LocalDate(2024, 2, 29));
      expect(LocalDate(2025, 3, 1).addDays(-1), LocalDate(2025, 2, 28));
      expect(LocalDate(2025, 1, 31).addDays(30), LocalDate(2025, 3, 2));
      expect(LocalDate(2025, 1, 1).addDays(0), LocalDate(2025, 1, 1));
    });

    test('daysUntil counts civil days in both directions', () {
      expect(LocalDate(2025, 1, 1).daysUntil(LocalDate(2025, 1, 1)), 0);
      expect(LocalDate(2025, 1, 1).daysUntil(LocalDate(2026, 1, 1)), 365);
      expect(LocalDate(2024, 1, 1).daysUntil(LocalDate(2025, 1, 1)), 366);
      expect(LocalDate(2025, 3, 10).daysUntil(LocalDate(2025, 3, 8)), -2);
    });

    // America/New_York 2025: spring forward on 9 March (23-hour local day),
    // fall back on 2 November (25-hour local day). Civil arithmetic must not
    // see either transition.
    test('America/New_York DST transitions are exactly one civil day', () {
      expect(LocalDate(2025, 3, 9).daysUntil(LocalDate(2025, 3, 10)), 1);
      expect(LocalDate(2025, 3, 8).daysUntil(LocalDate(2025, 3, 10)), 2);
      expect(LocalDate(2025, 11, 2).daysUntil(LocalDate(2025, 11, 3)), 1);
      expect(LocalDate(2025, 11, 1).daysUntil(LocalDate(2025, 11, 3)), 2);
      expect(LocalDate(2025, 3, 10).addDays(-1), LocalDate(2025, 3, 9));
      expect(LocalDate(2025, 11, 3).addDays(-1), LocalDate(2025, 11, 2));
      // Local wall times on either side of the transitions map to their own
      // civil day whatever the host zone is.
      expect(
        LocalDate.fromDateTime(DateTime(2025, 3, 8, 7))
            .daysUntil(LocalDate.fromDateTime(DateTime(2025, 3, 10, 0, 30))),
        2,
      );
      expect(
        LocalDate.fromDateTime(DateTime(2025, 11, 1, 0, 0))
            .daysUntil(LocalDate.fromDateTime(DateTime(2025, 11, 2, 23, 30))),
        1,
      );
    });

    test('ordering and equality are civil', () {
      expect(LocalDate(2025, 3, 9).isBefore(LocalDate(2025, 3, 10)), isTrue);
      expect(LocalDate(2025, 3, 10).isAfter(LocalDate(2025, 3, 9)), isTrue);
      expect(LocalDate(2025, 3, 9).compareTo(LocalDate(2025, 3, 9)), 0);
      expect(LocalDate(2025, 3, 9).hashCode, LocalDate(2025, 3, 9).hashCode);
      expect({LocalDate(2025, 3, 9), LocalDate(2025, 3, 9)}, hasLength(1));
    });
  });
}
