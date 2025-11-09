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

  // Show rewarded ad
  Future<bool> showRewardedAd({
    required Function onUserEarnedReward,
    Function? onAdClosed,
    Function? onAdFailed,
  }) async {
    if (_rewardedAd == null || !_isAdLoaded) {
      print('Rewarded ad is not ready yet.');
      if (onAdFailed != null) {
        onAdFailed();
      }
      return false;
    }

    bool rewardEarned = false;

    await _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('User earned reward: ${reward.amount} ${reward.type}');
      rewardEarned = true;
      onUserEarnedReward();
    });

    if (onAdClosed != null) {
      onAdClosed();
    }

    return rewardEarned;
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
