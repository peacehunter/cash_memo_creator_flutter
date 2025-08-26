import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

/// Singleton manager to handle loading and showing App Open Ads
class AppOpenAdManager {
  AppOpenAdManager._internal();

  static final AppOpenAdManager instance = AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;
  // Records when the ad was last displayed to prevent frequent showing
  DateTime? _lastShown;

  /// Load an App Open Ad
  void loadAd() {
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
          // Ad is preloaded; will be shown when appropriate via lifecycle callbacks
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
        },
      ),
    );
  }

  bool _isAdAvailable() {
    // Ad is available if it exists and was loaded less than 4 hours ago
    return _appOpenAd != null &&
        _loadTime != null &&
        DateTime.now().difference(_loadTime!).inHours < 4;
  }

  /// Show the App Open Ad if available
  void showAdIfAvailable() {
    // If ad isn’t fresh, preload a new one
    if (!_isAdAvailable()) {
      loadAd();
      return;
    }

    // Prevent showing again within 10 minutes
    if (_lastShown != null &&
        DateTime.now().difference(_lastShown!).inMinutes < 10) {
      return;
    }

    if (_isShowingAd) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback =
        FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = true;
        _lastShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}
