import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;

  // Method to load interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId, // Use AdHelper to get the correct ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _setFullScreenContentCallback(); // Set the full-screen callbacks
          print('Ad loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Set full screen callbacks for the interstitial ad
  void _setFullScreenContentCallback() {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('Interstitial ad is shown.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('Interstitial ad is dismissed.');
        ad.dispose(); // Dispose of the ad after it's shown and dismissed
        _interstitialAd = null; // Set to null so a new ad can be loaded
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('Interstitial ad failed to show: $error');
        ad.dispose(); // Dispose of the ad in case of failure
        _interstitialAd = null;
      },
      onAdImpression: (InterstitialAd ad) {
        print('Interstitial ad impression recorded.');
      },
    );
  }

  // Show the interstitial ad with optional callbacks for handling events
  void showInterstitialAd({
    Function? onAdClosed,    // When the ad is closed
    Function? onAdFailedToLoad,  // When the ad fails to load or show
    Function? onAdDismissed, // When the ad is dismissed after showing
  }) {
    if (_interstitialAd != null) {
      _interstitialAd!.show().then((_) {
        if (onAdClosed != null) {
          onAdClosed();  // Call the callback when the ad is closed
        }
      }).catchError((error) {
        if (onAdFailedToLoad != null) {
          onAdFailedToLoad(error);  // Call the callback on failure
        }
      });
    } else {
      print('Interstitial ad is not ready yet.');
      if (onAdFailedToLoad != null) {
        onAdFailedToLoad('Ad not ready.');
      }
    }
  }

  void emptyInterstitialObj(){
    _interstitialAd=null;
  }
  // Dispose of the interstitial ad when no longer needed
  void dispose() {
    _interstitialAd?.dispose();
  }
}
