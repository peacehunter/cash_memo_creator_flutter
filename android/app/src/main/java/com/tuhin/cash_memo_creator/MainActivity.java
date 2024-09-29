package com.tuhin.cash_memo_creator;

import android.content.Context;
import android.os.Environment;
import android.util.Log;

import androidx.annotation.NonNull;

import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;

import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.io.font.PdfEncodings;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.tuhin.cash_memo/pdf_print";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("pdf_print")) {
                                String text = call.argument("text");
                                byte[] fontBytes = call.argument("fontBytes");

                                try {
                                    pdfPrint(text, fontBytes);
                                    result.success("PDF generated successfully");
                                } catch (Exception e) {
                                    Log.e("PDF Print", "Error generating PDF", e);
                                    result.error("PDF_ERROR", "Failed to generate PDF", e.getMessage());
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void pdfPrint(String text, byte[] fontBytes) throws IOException {
        // Specify the output path
        String outputPath = getApplicationContext().getExternalFilesDir(null) + "/your_output.pdf";
        File pdfFile = new File(outputPath);

        // Create the PDF document
        PdfWriter writer = new PdfWriter(new FileOutputStream(pdfFile));
        PdfDocument pdfDocument = new PdfDocument(writer);
        Document document = new Document(pdfDocument);

        // Load the font from the byte array
       // com.itextpdf.kernel.font.PdfFont font = PdfFontFactory.createFont(fontBytes, "UTF-8", true);
        com.itextpdf.kernel.font.PdfFont  font = PdfFontFactory.createFont(fontBytes, PdfEncodings.IDENTITY_H);


        // Add content to the PDF
        Paragraph paragraph = new Paragraph(text)
                .setFont(font)
                .setFontSize(12); // Set a font size that works well for both languages

        document.add(paragraph);
        document.close();
    }
}
