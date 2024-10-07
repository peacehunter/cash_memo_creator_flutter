import 'dart:async';
import 'package:flutter/services.dart';

class AndroidAPILevel {
  static const platform = MethodChannel('com.tuhin.cash_memo_creator/api_level');

  static Future<int> getApiLevel() async {
    try {
      final int apiLevel = await platform.invokeMethod('getApiLevel');
      return apiLevel;
    } on PlatformException catch (e) {
      print("Failed to get API level: '${e.message}'.");
      return -1; // Handle the error appropriately
    }
  }
}
