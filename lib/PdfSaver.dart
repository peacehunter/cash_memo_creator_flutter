import 'dart:typed_data';
import 'package:flutter/services.dart';

class PdfService {
  static const platform = MethodChannel('com.tuhin.cash_memo_creator');

  Future<void> savePdf(Uint8List pdfData, String folderName, String fileName) async {
    try {
      final String result = await platform.invokeMethod('savePdf', {
        'pdfData': pdfData,
        'folderName': folderName, // Pass the folder name
        'fileName': fileName,     // Pass the file name
      });
      print(result); // Log success message
    } on PlatformException catch (e) {
      print("Failed to save PDF: '${e.message}'.");
    }
  }
}
