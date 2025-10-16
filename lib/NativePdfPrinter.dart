import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativePdfPrinter {
  printPdf(BuildContext? context) async {
    if (kIsWeb) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Native PDF printing is not supported on the web.')));
      }
      return;
    }
    const platform = MethodChannel('samples.flutter.dev/battery');
    try {
      final result = await platform.invokeMethod<int>('getBatteryLevel');
    } on PlatformException catch (e) {
      print("Failed to get battery level: '\${e.message}'.");
    }
  }
}