import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/models/entry.dart';
import 'package:tally/features/export/invoice_statement_scope.dart';

void main() {
  group('buildInvoiceStatementEntries', () {
    test('includes previous month carry-forward entries in next statement', () {
      final mayEntries = [
        _entry(DateTime(2026, 5, 18), 8),
        _entry(DateTime(2026, 5, 20), 8),
        _entry(DateTime(2026, 5, 27), 8),
      ];
      final juneEntries = [
        _entry(DateTime(2026, 6, 2), 8),
      ];

      final statementEntries = buildInvoiceStatementEntries(
        month: DateTime(2026, 6, 1),
        monthEntries: juneEntries,
        previousMonthEntries: mayEntries,
        invoiceCarryForwardStartByMonth: const {
          '2026-05': '2026-05-20T00:00:00.000',
        },
      );

      expect(
        statementEntries.map((entry) => entry.id).toList(),
        ['2026-05-20', '2026-05-27', '2026-06-02'],
      );
    });

    test('excludes current month entries on or after its carry-forward start', () {
      final juneEntries = [
        _entry(DateTime(2026, 6, 2), 8),
        _entry(DateTime(2026, 6, 12), 8),
        _entry(DateTime(2026, 6, 20), 8),
      ];

      final statementEntries = buildInvoiceStatementEntries(
        month: DateTime(2026, 6, 1),
        monthEntries: juneEntries,
        previousMonthEntries: const [],
        invoiceCarryForwardStartByMonth: const {
          '2026-06': '2026-06-20T00:00:00.000',
        },
      );

      expect(
        statementEntries.map((entry) => entry.id).toList(),
        ['2026-06-02', '2026-06-12'],
      );
    });
  });

  group('invoiceCarryForwardStartForSentMonth', () {
    test('keeps the answered day when that day is not logged yet', () {
      final carryForwardStart = invoiceCarryForwardStartForSentMonth(
        answeredAt: DateTime(2026, 5, 20, 14, 30),
        hasLoggedForAnsweredDay: false,
      );

      expect(carryForwardStart, DateTime(2026, 5, 20));
    });

    test('moves to the next day when the answered day is already logged', () {
      final carryForwardStart = invoiceCarryForwardStartForSentMonth(
        answeredAt: DateTime(2026, 5, 20, 14, 30),
        hasLoggedForAnsweredDay: true,
      );

      expect(carryForwardStart, DateTime(2026, 5, 21));
    });
  });
}

Entry _entry(DateTime date, int hours) => Entry(
  id: Entry.idForDate(date),
  date: DateTime(date.year, date.month, date.day),
  hours: hours,
  minutes: 0,
  source: 'test',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
