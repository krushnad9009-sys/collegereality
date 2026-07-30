import 'package:college_reality_india/features/communication/utils/communication_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatGuideResponseTime', () {
    test('formats minutes and hours', () {
      expect(formatGuideResponseTime(0), 'Usually responds quickly');
      expect(formatGuideResponseTime(25), '~25 min response');
      expect(formatGuideResponseTime(120), '~2 hr response');
    });
  });

  group('formatLastActive', () {
    test('formats relative activity', () {
      final now = DateTime.now();
      expect(formatLastActive(null), 'Recently active');
      expect(formatLastActive(now.subtract(const Duration(minutes: 2))), 'Active now');
      expect(
        formatLastActive(now.subtract(const Duration(minutes: 20))),
        'Active 20m ago',
      );
      expect(
        formatLastActive(now.subtract(const Duration(hours: 3))),
        'Active 3h ago',
      );
    });
  });

  group('formatCallDuration', () {
    test('pads mm:ss', () {
      expect(formatCallDuration(5), '00:05');
      expect(formatCallDuration(75), '01:15');
      expect(formatCallDuration(600), '10:00');
    });
  });
}
