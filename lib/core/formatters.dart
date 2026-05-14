import 'dart:math' as math;

/// Round any monetary value to 3 decimal places, always rounding UP (ceiling).
/// This is the single source of truth for money rounding across Tally.
///
/// Examples:
///   roundMoney(8.125)    => 8.125
///   roundMoney(8.1251)   => 8.126
///   roundMoney(8.5005)   => 8.501
///   roundMoney(16.25)    => 16.25
double roundMoney(double v) {
  if (v.isNaN || v.isInfinite) return 0;
  final cents = (v * 1000).ceil();
  return cents / 1000.0;
}

/// Format money for display: always 3 decimals, with thousands separator and £ prefix.
///
/// Examples:
///   formatMoney(8.125)    => '£8.125'
///   formatMoney(16.25)    => '£16.250'
///   formatMoney(1234.5)   => '£1,234.500'
String formatMoney(double v, {String symbol = '£'}) {
  final rounded = roundMoney(v);
  final parts = rounded.toStringAsFixed(3).split('.');
  final whole = _withThousands(parts[0]);
  return '$symbol$whole.${parts[1]}';
}

/// Format money without the currency symbol.
String formatMoneyPlain(double v) {
  final rounded = roundMoney(v);
  final parts = rounded.toStringAsFixed(3).split('.');
  return '${_withThousands(parts[0])}.${parts[1]}';
}

String _withThousands(String digits) {
  final negative = digits.startsWith('-');
  final clean = negative ? digits.substring(1) : digits;
  final buf = StringBuffer();
  for (var i = 0; i < clean.length; i++) {
    if (i > 0 && (clean.length - i) % 3 == 0) buf.write(',');
    buf.write(clean[i]);
  }
  return negative ? '-$buf' : buf.toString();
}

/// Format duration as Hh Mm (e.g. "7h 30m"). Single-source for time-display strings.
String formatHM(int totalMinutes) {
  final m = math.max(0, totalMinutes);
  final h = m ~/ 60;
  final mins = m % 60;
  if (h == 0) return '${mins}m';
  if (mins == 0) return '${h}h';
  return '${h}h ${mins}m';
}

/// Decimal hours rounded to 1 decimal place (no ceiling here — informational only).
String formatDecimalHours(int totalMinutes) {
  final hours = totalMinutes / 60.0;
  return hours.toStringAsFixed(1);
}
