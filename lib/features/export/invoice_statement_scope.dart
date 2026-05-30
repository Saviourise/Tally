import '../../data/models/entry.dart';

String invoiceStatementMonthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

DateTime invoiceCarryForwardStartForSentMonth({
  required DateTime answeredAt,
  required bool hasLoggedForAnsweredDay,
}) {
  final normalized = DateTime(
    answeredAt.year,
    answeredAt.month,
    answeredAt.day,
  );
  return normalized.add(
    Duration(days: hasLoggedForAnsweredDay ? 1 : 0),
  );
}

List<Entry> buildInvoiceStatementEntries({
  required DateTime month,
  required List<Entry> monthEntries,
  required List<Entry> previousMonthEntries,
  required Map<String, String> invoiceCarryForwardStartByMonth,
}) {
  final normalizedMonth = DateTime(month.year, month.month, 1);
  final previousMonth = DateTime(
    normalizedMonth.year,
    normalizedMonth.month - 1,
    1,
  );
  final currentMonthKey = invoiceStatementMonthKey(normalizedMonth);
  final previousMonthKey = invoiceStatementMonthKey(previousMonth);
  final currentCarryForwardStart = parseInvoiceCarryForwardStart(
    invoiceCarryForwardStartByMonth[currentMonthKey],
  );
  final previousCarryForwardStart = parseInvoiceCarryForwardStart(
    invoiceCarryForwardStartByMonth[previousMonthKey],
  );

  final statementEntries = <Entry>[
    if (previousCarryForwardStart != null)
      ...previousMonthEntries.where(
        (entry) => !entry.date.isBefore(previousCarryForwardStart),
      ),
    ...monthEntries.where(
      (entry) =>
          currentCarryForwardStart == null ||
          entry.date.isBefore(currentCarryForwardStart),
    ),
  ];
  statementEntries.sort((a, b) => a.date.compareTo(b.date));
  return statementEntries;
}

DateTime? parseInvoiceCarryForwardStart(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
