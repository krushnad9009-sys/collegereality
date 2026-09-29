import '../../features/communication/models/guide_stats_model.dart';

/// Shared call wallet + guide call pricing. MUST match
/// functions/src/walletLogic.js -- the server is the only one that moves
/// money and re-checks every price; this copy only drives what the app
/// shows (rates, "≈ N min" estimates, checkout packages).
class WalletConstants {
  WalletConstants._();

  /// Rate for any guide who hasn't published their own call pricing.
  static const int defaultRatePaisePerMinute = 1000; // ₹10/min

  static const int minRechargePaise = 5000; // ₹50
  static const int maxRechargePaise = 1000000; // ₹10,000
  static const List<int> rechargePresetsPaise = [10000, 20000, 50000, 100000];

  /// A paid call needs at least this much talk time to start.
  static const int minCallSeconds = 60;

  static const List<int> defaultPackageMinutes = [15, 30];
}

/// Per-minute rate for calling a guide: their explicit rate, else their
/// cheapest priced call package (price / minutes, rounded up), else ₹10.
int resolvePerMinuteRatePaise(GuideCommunicationSettings s) {
  final explicit = s.perMinuteRatePaise;
  if (explicit > 0) return explicit;
  final perMinute = s.callPricing
      .where((p) => p.pricePaise > 0 && p.minutes > 0)
      .map((p) => (p.pricePaise / p.minutes).ceil());
  if (perMinute.isNotEmpty) return perMinute.reduce((a, b) => a < b ? a : b);
  return WalletConstants.defaultRatePaisePerMinute;
}

/// Consultation call packages a guide offers; a guide who never priced
/// calls gets default ₹10/min packages instead of being unbookable.
List<GuideCallPriceOption> effectiveCallPackages(GuideCommunicationSettings s) {
  final priced =
      s.callPricing.where((p) => p.pricePaise > 0 && p.minutes > 0).toList();
  if (s.callAvailable && priced.isNotEmpty) return priced;
  if (priced.isNotEmpty) return const []; // priced, but switched off
  return [
    for (final minutes in WalletConstants.defaultPackageMinutes)
      GuideCallPriceOption(
        type: 'call',
        minutes: minutes,
        pricePaise: minutes * WalletConstants.defaultRatePaisePerMinute,
      ),
  ];
}

/// Whole seconds of talk [balancePaise] buys at [ratePaisePerMinute].
int talkSecondsFor(int balancePaise, int ratePaisePerMinute) {
  if (ratePaisePerMinute <= 0 || balancePaise <= 0) return 0;
  return (balancePaise * 60) ~/ ratePaisePerMinute;
}

/// "₹10", "₹12.50".
String formatRupees(int paise) {
  final rupees = paise ~/ 100;
  final rem = paise % 100;
  return rem == 0 ? '₹$rupees' : '₹$rupees.${rem.toString().padLeft(2, '0')}';
}
