import 'package:college_reality_india/core/constants/wallet_constants.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Must agree with functions/test/walletLogic.test.js -- the server re-checks
// every price, so any drift here shows the user a wrong rate or package.
void main() {
  group('resolvePerMinuteRatePaise', () {
    test('₹10/min default for a guide with no pricing', () {
      expect(resolvePerMinuteRatePaise(const GuideCommunicationSettings()), 1000);
    });

    test('explicit rate wins', () {
      expect(
        resolvePerMinuteRatePaise(const GuideCommunicationSettings(
          perMinuteRatePaise: 1500,
          callPricing: [
            GuideCallPriceOption(type: 'call', minutes: 15, pricePaise: 9900),
          ],
        )),
        1500,
      );
    });

    test('derived from the cheapest package (₹99 / 15 min -> 660)', () {
      expect(
        resolvePerMinuteRatePaise(const GuideCommunicationSettings(
          callPricing: [
            GuideCallPriceOption(type: 'call', minutes: 30, pricePaise: 24900),
            GuideCallPriceOption(type: 'call', minutes: 15, pricePaise: 9900),
          ],
        )),
        660,
      );
    });
  });

  group('effectiveCallPackages', () {
    test('default 15/30 min packages when the guide never priced calls', () {
      final packs = effectiveCallPackages(const GuideCommunicationSettings());
      expect(packs.map((p) => [p.minutes, p.pricePaise]), [
        [15, 15000],
        [30, 30000],
      ]);
    });

    test("respects a guide who priced calls but switched them off", () {
      expect(
        effectiveCallPackages(const GuideCommunicationSettings(
          callPricing: [
            GuideCallPriceOption(type: 'call', minutes: 15, pricePaise: 9900),
          ],
        )),
        isEmpty,
      );
    });
  });

  test('shared balance: ₹150 = 15 min at ₹10, 30 min at ₹5', () {
    expect(talkSecondsFor(15000, 1000), 15 * 60);
    expect(talkSecondsFor(15000, 500), 30 * 60);
    expect(talkSecondsFor(0, 1000), 0);
  });

  test('formatRupees', () {
    expect(formatRupees(15000), '₹150');
    expect(formatRupees(1250), '₹12.50');
    expect(formatRupees(5), '₹0.05');
  });
}
