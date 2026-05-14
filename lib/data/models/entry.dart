import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  final String id;
  final DateTime date;
  final int hours;
  final int minutes;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Entry({
    required this.id,
    required this.date,
    required this.hours,
    required this.minutes,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalMinutes => hours * 60 + minutes;

  static String idForDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  factory Entry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    final raw = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Entry(
      id: s.id,
      date: DateTime(raw.year, raw.month, raw.day),
      hours: (d['hours'] as num?)?.toInt() ?? 0,
      minutes: (d['minutes'] as num?)?.toInt() ?? 0,
      source: (d['source'] as String?) ?? 'manual',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'hours': hours,
        'minutes': minutes,
        'totalMinutes': totalMinutes,
        'source': source,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
