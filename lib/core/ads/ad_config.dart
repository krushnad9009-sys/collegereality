import 'package:flutter/foundation.dart';

import 'ad_remote_settings.dart';

/// Which AdMob ad unit IDs to use, and whether ads run at all.
///
///  * Debug / profile builds ALWAYS use Google's official test ad units
///    (https://developers.google.com/admob/flutter/test-ads) -- clicking a
///    real ad from a dev build is invalid traffic and can get the AdMob
///    account suspended.
///  * Release builds use ONLY the production IDs passed at build time, e.g.
///
///      flutter build appbundle --release \
///        --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/YYYY \
///        --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/YYYY \
///        --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY
///      (…_IOS equivalents for iOS)
///
///    A release build without them shows NO ads for that format -- it never
///    falls back to test IDs (which earn nothing).
///
/// On top of that, a Super Admin switches each format on/off and can swap
/// the production unit IDs live from the admin panel
/// (`app_config/ads_settings`, see [AdRemoteSettings]) -- remote IDs win
/// over the build-time ones in release builds.
///
/// The AdMob *App* ID is native config, not Dart: Android reads it from the
/// `ADMOB_APP_ID` gradle property (android/app/build.gradle.kts, test app
/// ID by default); iOS from `GADApplicationIdentifier` in Info.plist.
class AdConfig {
  AdConfig._();

  // Google's official test ad units.
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  static const _prodBannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
  );
  static const _prodBannerIos = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const _prodInterstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
  );
  static const _prodInterstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
  );
  static const _prodRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );
  static const _prodRewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS');

  /// Kill switch: `--dart-define=ADS_ENABLED=false`.
  static const bool _enabledFlag = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: true,
  );

  /// Ads exist only on Android / iOS (the plugin has no web support; the
  /// Super Admin web panel never shows ads).
  static bool get supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get enabled => _enabledFlag && supportedPlatform;

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  /// Which unit ID to use for one ad format, or null = don't show it.
  ///
  /// Order: platform/kill switch -> Super Admin toggle (remote) -> build:
  ///   * non-release: ALWAYS Google's test unit, even if real IDs are saved
  ///     remotely (dev taps on real ads = invalid traffic);
  ///   * release: the Super Admin's remote ID, else the build-time
  ///     --dart-define ID, else nothing (never a test ID).
  @visibleForTesting
  static String? resolveUnitId({
    required bool remoteEnabled,
    required String remoteId,
    required String testId,
    required String buildId,
    bool? releaseOverride,
    bool? platformEnabledOverride,
  }) {
    if (!(platformEnabledOverride ?? enabled)) return null;
    if (!remoteEnabled) return null;
    final release = releaseOverride ?? kReleaseMode;
    if (!release) return testId;
    if (remoteId.isNotEmpty) return remoteId;
    return buildId.isEmpty ? null : buildId;
  }

  static String? bannerUnitIdFor(AdRemoteSettings s) => resolveUnitId(
    remoteEnabled: s.enableBannerAds,
    remoteId: _ios ? s.bannerAdIdIos : s.bannerAdId,
    testId: _ios ? _testBannerIos : _testBannerAndroid,
    buildId: _ios ? _prodBannerIos : _prodBannerAndroid,
  );

  static String? interstitialUnitIdFor(AdRemoteSettings s) => resolveUnitId(
    remoteEnabled: s.enableInterstitialAds,
    remoteId: _ios ? s.interstitialAdIdIos : s.interstitialAdId,
    testId: _ios ? _testInterstitialIos : _testInterstitialAndroid,
    buildId: _ios ? _prodInterstitialIos : _prodInterstitialAndroid,
  );

  static String? rewardedUnitIdFor(AdRemoteSettings s) => resolveUnitId(
    remoteEnabled: s.enableRewardedAds,
    remoteId: _ios ? s.rewardedAdIdIos : s.rewardedAdId,
    testId: _ios ? _testRewardedIos : _testRewardedAndroid,
    buildId: _ios ? _prodRewardedIos : _prodRewardedAndroid,
  );

  /// Interstitials: at most one per [interstitialCooldown], and never in the
  /// first [interstitialGracePeriod] of a session.
  static const Duration interstitialCooldown = Duration(minutes: 3);
  static const Duration interstitialGracePeriod = Duration(seconds: 60);

  /// Rewarded video -> wallet credit. Display copy only: the server
  /// (functions/src/adRewardLogic.js) decides the real amount and cap.
  static const int rewardPaise = 200; // ₹2 per completed video
  static const int rewardDailyCap = 5;
}
