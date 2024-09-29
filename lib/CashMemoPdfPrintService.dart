import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CashMemoService {
  static const platform = MethodChannel('com.tuhin.cash_memo/pdf_print');

  Future<void> requestPermissions() async {

    if (await Permission.storage.request().isGranted) {
      // Permission granted
      print('Storage permission granted');
    } else {
      // Handle the case when permission is denied
      print('Storage permission denied');
      // Optionally, prompt the user to go to settings
      if (await Permission.storage.isPermanentlyDenied) {
        // Open app settings
        openAppSettings();
      }
    }
  }

  Future<void> generateCashMemoInNative(String text) async {
    await requestPermissions(); // Request permissions before generating PDF

    try {
      // Load the font from Flutter's assets
      ByteData fontData = await rootBundle.load('assets/fonts/NotoSansBengali.ttf');
      List<int> fontBytes = fontData.buffer.asUint8List();

      // Call the platform channel to invoke the pdfPrint method in Java
      final result = await platform.invokeMethod('pdf_print', {
        'text': text, // Pass any additional data you need here
        'fontBytes': fontBytes, // Pass the font bytes to native Android
      });

      print(result); // Handle the result or success message from Java
    } on PlatformException catch (e) {
      print("Failed to generate PDF: ${e.message}");
    }
  }
}
