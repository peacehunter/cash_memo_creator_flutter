import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

/// Singleton manager to handle loading and showing App Open Ads
class AppOpenAdManager {
  AppOpenAdManager._internal();
  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;
  DateTime? _lastShown;

  /// Load an App Open Ad
  void loadAd() {
    if (kIsWeb) return;
    // Limit ad load frequency to avoid excessive calls
    if (_appOpenAd != null) {
      return;
    }
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
        },
      ),
    );
  }

  bool _isAdAvailable() {
    if (kIsWeb) return false;
    return _appOpenAd != null &&
        _loadTime != null &&
        DateTime.now().difference(_loadTime!).inHours < 4;
  }

  /// Show the App Open Ad if available
  void showIfAvailable() {
    if (kIsWeb) return;
    if (_isAdAvailable() && !_isShowingAd) {
      _isShowingAd = true;
      _appOpenAd!.show();
      _appOpenAd = null;
      _isShowingAd = false;
      _loadTime = null;
    }
  }
}
