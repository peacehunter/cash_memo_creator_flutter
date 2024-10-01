package com.tuhin.cash_memo_creator;

import android.content.Context;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class PdfSaver {
    private Context context;

    public PdfSaver(Context context) {
        this.context = context;
    }

    public void savePdf(byte[] pdfData) {
        // Get the public Documents directory
        File documentsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS);

        // Ensure the Documents directory exists
        if (!documentsDir.exists()) {
            boolean dirCreated = documentsDir.mkdirs();
            if (!dirCreated) {
                Log.e("PdfSaver", "Failed to create the Documents directory.");
                return;
            }
        }

        // Create the PDF file
        File pdfFile = new File(documentsDir, "GeneratedMemo.pdf");

        // Save the PDF to the file
        try (FileOutputStream fos = new FileOutputStream(pdfFile)) {
            fos.write(pdfData);
            fos.flush();
            Toast.makeText(context, "PDF saved successfully to " + pdfFile.getPath(), Toast.LENGTH_LONG).show();
            Log.i("PdfSaver", "PDF saved successfully to " + pdfFile.getPath());
        } catch (IOException e) {
            Log.e("PdfSaver", "Failed to save PDF: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
