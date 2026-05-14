import '../data/models/entry.dart';
import 'formatters.dart';

/// Tally's pay rule (v1):
///   - Weekday (Mon–Fri): each day is independent.
///       hours >= fullDayHours       → full-day pay
///       0 < hours < fullDayHours    → half of full-day pay
///       hours == 0                  → 0
///   - Weekend (Sat + Sun): treated as ONE combined day.
///       combinedHours >= fullDayHours → full-day pay (shared across Sat+Sun)
///       0 < combinedHours < fullDayHours → half-day pay (shared across Sat+Sun)
///       combinedHours == 0           → 0
///
/// All returned values pass through [roundMoney] (3dp ceiling).
class PayCalc {
  PayCalc._();

  /// Per-day pay for a *weekday*. Don't use for Sat/Sun — use [entryPay] or
  /// [_weekendPay] instead so weekend pooling is respected.
  static double dayPay({
    required int totalMinutes,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    if (totalMinutes <= 0) return 0;
    final thresholdMinutes = fullDayHours * 60;
    if (totalMinutes >= thresholdMinutes) return roundMoney(hourlyFullDayPay);
    return roundMoney(hourlyFullDayPay / 2.0);
  }

  /// Combined Saturday + Sunday pay.
  static double _weekendPay({
    required int combinedMinutes,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    if (combinedMinutes <= 0) return 0;
    final thresholdMinutes = fullDayHours * 60;
    if (combinedMinutes >= thresholdMinutes) return roundMoney(hourlyFullDayPay);
    return roundMoney(hourlyFullDayPay / 2.0);
  }

  /// Pay attributable to a single entry. Weekday entries are independent.
  /// Weekend entries pool with their paired day and the weekend pay is split
  /// proportionally by minutes so the per-day totals still sum to the right
  /// monthly total.
  ///
  /// [companionMinutes] is the paired weekend day's minutes (Sat for a Sun
  /// entry, Sun for a Sat entry). Pass 0 if the paired day has no entry.
  static double entryPay({
    required int weekday,
    required int totalMinutes,
    required int companionMinutes,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    if (totalMinutes <= 0) return 0;
    if (weekday <= 5) {
      return dayPay(
        totalMinutes: totalMinutes,
        hourlyFullDayPay: hourlyFullDayPay,
        fullDayHours: fullDayHours,
      );
    }
    final combined = totalMinutes + companionMinutes;
    final weekend = _weekendPay(
      combinedMinutes: combined,
      hourlyFullDayPay: hourlyFullDayPay,
      fullDayHours: fullDayHours,
    );
    if (combined == 0) return 0;
    return roundMoney(weekend * (totalMinutes / combined));
  }

  /// Convenience: compute pay for an [entry] given the full month's entries.
  /// Looks up the weekend companion automatically.
  static double payForEntry({
    required Entry entry,
    required Iterable<Entry> monthEntries,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    final wd = entry.date.weekday;
    var companion = 0;
    if (wd > 5) {
      final pairedDate = wd == 6
          ? entry.date.add(const Duration(days: 1))
          : entry.date.subtract(const Duration(days: 1));
      final pairedId = Entry.idForDate(pairedDate);
      for (final e in monthEntries) {
        if (e.id == pairedId) {
          companion = e.totalMinutes;
          break;
        }
      }
    }
    return entryPay(
      weekday: wd,
      totalMinutes: entry.totalMinutes,
      companionMinutes: companion,
      hourlyFullDayPay: hourlyFullDayPay,
      fullDayHours: fullDayHours,
    );
  }

  /// Total pay across all entries with weekend pooling applied.
  static double sumEntries({
    required Iterable<Entry> entries,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    final byId = {for (final e in entries) e.id: e};
    final processed = <String>{};
    var total = 0.0;
    for (final e in entries) {
      if (processed.contains(e.id)) continue;
      processed.add(e.id);
      if (e.date.weekday <= 5) {
        total += dayPay(
          totalMinutes: e.totalMinutes,
          hourlyFullDayPay: hourlyFullDayPay,
          fullDayHours: fullDayHours,
        );
      } else {
        // Weekend: combine with pair
        final pairedDate = e.date.weekday == 6
            ? e.date.add(const Duration(days: 1))
            : e.date.subtract(const Duration(days: 1));
        final pairedId = Entry.idForDate(pairedDate);
        final paired = byId[pairedId];
        final combined = e.totalMinutes + (paired?.totalMinutes ?? 0);
        total += _weekendPay(
          combinedMinutes: combined,
          hourlyFullDayPay: hourlyFullDayPay,
          fullDayHours: fullDayHours,
        );
        if (paired != null) processed.add(pairedId);
      }
    }
    return roundMoney(total);
  }

  /// Preview pay for an in-progress log entry on [date] given [totalMinutes].
  /// The [monthEntries] list is used to look up the paired weekend day so the
  /// preview reflects the weekend rule.
  static double previewPay({
    required DateTime date,
    required int totalMinutes,
    required Iterable<Entry> monthEntries,
    required double hourlyFullDayPay,
    required int fullDayHours,
  }) {
    final wd = date.weekday;
    if (wd <= 5) {
      return dayPay(
        totalMinutes: totalMinutes,
        hourlyFullDayPay: hourlyFullDayPay,
        fullDayHours: fullDayHours,
      );
    }
    final pairedDate = wd == 6
        ? date.add(const Duration(days: 1))
        : date.subtract(const Duration(days: 1));
    final pairedId = Entry.idForDate(pairedDate);
    final today = DateTime(date.year, date.month, date.day);
    final todayId = Entry.idForDate(today);
    var companion = 0;
    for (final e in monthEntries) {
      if (e.id == pairedId && e.id != todayId) {
        companion = e.totalMinutes;
        break;
      }
    }
    return entryPay(
      weekday: wd,
      totalMinutes: totalMinutes,
      companionMinutes: companion,
      hourlyFullDayPay: hourlyFullDayPay,
      fullDayHours: fullDayHours,
    );
  }

  /// Returns true if this day's logged hours qualify for the full-day rate,
  /// considering weekend pooling.
  static bool qualifiesAsFullDay({
    required DateTime date,
    required int totalMinutes,
    required Iterable<Entry> monthEntries,
    required int fullDayHours,
  }) {
    final wd = date.weekday;
    final thresholdMinutes = fullDayHours * 60;
    if (wd <= 5) return totalMinutes >= thresholdMinutes;
    final pairedDate = wd == 6
        ? date.add(const Duration(days: 1))
        : date.subtract(const Duration(days: 1));
    final pairedId = Entry.idForDate(pairedDate);
    final todayId = Entry.idForDate(DateTime(date.year, date.month, date.day));
    var companion = 0;
    for (final e in monthEntries) {
      if (e.id == pairedId && e.id != todayId) {
        companion = e.totalMinutes;
        break;
      }
    }
    return (totalMinutes + companion) >= thresholdMinutes;
  }
}
