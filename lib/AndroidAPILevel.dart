import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AndroidAPILevel {
  static const platform =
      MethodChannel('com.tuhin.cash_memo_creator/api_level');

  static Future<int> getApiLevel() async {
    if (kIsWeb) {
      // Not applicable to web
      return -1;
    }
    try {
      final int apiLevel = await platform.invokeMethod('getApiLevel');
      return apiLevel;
    } on PlatformException catch (e) {
      print("Failed to get API level: '\${e.message}'.");
      return -1;
    }
  }
}
