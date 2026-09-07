import 'package:intl/intl.dart';

/// Formats amounts in Indian numbering with ₹ symbol.
/// Example: 85000 → ₹85,000/year  |  125000 → ₹1,25,000/year
class IndianCurrencyFormatter {
  IndianCurrencyFormatter._();

  static final _formatter = NumberFormat.decimalPattern('en_IN');

  static String format(
    num amount, {
    String suffix = '/year',
    bool includeSymbol = true,
  }) {
    if (amount <= 0) return '—';
    final value = amount is int ? amount : amount.round();
    final core = _formatter.format(value);
    return includeSymbol ? '₹$core$suffix' : '$core$suffix';
  }

  /// Ultra-short form for tight UI like stat chips: `₹85k`, `₹1.2L`, `₹3.5Cr`.
  /// No `/year` suffix. Returns `'—'` for non-positive amounts.
  static String compact(num amount) {
    if (amount <= 0) return '—';
    final v = amount.toDouble();
    if (v >= 10000000) return '₹${_trimZero(v / 10000000)}Cr';
    if (v >= 100000) return '₹${_trimZero(v / 100000)}L';
    if (v >= 1000) return '₹${_trimZero(v / 1000)}k';
    return '₹${v.round()}';
  }

  static String _trimZero(double n) {
    final s = n.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String formatRange({
    required int min,
    required int max,
    String suffix = '/year',
  }) {
    if (min <= 0 && max <= 0) return '—';
    if (min > 0 && max > 0 && min != max) {
      return '${format(min, suffix: '', includeSymbol: true)} – ${format(max, suffix: suffix, includeSymbol: false)}';
    }
    return format(min > 0 ? min : max, suffix: suffix);
  }
}
