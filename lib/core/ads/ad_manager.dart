import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../bootstrap/firebase_bootstrap.dart';
import 'ad_config.dart';
import 'ad_remote_settings.dart';

/// Pure interstitial frequency cap (unit-tested): never in the first
/// [AdConfig.interstitialGracePeriod] of a session, and at most once per
/// [AdConfig.interstitialCooldown].
bool interstitialAllowed({
  required DateTime now,
  required DateTime sessionStart,
  DateTime? lastShown,
}) {
  if (now.difference(sessionStart) < AdConfig.interstitialGracePeriod) {
    return false;
  }
  if (lastShown != null &&
      now.difference(lastShown) < AdConfig.interstitialCooldown) {
    return false;
  }
  return true;
}

enum RewardedAdOutcome {
  /// Watched to the end -- the server credits the wallet (SSV callback).
  rewarded,

  /// Closed early, or no ad available right now.
  notRewarded,
  unavailable,
}

/// One place that loads and shows AdMob ads. Every entry point is safe to
/// call at any time: before init, on web, with ads disabled, offline, or
/// with no fill -- it just does nothing (never throws into the UI).
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  final DateTime _sessionStart = DateTime.now();
  Completer<bool>? _init;
  bool _sdkReady = false;

  /// Live Super Admin settings (`app_config/ads_settings`). Everything is
  /// OFF until the first snapshot says otherwise. Widgets listen to this
  /// to show/hide instantly when an admin flips a switch.
  final ValueNotifier<AdRemoteSettings> settings =
      ValueNotifier(AdRemoteSettings.allOff);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  String? _interstitialUnit;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitial;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;

  /// True once consent is resolved and the SDK is initialized.
  Future<bool> get ready => _init?.future ?? Future.value(false);

  /// Called unawaited from main(): consent (UMP, required for EEA/UK
  /// users) -> MobileAds.initialize() -> preload an interstitial. Bounded
  /// so a hung consent / SDK call can never matter to the app.
  Future<bool> initialize() {
    final existing = _init;
    if (existing != null) return existing.future;
    final completer = _init = Completer<bool>();
    if (!AdConfig.enabled) {
      completer.complete(false);
      return completer.future;
    }
    unawaited(_listenToRemoteSettings());
    () async {
      try {
        await _gatherConsent().timeout(const Duration(seconds: 10));
        if (!await ConsentInformation.instance.canRequestAds()) {
          completer.complete(false);
          return;
        }
        await MobileAds.instance.initialize().timeout(
          const Duration(seconds: 10),
        );
        _sdkReady = true;
        completer.complete(true);
        _loadInterstitial();
      } catch (e) {
        debugPrint('[Ads] init skipped: $e');
        if (!completer.isCompleted) completer.complete(false);
      }
    }();
    return completer.future;
  }

  /// Subscribes to the Super Admin ad settings once Firebase is up (never
  /// awaited by startup). Offline, Firestore serves the last cached copy.
  Future<void> _listenToRemoteSettings() async {
    try {
      await FirebaseBootstrap.ensureInitialized();
      await _settingsSub?.cancel();
      _settingsSub = FirebaseFirestore.instance
          .collection(AdRemoteSettings.collection)
          .doc(AdRemoteSettings.docId)
          .snapshots()
          .listen(
            (snap) => applySettings(AdRemoteSettings.fromJson(snap.data())),
            onError: (Object e) {
              debugPrint('[Ads] settings unavailable, ads off: $e');
              applySettings(AdRemoteSettings.allOff);
            },
          );
    } catch (e) {
      debugPrint('[Ads] settings listener not started: $e');
    }
  }

  /// Applies new settings: toggling a format off drops any loaded ad of
  /// that format; a changed unit ID reloads with the new one.
  @visibleForTesting
  void applySettings(AdRemoteSettings next) {
    settings.value = next;
    final unit = AdConfig.interstitialUnitIdFor(next);
    if (unit != _interstitialUnit) {
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialUnit = null;
    }
    if (unit != null) _loadInterstitial();
    if (AdConfig.rewardedUnitIdFor(next) == null) {
      _rewarded?.dispose();
      _rewarded = null;
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) debugPrint('[Ads] consent form: ${error.message}');
        if (!done.isCompleted) done.complete();
      }),
      (error) {
        debugPrint('[Ads] consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  // ── Interstitial ────────────────────────────────────────────────────

  void _loadInterstitial() {
    final unitId = AdConfig.interstitialUnitIdFor(settings.value);
    if (!_sdkReady ||
        unitId == null ||
        _interstitial != null ||
        _interstitialLoading) {
      return;
    }
    _interstitialLoading = true;
    _interstitialUnit = unitId;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          // Switched off / ID changed while this was loading: discard.
          if (AdConfig.interstitialUnitIdFor(settings.value) != unitId) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          debugPrint('[Ads] interstitial load failed: ${error.message}');
        },
      ),
    );
  }

  /// Shows a full-screen ad after a natural break ([reason] is just for
  /// logs), if one is loaded and the frequency cap allows. Resolves when
  /// the ad is dismissed (or immediately if none was shown), so callers can
  /// `await` it before navigating on.
  Future<void> showInterstitialAtBreak(String reason) async {
    if (!await ready) return;
    // Super Admin switched full-screen ads off.
    if (AdConfig.interstitialUnitIdFor(settings.value) == null) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (!interstitialAllowed(
      now: DateTime.now(),
      sessionStart: _sessionStart,
      lastShown: _lastInterstitial,
    )) {
      return;
    }
    _interstitial = null;
    _lastInterstitial = DateTime.now();
    final closed = Completer<void>();
    void finish(Ad a) {
      a.dispose();
      if (!closed.isCompleted) closed.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint(
          '[Ads] interstitial show failed ($reason): ${error.message}',
        );
        finish(a);
      },
    );
    try {
      await ad.show();
    } catch (e) {
      finish(ad);
    }
    return closed.future.timeout(const Duration(minutes: 2), onTimeout: () {});
  }

  // ── Rewarded ───────────────────────────────────────────────────────

  bool get rewardedAvailable =>
      AdConfig.rewardedUnitIdFor(settings.value) != null;

  Future<RewardedAd?> _loadRewarded(String uid) {
    final unitId = AdConfig.rewardedUnitIdFor(settings.value);
    if (unitId == null || _rewardedLoading) return Future.value(null);
    _rewardedLoading = true;
    final loaded = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          loaded.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          debugPrint('[Ads] rewarded load failed: ${error.message}');
          loaded.complete(null);
        },
      ),
    );
    return loaded.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _rewardedLoading = false;
        return null;
      },
    );
  }

  /// Loads and shows a rewarded video for [uid]. The reward itself is
  /// granted SERVER-side: AdMob calls our `admobRewardCallback` function
  /// with a Google-signed payload carrying this uid (server-side
  /// verification), which credits the wallet. The client never credits
  /// money, so a modified app can't mint balance.
  Future<RewardedAdOutcome> showRewarded({required String uid}) async {
    if (!rewardedAvailable || !await ready) {
      return RewardedAdOutcome.unavailable;
    }
    final ad = _rewarded ?? await _loadRewarded(uid);
    _rewarded = null;
    if (ad == null) return RewardedAdOutcome.unavailable;

    await ad.setServerSideOptions(ServerSideVerificationOptions(userId: uid));
    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
      await closed.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } catch (e) {
      debugPrint('[Ads] rewarded show failed: $e');
      ad.dispose();
      return RewardedAdOutcome.unavailable;
    }
    return earned ? RewardedAdOutcome.rewarded : RewardedAdOutcome.notRewarded;
  }
}
