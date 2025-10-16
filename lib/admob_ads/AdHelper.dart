import 'package:flutter/foundation.dart';
// Don't import dart:io for web
// import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return '';
    }
    // import 'dart:io' only valid for non-web: Platform.isAndroid/iOS
    // The below code WILL NOT run on web since AdHelper should only be used when !kIsWeb
    // ignore: undefined_prefixed_name, dead_code
    // ignore_for_file: unnecessary_statements
    // No implementation for web
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return '';
    }
    return '';
  }

  static String get appOpenAdUnitId {
    if (kIsWeb) {
      return '';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) {
      return '';
    }
    return '';
  }
}
