import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_manager.dart';

/// Adaptive banner for the bottom of a screen, driven live by the Super
/// Admin's `enableBannerAds` / `bannerAdId` (app_config/ads_settings).
///
/// Takes no space until an ad has actually loaded, animates its height to
/// zero when banners are switched off (or a load fails), and reloads when
/// the unit ID changes -- so the layout never keeps an empty gap.
class StickyBannerAd extends StatefulWidget {
  const StickyBannerAd({super.key});

  @override
  State<StickyBannerAd> createState() => _StickyBannerAdState();
}

class _StickyBannerAdState extends State<StickyBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  String? _unitId;
  int? _width;

  @override
  void initState() {
    super.initState();
    AdManager.instance.settings.addListener(_onSettings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_width != width) {
      _width = width;
      _sync(forceReload: true);
    }
  }

  void _onSettings() => _sync();

  /// Brings the banner in line with the current settings.
  Future<void> _sync({bool forceReload = false}) async {
    final unitId = AdConfig.bannerUnitIdFor(AdManager.instance.settings.value);
    if (unitId == null) {
      _drop();
      return;
    }
    if (!forceReload && unitId == _unitId && _ad != null) return;
    _unitId = unitId;
    await _load(unitId);
  }

  void _drop() {
    final ad = _ad;
    _ad = null;
    _unitId = null;
    if (mounted && _loaded) setState(() => _loaded = false);
    _loaded = false;
    ad?.dispose();
  }

  Future<void> _load(String unitId) async {
    final width = _width;
    if (width == null || !await AdManager.instance.ready || !mounted) return;
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          MediaQuery.orientationOf(context),
          width,
        );
    // Settings changed while we were measuring.
    if (size == null || !mounted || unitId != _unitId) return;

    final previous = _ad;
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted && identical(_ad, ad)) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          debugPrint('[Ads] banner failed: ${error.message}');
          if (mounted && identical(_ad, ad)) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    setState(() {
      _ad = ad;
      _loaded = false;
    });
    previous?.dispose();
    await ad.load();
  }

  @override
  void dispose() {
    AdManager.instance.settings.removeListener(_onSettings);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final visible = ad != null && _loaded;
    // Sits above the bottom navigation bar, which already handles the
    // system inset -- no SafeArea here or the gap would double.
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: visible
          ? SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}
