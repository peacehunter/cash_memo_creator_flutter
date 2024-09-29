import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class NativePdfPrinter{
  printPdf() async {
    const platform = MethodChannel('samples.flutter.dev/battery');

    try {
      final result = await platform.invokeMethod<int>('getBatteryLevel');
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }

  }
}