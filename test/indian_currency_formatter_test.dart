import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/utils/indian_currency_formatter.dart';

void main() {
  group('IndianCurrencyFormatter', () {
    test('formats standard amounts with Indian grouping', () {
      expect(
        IndianCurrencyFormatter.format(85000),
        '₹85,000/year',
      );
      expect(
        IndianCurrencyFormatter.format(125000),
        '₹1,25,000/year',
      );
    });

    test('returns dash for zero or negative amounts', () {
      expect(IndianCurrencyFormatter.format(0), '—');
      expect(IndianCurrencyFormatter.format(-100), '—');
    });

    test('formats fee ranges', () {
      expect(
        IndianCurrencyFormatter.formatRange(min: 85000, max: 125000),
        '₹85,000 – 1,25,000/year',
      );
      expect(
        IndianCurrencyFormatter.formatRange(min: 100000, max: 100000),
        '₹1,00,000/year',
      );
    });
  });
}
