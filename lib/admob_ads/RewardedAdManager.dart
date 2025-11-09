import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Load rewarded ad
  void loadRewardedAd({Function? onAdLoaded, Function? onAdFailedToLoad}) {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _setFullScreenContentCallback();
          if (onAdLoaded != null) {
            onAdLoaded();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Rewarded ad failed to load: $error');
          _isAdLoaded = false;
          _rewardedAd = null;
          if (onAdFailedToLoad != null) {
            onAdFailedToLoad(error);
          }
        },
      ),
    );
  }

  // Set full screen callbacks
  void _setFullScreenContentCallback() {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('Rewarded ad showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('Rewarded ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
      },
    );
  }

  // Show rewarded ad with proper async handling using Completer
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || !_isAdLoaded) {
      print('Rewarded ad is not ready yet.');
      return false;
    }

    // Use Completer to properly await ad completion
    final Completer<bool> completer = Completer<bool>();
    bool rewardEarned = false;

    // Update callbacks to complete the future
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('Rewarded ad showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('Rewarded ad dismissed. Reward earned: $rewardEarned');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Complete the future when ad is dismissed
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Complete with false on error
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    // Show the ad and listen for reward
    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    // Wait for the ad to be dismissed or fail
    return completer.future;
  }

  // Check if ad is loaded
  bool get isAdLoaded => _isAdLoaded;

  // Dispose
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
