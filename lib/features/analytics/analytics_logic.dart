import '../../core/pay_calc.dart';
import '../../data/models/entry.dart';

class MonthSummary {
  final int totalMinutes;
  final int daysLogged;
  final int fullDays;
  final int partialDays;
  final double entriesPay;

  const MonthSummary({
    required this.totalMinutes,
    required this.daysLogged,
    required this.fullDays,
    required this.partialDays,
    required this.entriesPay,
  });
}

MonthSummary summarize(
  List<Entry> entries, {
  required double hourlyFullDayPay,
  required int fullDayHours,
}) {
  // Total minutes + daysLogged are straightforward.
  var total = 0;
  for (final e in entries) {
    total += e.totalMinutes;
  }
  final daysLogged = entries.where((e) => e.totalMinutes > 0).length;

  // Full/partial counts now consider weekend pooling. For each entry, ask
  // whether it qualifies as a full day given its weekend pair.
  var full = 0;
  var partial = 0;
  for (final e in entries) {
    if (e.totalMinutes <= 0) continue;
    final isFull = PayCalc.qualifiesAsFullDay(
      date: e.date,
      totalMinutes: e.totalMinutes,
      monthEntries: entries,
      fullDayHours: fullDayHours,
    );
    if (isFull) {
      full++;
    } else {
      partial++;
    }
  }

  final pay = PayCalc.sumEntries(
    entries: entries,
    hourlyFullDayPay: hourlyFullDayPay,
    fullDayHours: fullDayHours,
  );

  return MonthSummary(
    totalMinutes: total,
    daysLogged: daysLogged,
    fullDays: full,
    partialDays: partial,
    entriesPay: pay,
  );
}

/// Project month-end earnings using the average pay per logged weekday so far.
({double projection, int weekdaysRemaining, double confidence}) projectMonthly({
  required List<Entry> monthEntries,
  required DateTime month,
  required double hourlyFullDayPay,
  required int fullDayHours,
}) {
  final now = DateTime.now();
  final inThisMonth = now.year == month.year && now.month == month.month;
  // Sum of weekdays in the month
  final firstDay = DateTime(month.year, month.month, 1);
  final nextMonth = DateTime(month.year, month.month + 1, 1);
  var totalWeekdays = 0;
  var remainingWeekdays = 0;
  for (var d = firstDay;
      d.isBefore(nextMonth);
      d = d.add(const Duration(days: 1))) {
    if (d.weekday >= 1 && d.weekday <= 5) {
      totalWeekdays++;
      if (inThisMonth && d.isAfter(DateTime(now.year, now.month, now.day))) {
        remainingWeekdays++;
      }
    }
  }
  final summary = summarize(monthEntries,
      hourlyFullDayPay: hourlyFullDayPay, fullDayHours: fullDayHours);
  final loggedWeekdays = monthEntries
      .where((e) => e.totalMinutes > 0 && e.date.weekday <= 5)
      .length;
  if (loggedWeekdays == 0) {
    return (
      projection: summary.entriesPay,
      weekdaysRemaining: remainingWeekdays,
      confidence: 0.0
    );
  }
  final avgPay = summary.entriesPay / loggedWeekdays;
  final projection = summary.entriesPay + (avgPay * remainingWeekdays);
  final confidence =
      (loggedWeekdays / totalWeekdays).clamp(0.0, 1.0).toDouble();
  return (
    projection: projection,
    weekdaysRemaining: remainingWeekdays,
    confidence: confidence
  );
}

({int currentStreak, int bestStreak}) computeStreaks(List<Entry> yearEntries) {
  final logged = <String>{
    for (final e in yearEntries)
      if (e.totalMinutes > 0) Entry.idForDate(e.date),
  };
  if (logged.isEmpty) return (currentStreak: 0, bestStreak: 0);

  // Current streak: walk backwards from today, counting only weekdays (Mon–Fri).
  // Today is a "grace day" — if it isn't logged yet, the streak still continues
  // from yesterday. Any other missed weekday breaks the streak.
  var current = 0;
  var d = DateTime.now();
  var firstWeekdayChecked = false;
  while (current < 366) {
    if (d.weekday > 5) {
      d = d.subtract(const Duration(days: 1));
      continue;
    }
    final isLogged = logged.contains(Entry.idForDate(d));
    if (isLogged) {
      current++;
    } else if (firstWeekdayChecked) {
      break; // missed a non-today weekday — streak ends
    }
    firstWeekdayChecked = true;
    d = d.subtract(const Duration(days: 1));
  }

  // Best streak this year. Walk through logged weekdays sorted oldest→newest.
  // Bridging weekends so Fri→Mon counts as consecutive.
  var best = 0;
  var run = 0;
  final sorted = yearEntries
      .where((e) => e.totalMinutes > 0 && e.date.weekday <= 5)
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toList()
    ..sort((a, b) => a.compareTo(b));
  DateTime? prev;
  for (final day in sorted) {
    if (prev == null) {
      run = 1;
    } else {
      var bridge = prev.add(const Duration(days: 1));
      while (bridge.weekday > 5) {
        bridge = bridge.add(const Duration(days: 1));
      }
      final isConsecutive = bridge.year == day.year &&
          bridge.month == day.month &&
          bridge.day == day.day;
      run = isConsecutive ? run + 1 : 1;
    }
    if (run > best) best = run;
    prev = day;
  }
  return (currentStreak: current, bestStreak: best);
}

/// Weekday patterns. Saturday and Sunday are bucketed together as a single
/// "Weekend" group identified by bucket index 6 (Mon–Fri = 1..5, Weekend = 6).
({int bestBucket, double bestAvgHours, double fullDayHitRate}) computeWeekdayPatterns(
  List<Entry> monthEntries, {
  required int fullDayMinutes,
}) {
  int bucket(int weekday) => weekday <= 5 ? weekday : 6;
  final byBucket = <int, List<int>>{};
  for (final e in monthEntries) {
    if (e.totalMinutes > 0) {
      byBucket.putIfAbsent(bucket(e.date.weekday), () => []).add(e.totalMinutes);
    }
  }
  if (byBucket.isEmpty) {
    return (bestBucket: 1, bestAvgHours: 0, fullDayHitRate: 0);
  }
  var bestBkt = 1;
  var bestAvg = 0.0;
  byBucket.forEach((b, list) {
    final avg = list.reduce((a, b) => a + b) / list.length / 60.0;
    if (avg > bestAvg) {
      bestAvg = avg;
      bestBkt = b;
    }
  });
  // Full-day hit rate over weekdays only (Mon–Fri).
  final weekdays = monthEntries
      .where((e) => e.date.weekday <= 5 && e.totalMinutes > 0);
  final fullHits =
      weekdays.where((e) => e.totalMinutes >= fullDayMinutes).length;
  final rate = weekdays.isEmpty ? 0.0 : fullHits / weekdays.length;
  return (bestBucket: bestBkt, bestAvgHours: bestAvg, fullDayHitRate: rate);
}

/// Labels indexed by bucket: 1=Mon..5=Fri, 6=Weekend.
const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Weekend'];
