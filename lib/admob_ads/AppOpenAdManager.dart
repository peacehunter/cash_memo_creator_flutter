import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  // Maximum duration to cache app open ad (4 hours as per Google recommendation)
  static const int maxCacheDurationHours = 4;

  // Load app open ad
  void loadAd() {
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      orientation: AppOpenAd.orientationPortrait,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          print('App open ad loaded successfully.');
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('App open ad failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  // Check if ad is available and not expired
  bool get isAdAvailable {
    if (_appOpenAd == null) return false;
    if (_appOpenLoadTime == null) return false;

    final now = DateTime.now();
    final duration = now.difference(_appOpenLoadTime!);

    return duration.inHours < maxCacheDurationHours;
  }

  // Show app open ad if available
  void showAdIfAvailable() {
    if (!isAdAvailable) {
      print('App open ad not available or expired. Loading new ad...');
      loadAd();
      return;
    }

    if (_isShowingAd) {
      print('App open ad is already showing.');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = true;
        print('App open ad showed full screen content.');
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = false;
        print('App open ad dismissed.');
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _isShowingAd = false;
        print('App open ad failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Load next ad
      },
    );

    _appOpenAd!.show();
  }

  // Dispose
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
