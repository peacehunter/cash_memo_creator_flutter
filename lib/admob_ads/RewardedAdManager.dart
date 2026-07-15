import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdHelper.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  bool _autoReload = true;

  // Singleton pattern for global preloading
  static final RewardedAdManager _instance = RewardedAdManager._internal();
  factory RewardedAdManager() => _instance;
  RewardedAdManager._internal();

  // Initialize and preload ad
  void initialize({bool autoReload = true}) {
    _autoReload = autoReload;
    print('📺 [RewardedAdManager] Initializing with autoReload: $autoReload');
    preloadAd();
  }

  // Preload ad (can be called manually or automatically)
  void preloadAd() {
    if (_isLoading || _isAdLoaded) {
      print('📺 [RewardedAdManager] Already loading or loaded, skipping preload');
      return;
    }
    print('📺 [RewardedAdManager] Starting preload...');
    loadRewardedAd();
  }

  // Load rewarded ad
  void loadRewardedAd({Function? onAdLoaded, Function? onAdFailedToLoad}) {
    if (_isLoading) {
      print('📺 [RewardedAdManager] Ad is already being loaded, skipping...');
      return;
    }

    _isLoading = true;
    print('📺 [RewardedAdManager] Loading rewarded ad...');

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('📺 [RewardedAdManager] ✅ Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
          _setFullScreenContentCallback();
          if (onAdLoaded != null) {
            onAdLoaded();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('📺 [RewardedAdManager] ❌ Rewarded ad failed to load: $error');
          _isAdLoaded = false;
          _isLoading = false;
          _rewardedAd = null;
          if (onAdFailedToLoad != null) {
            onAdFailedToLoad(error);
          }

          // Retry after 30 seconds if autoReload is enabled
          if (_autoReload) {
            print('📺 [RewardedAdManager] Will retry loading in 30 seconds...');
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isAdLoaded && !_isLoading) {
                preloadAd();
              }
            });
          }
        },
      ),
    );
  }

  // Set full screen callbacks with auto-reload
  void _setFullScreenContentCallback() {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('📺 [RewardedAdManager] Ad showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('📺 [RewardedAdManager] Ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Automatically preload next ad if autoReload is enabled
        if (_autoReload) {
          print('📺 [RewardedAdManager] Auto-reloading next ad...');
          Future.delayed(const Duration(seconds: 1), () {
            preloadAd();
          });
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('📺 [RewardedAdManager] ❌ Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Preload next ad on failure too
        if (_autoReload) {
          Future.delayed(const Duration(seconds: 1), () {
            preloadAd();
          });
        }
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
