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
