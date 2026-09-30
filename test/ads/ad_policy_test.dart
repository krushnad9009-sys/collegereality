import 'package:college_reality_india/core/ads/ad_config.dart';
import 'package:college_reality_india/core/ads/ad_manager.dart';
import 'package:college_reality_india/core/ads/ad_remote_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _real = 'ca-app-pub-1234567890123456/1234567890';
const _built = 'ca-app-pub-6543210987654321/0987654321';
const _test = 'ca-app-pub-3940256099942544/1033173712';

String? _resolve({
  bool remoteEnabled = true,
  String remoteId = '',
  String buildId = '',
  bool release = false,
  bool platform = true,
}) =>
    AdConfig.resolveUnitId(
      remoteEnabled: remoteEnabled,
      remoteId: remoteId,
      testId: _test,
      buildId: buildId,
      releaseOverride: release,
      platformEnabledOverride: platform,
    );

void main() {
  group('interstitial frequency cap', () {
    final start = DateTime(2026, 9, 30, 10);

    test('never in the first minute of a session', () {
      expect(
        interstitialAllowed(
            now: start.add(const Duration(seconds: 30)), sessionStart: start),
        isFalse,
      );
      expect(
        interstitialAllowed(
            now: start.add(const Duration(seconds: 61)), sessionStart: start),
        isTrue,
      );
    });

    test('at most one per cooldown window', () {
      final last = start.add(const Duration(minutes: 5));
      expect(
        interstitialAllowed(
          now: last.add(const Duration(minutes: 1)),
          sessionStart: start,
          lastShown: last,
        ),
        isFalse,
      );
      expect(
        interstitialAllowed(
          now: last.add(AdConfig.interstitialCooldown),
          sessionStart: start,
          lastShown: last,
        ),
        isTrue,
      );
    });
  });

  group('unit id resolution (Super Admin switch + build type)', () {
    test('switched off by the Super Admin -> no ad, in any build', () {
      expect(_resolve(remoteEnabled: false, remoteId: _real), isNull);
      expect(
          _resolve(remoteEnabled: false, remoteId: _real, release: true), isNull);
    });

    test('debug/profile always use the Google test unit, even with real '
        'IDs saved remotely', () {
      expect(_resolve(remoteId: _real, buildId: _built), _test);
    });

    test('release prefers the remote ID, then the built-in one', () {
      expect(_resolve(remoteId: _real, buildId: _built, release: true), _real);
      expect(_resolve(buildId: _built, release: true), _built);
    });

    test('release never falls back to a test unit', () {
      expect(_resolve(release: true), isNull);
    });

    test('unsupported platform (web / desktop) -> no ad', () {
      expect(_resolve(remoteId: _real, platform: false), isNull);
    });

    test('platform picks its own test unit', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        AdConfig.interstitialUnitIdFor(
            const AdRemoteSettings(enableInterstitialAds: true)),
        'ca-app-pub-3940256099942544/4411468910',
      );
    });
  });

  group('AdRemoteSettings', () {
    test('missing doc = everything off', () {
      final s = AdRemoteSettings.fromJson(null);
      expect(s.enableBannerAds, isFalse);
      expect(s.enableInterstitialAds, isFalse);
      expect(s.enableRewardedAds, isFalse);
    });

    test('reads flags and IDs; drops malformed IDs and non-bool flags', () {
      final s = AdRemoteSettings.fromJson({
        'enableBannerAds': true,
        'enableInterstitialAds': 'yes',
        'bannerAdId': _real,
        'interstitialAdId': 'ca-app-pub-typo/123',
      });
      expect(s.enableBannerAds, isTrue);
      expect(s.enableInterstitialAds, isFalse);
      expect(s.bannerAdId, _real);
      expect(s.interstitialAdId, '');
    });

    test('id validation', () {
      expect(AdRemoteSettings.isValidAdUnitId(''), isTrue);
      expect(AdRemoteSettings.isValidAdUnitId(_real), isTrue);
      expect(AdRemoteSettings.isValidAdUnitId('ca-app-pub-123/456'), isFalse);
      expect(
        AdRemoteSettings.isValidAdUnitId(
            'ca-app-pub-1234567890123456~1234567890'),
        isFalse, // that's an App ID, not an ad unit ID
      );
    });

    test('value equality (drives the admin "Save" button)', () {
      expect(
        const AdRemoteSettings(enableBannerAds: true, bannerAdId: _real),
        const AdRemoteSettings(enableBannerAds: true, bannerAdId: _real),
      );
      expect(
        const AdRemoteSettings(enableBannerAds: true),
        isNot(const AdRemoteSettings()),
      );
    });
  });

  test('flipping the switch updates live consumers (rewarded button)', () {
    final manager = AdManager.instance;
    manager.applySettings(const AdRemoteSettings(enableRewardedAds: true));
    expect(manager.rewardedAvailable, isTrue);
    manager.applySettings(AdRemoteSettings.allOff);
    expect(manager.rewardedAvailable, isFalse);
  });
}
