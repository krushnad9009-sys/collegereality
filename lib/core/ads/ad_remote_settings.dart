import 'package:flutter/foundation.dart';

/// Super Admin-controlled AdMob switches + ad unit IDs, stored in
/// `app_config/ads_settings` and applied live (no app update needed).
///
/// Field names follow the admin spec: `bannerAdId` / `interstitialAdId` /
/// `rewardedAdId` are the ANDROID unit IDs (AdMob issues separate IDs per
/// platform); the `...Ios` fields are their iOS counterparts.
///
/// Missing / unreadable doc => everything OFF: ads show only once a Super
/// Admin has switched them on.
@immutable
class AdRemoteSettings {
  final bool enableBannerAds;
  final bool enableInterstitialAds;
  final bool enableRewardedAds;
  final String bannerAdId;
  final String bannerAdIdIos;
  final String interstitialAdId;
  final String interstitialAdIdIos;
  final String rewardedAdId;
  final String rewardedAdIdIos;
  final DateTime? updatedAt;
  final String? updatedBy;

  const AdRemoteSettings({
    this.enableBannerAds = false,
    this.enableInterstitialAds = false,
    this.enableRewardedAds = false,
    this.bannerAdId = '',
    this.bannerAdIdIos = '',
    this.interstitialAdId = '',
    this.interstitialAdIdIos = '',
    this.rewardedAdId = '',
    this.rewardedAdIdIos = '',
    this.updatedAt,
    this.updatedBy,
  });

  static const allOff = AdRemoteSettings();

  static const collection = 'app_config';
  static const docId = 'ads_settings';

  /// AdMob ad unit ID: `ca-app-pub-<16 digits>/<10 digits>`. Mirrored in
  /// firestore.rules so a typo can't be saved.
  static final RegExp adUnitIdPattern = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');

  /// Empty (= "use the build's default") or a well-formed ad unit ID.
  static bool isValidAdUnitId(String value) =>
      value.isEmpty || adUnitIdPattern.hasMatch(value.trim());

  factory AdRemoteSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return allOff;
    String id(String key) {
      final v = json[key];
      return v is String && isValidAdUnitId(v) ? v.trim() : '';
    }

    bool flag(String key) => json[key] == true;
    DateTime? updatedAt;
    final raw = json['updatedAt'];
    if (raw is String) {
      updatedAt = DateTime.tryParse(raw);
    } else if (raw != null) {
      try {
        updatedAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    return AdRemoteSettings(
      enableBannerAds: flag('enableBannerAds'),
      enableInterstitialAds: flag('enableInterstitialAds'),
      enableRewardedAds: flag('enableRewardedAds'),
      bannerAdId: id('bannerAdId'),
      bannerAdIdIos: id('bannerAdIdIos'),
      interstitialAdId: id('interstitialAdId'),
      interstitialAdIdIos: id('interstitialAdIdIos'),
      rewardedAdId: id('rewardedAdId'),
      rewardedAdIdIos: id('rewardedAdIdIos'),
      updatedAt: updatedAt,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableBannerAds': enableBannerAds,
        'enableInterstitialAds': enableInterstitialAds,
        'enableRewardedAds': enableRewardedAds,
        'bannerAdId': bannerAdId,
        'bannerAdIdIos': bannerAdIdIos,
        'interstitialAdId': interstitialAdId,
        'interstitialAdIdIos': interstitialAdIdIos,
        'rewardedAdId': rewardedAdId,
        'rewardedAdIdIos': rewardedAdIdIos,
      };

  @override
  bool operator ==(Object other) =>
      other is AdRemoteSettings &&
      const _MapEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

/// Minimal map equality (avoids a package:collection import here).
class _MapEquality {
  const _MapEquality();
  bool equals(Map<String, dynamic> a, Map<String, dynamic> b) =>
      a.length == b.length &&
      a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
}
