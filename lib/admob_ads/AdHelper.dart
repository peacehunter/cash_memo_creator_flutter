import 'package:flutter/foundation.dart';
import 'dart:io';

class AdHelper {
  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (kIsWeb) return '';

    if (Platform.isAndroid) {
      // TODO: Replace with your actual Android banner ad unit ID
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your actual ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your actual iOS banner ad unit ID
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your actual ID
    }
    return '';
  }

  // Interstitial Ad Unit IDs
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';

    if (Platform.isAndroid) {
      // TODO: Replace with your actual Android interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your actual ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your actual iOS interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your actual ID
    }
    return '';
  }

  // Rewarded Ad Unit IDs
  static String get rewardedAdUnitId {
    if (kIsWeb) {
      print('📱 [AdHelper] Platform is Web - rewarded ads not supported');
      return '';
    }

    String adUnitId = '';
    if (Platform.isAndroid) {
      // TODO: Replace with your actual Android rewarded ad unit ID
      adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
      // adUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your actual ID
      print('📱 [AdHelper] Using Android rewarded ad unit ID: $adUnitId');
    } else if (Platform.isIOS) {
      // TODO: Replace with your actual iOS rewarded ad unit ID
      adUnitId = 'ca-app-pub-3940256099942544/1712485313'; // Test ID
      // adUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your actual ID
      print('📱 [AdHelper] Using iOS rewarded ad unit ID: $adUnitId');
    } else {
      print('📱 [AdHelper] Unsupported platform for rewarded ads');
    }
    return adUnitId;
  }

  // Native Ad Unit IDs
  static String get nativeAdUnitId {
    if (kIsWeb) return '';

    if (Platform.isAndroid) {
      // TODO: Replace with your actual Android native ad unit ID
      return 'ca-app-pub-3940256099942544/2247696110'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your actual ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your actual iOS native ad unit ID
      return 'ca-app-pub-3940256099942544/3986624511'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your actual ID
    }
    return '';
  }

  // App Open Ad Unit IDs
  static String get appOpenAdUnitId {
    if (kIsWeb) return '';

    if (Platform.isAndroid) {
      // TODO: Replace with your actual Android app open ad unit ID
      return 'ca-app-pub-3940256099942544/3419835294'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your actual ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your actual iOS app open ad unit ID
      return 'ca-app-pub-3940256099942544/5662855259'; // Test ID
      // return 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your actual ID
    }
    return '';
  }
}
