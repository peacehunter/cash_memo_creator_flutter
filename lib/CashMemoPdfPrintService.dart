import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class CashMemoService {
  static const platform = MethodChannel('com.tuhin.cash_memo/pdf_print');

  Future<void> requestPermissions() async {
    if (kIsWeb) {
      // Web: no permissions available or required
      return;
    }
    if (await Permission.storage.request().isGranted) {
      print('Storage permission granted');
    } else {
      print('Storage permission denied');
      if (await Permission.storage.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  Future<void> generateCashMemoInNative(String text) async {
    await requestPermissions(); // Request permissions before generating PDF
    if (kIsWeb) {
      // Not supported on web platform
      throw UnimplementedError(
          'Native PDF generation is not supported on web.');
    }
    try {
      ByteData fontData =
          await rootBundle.load('assets/fonts/NotoSansBengali.ttf');
      List<int> fontBytes = fontData.buffer.asUint8List();
      final result = await platform.invokeMethod('pdf_print', {
        'text': text,
        'fontBytes': fontBytes,
      });
      print(result);
    } on PlatformException catch (e) {
      print("Failed to generate PDF: \${e.message}");
    }
  }
}
