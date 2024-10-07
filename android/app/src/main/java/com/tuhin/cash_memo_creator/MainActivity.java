package com.tuhin.cash_memo_creator;

import android.Manifest;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.tuhin.cash_memo_creator";
    private static final String API_LEVEL_CHANNEL = "com.tuhin.cash_memo_creator/api_level"; // New channel for API level
    private static final String PDF_MIME_TYPE = "application/pdf";
    private static final int REQUEST_WRITE_PERMISSION = 100;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Existing Method Channel for saving PDF
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("savePdf")) {
                                byte[] pdfData = call.argument("pdfData");
                                String folderName = call.argument("folderName");
                                String fileName = call.argument("fileName");

                                if (pdfData != null && folderName != null && fileName != null) {
                                    // Check write permissions for API 23+
                                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q &&
                                            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {

                                        // API level is 29 or lower and permission is not granted
                                        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, REQUEST_WRITE_PERMISSION);

                                    } else {
                                        // Call the savePdf method for API level 30 or higher, or when permission is granted
                                        savePdf(pdfData, folderName, fileName, result);
                                    }

                                } else {
                                    result.error("INVALID_DATA", "PDF data, folder name, or file name is null", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        // New Method Channel for getting API level
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), API_LEVEL_CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("getApiLevel")) {
                                result.success(Build.VERSION.SDK_INT); // Return the API level
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    // Handle permission result
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_WRITE_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted
                Toast.makeText(this, "Write permission granted", Toast.LENGTH_SHORT).show();
            } else {
                // Permission denied
                Toast.makeText(this, "Write permission is required to save PDF", Toast.LENGTH_LONG).show();
            }
        }
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
        // External storage path for the public Documents directory
        File directory = new File(Environment.getExternalStorageDirectory(), Environment.DIRECTORY_DOCUMENTS + "/" + folderName);

        // Create the directory if it doesn't exist
        if (!directory.exists()) {
            boolean isCreated = directory.mkdirs();
            if (!isCreated) {
                result.error("DIRECTORY_ERROR", "Failed to create directory", null);
                return;
            }
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
