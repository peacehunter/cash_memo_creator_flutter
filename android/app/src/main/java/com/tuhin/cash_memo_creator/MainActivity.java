package com.tuhin.cash_memo_creator;

import android.content.ContentValues;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;  // Import the Environment class
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.tuhin.cash_memo_creator";
    private static final String PDF_MIME_TYPE = "application/pdf";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("savePdf")) {
                                byte[] pdfData = call.argument("pdfData");
                                String folderName = call.argument("folderName");
                                String fileName = call.argument("fileName");

                                if (pdfData != null && folderName != null && fileName != null) {
                                    // Call the savePdf method
                                    savePdf(pdfData, folderName, fileName, result);
                                } else {
                                    result.error("INVALID_DATA", "PDF data, folder name, or file name is null", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void savePdf(byte[] pdfData, String folderName, String fileName, MethodChannel.Result result) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            // Use MediaStore for API level 29 and above
            savePdfUsingMediaStore(pdfData, folderName, fileName, result);
        } else {
            // Use traditional file I/O for API level 28 and below
            savePdfToFile(pdfData, folderName, fileName, result);
        }
    }

    private void savePdfUsingMediaStore(byte[] pdfData, String folderName, String fileName, MethodChannel.Result result) {
        ContentValues contentValues = new ContentValues();
        contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
        contentValues.put(MediaStore.MediaColumns.MIME_TYPE, PDF_MIME_TYPE);
        contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS + "/" + folderName); // Use the folder name from the argument

        Uri uri = getContentResolver().insert(MediaStore.Files.getContentUri("external"), contentValues);
        if (uri != null) {
            try (OutputStream outputStream = getContentResolver().openOutputStream(uri)) {
                if (outputStream != null) {
                    outputStream.write(pdfData);
                    outputStream.flush();
                    result.success("PDF saved successfully to " + uri.toString());
                } else {
                    result.error("WRITE_ERROR", "Unable to open output stream", null);
                }
            } catch (IOException e) {
                e.printStackTrace();
                result.error("WRITE_ERROR", "Error while saving PDF", e.getMessage());
            }
        } else {
            result.error("INSERT_ERROR", "Error while inserting into MediaStore", null);
        }
    }

    private void savePdfToFile(byte[] pdfData, String folderName, String fileName, MethodChannel.Result result) {
        File directory = new File(Environment.getExternalStorageDirectory(), Environment.DIRECTORY_DOCUMENTS + "/" + folderName);

        // Create the directory if it doesn't exist
        if (!directory.exists()) {
            directory.mkdirs();
        }

        File pdfFile = new File(directory, fileName);

        try (FileOutputStream fos = new FileOutputStream(pdfFile)) {
            fos.write(pdfData);
            fos.flush();
            result.success("PDF saved successfully to " + pdfFile.getAbsolutePath());
        } catch (IOException e) {
            e.printStackTrace();
            result.error("WRITE_ERROR", "Error while saving PDF", e.getMessage());
        }
    }
}
