import 'package:cloud_firestore/cloud_firestore.dart';

enum ExtraKind { fee, payment }

class Extra {
  final String id;
  final String monthKey; // YYYY-MM
  final String label;
  final double amount; // always positive; kind decides sign
  final ExtraKind kind;
  final DateTime createdAt;

  const Extra({
    required this.id,
    required this.monthKey,
    required this.label,
    required this.amount,
    required this.kind,
    required this.createdAt,
  });

  /// Signed contribution to the month total: payments add, fees subtract.
  double get signedAmount => kind == ExtraKind.payment ? amount : -amount;

  static String monthKeyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  factory Extra.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    return Extra(
      id: s.id,
      monthKey: (d['monthKey'] as String?) ?? '',
      label: (d['label'] as String?) ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      kind: ((d['kind'] as String?) ?? 'fee') == 'payment'
          ? ExtraKind.payment
          : ExtraKind.fee,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'monthKey': monthKey,
        'label': label,
        'amount': amount,
        'kind': kind == ExtraKind.payment ? 'payment' : 'fee',
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
