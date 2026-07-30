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
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.tuhin.cash_memo_creator";
    private static final String API_LEVEL_CHANNEL = "com.tuhin.cash_memo_creator/api_level"; // New channel for API level
    private static final String PDF_MIME_TYPE = "application/pdf";
    private static final int REQUEST_WRITE_PERMISSION = 100;

    // Executor thread pool for offloading background Binder IPC and I/O tasks off the main UI thread
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Method Channel for saving, querying, and deleting PDFs
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
                                        // Execute file write off the main UI thread
                                        executor.execute(() -> savePdf(pdfData, folderName, fileName, result));
                                    }

                                } else {
                                    result.error("INVALID_DATA", "PDF data, folder name, or file name is null", null);
                                }
                            } else if (call.method.equals("getSavedPdfs")) {
                                String folderName = call.argument("folderName");
                                if (folderName != null) {
                                    // Execute MediaStore Binder query off the main UI thread to prevent ANR
                                    executor.execute(() -> getSavedPdfs(folderName, result));
                                } else {
                                    result.error("INVALID_DATA", "Folder name is null", null);
                                }
                            } else if (call.method.equals("deleteSavedPdf")) {
                                String filePath = call.argument("filePath");
                                if (filePath != null) {
                                    // Execute file deletion off the main UI thread
                                    executor.execute(() -> deleteSavedPdf(filePath, result));
                                } else {
                                    result.error("INVALID_DATA", "File path is null", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        // Method Channel for getting API level
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

    @Override
    public void onDestroy() {
        executor.shutdown();
        super.onDestroy();
    }

    private void sendSuccess(MethodChannel.Result result, Object data) {
        runOnUiThread(() -> result.success(data));
    }

    private void sendError(MethodChannel.Result result, String errorCode, String errorMessage, Object errorDetails) {
        runOnUiThread(() -> result.error(errorCode, errorMessage, errorDetails));
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
                    sendSuccess(result, "PDF saved successfully to " + uri.toString());
                } else {
                    sendError(result, "WRITE_ERROR", "Unable to open output stream", null);
                }
            } catch (IOException e) {
                e.printStackTrace();
                sendError(result, "WRITE_ERROR", "Error while saving PDF", e.getMessage());
            }
        } else {
            sendError(result, "INSERT_ERROR", "Error while inserting into MediaStore", null);
        }
    }

    private void savePdfToFile(byte[] pdfData, String folderName, String fileName, MethodChannel.Result result) {
        // External storage path for the public Documents directory
        File directory = new File(Environment.getExternalStorageDirectory(), Environment.DIRECTORY_DOCUMENTS + "/" + folderName);

        // Create the directory if it doesn't exist
        if (!directory.exists()) {
            boolean isCreated = directory.mkdirs();
            if (!isCreated) {
                sendError(result, "DIRECTORY_ERROR", "Failed to create directory", null);
                return;
            }
        }

        File pdfFile = new File(directory, fileName);

        try (FileOutputStream fos = new FileOutputStream(pdfFile)) {
            fos.write(pdfData);
            fos.flush();
            sendSuccess(result, "PDF saved successfully to " + pdfFile.getAbsolutePath());
        } catch (IOException e) {
            e.printStackTrace();
            sendError(result, "WRITE_ERROR", "Error while saving PDF", e.getMessage());
        }
    }

    private void getSavedPdfs(String folderName, MethodChannel.Result result) {
        List<Map<String, Object>> pdfList = new ArrayList<>();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Uri uri = MediaStore.Files.getContentUri("external");
            String[] projection = new String[]{
                    MediaStore.Files.FileColumns.DATA,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.DATE_MODIFIED
            };

            String selection = MediaStore.Files.FileColumns.MIME_TYPE + " = ? AND " +
                               MediaStore.Files.FileColumns.RELATIVE_PATH + " LIKE ?";
            String[] selectionArgs = new String[]{
                    PDF_MIME_TYPE,
                    Environment.DIRECTORY_DOCUMENTS + "/" + folderName + "/%"
            };

            try (android.database.Cursor cursor = getContentResolver().query(
                    uri,
                    projection,
                    selection,
                    selectionArgs,
                    MediaStore.Files.FileColumns.DATE_MODIFIED + " DESC"
            )) {
                if (cursor != null) {
                    int dataIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA);
                    int nameIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME);
                    int dateModifiedIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED);

                    while (cursor.moveToNext()) {
                        String path = cursor.getString(dataIndex);
                        String name = cursor.getString(nameIndex);
                        long dateModified = cursor.getLong(dateModifiedIndex) * 1000; // seconds to ms

                        File file = new File(path);
                        if (file.exists() && file.canRead()) {
                            Map<String, Object> pdfMap = new HashMap<>();
                            pdfMap.put("path", path);
                            pdfMap.put("name", name);
                            pdfMap.put("dateModified", dateModified);
                            pdfList.add(pdfMap);
                        }
                    }
                }
                sendSuccess(result, pdfList);
            } catch (Exception e) {
                sendError(result, "QUERY_ERROR", "Failed to query MediaStore: " + e.getMessage(), null);
            }
        } else {
            File directory = new File(Environment.getExternalStorageDirectory(), Environment.DIRECTORY_DOCUMENTS + "/" + folderName);
            if (directory.exists() && directory.isDirectory()) {
                File[] files = directory.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));
                if (files != null) {
                    Arrays.sort(files, (f1, f2) -> Long.compare(f2.lastModified(), f1.lastModified()));

                    for (File file : files) {
                        Map<String, Object> pdfMap = new HashMap<>();
                        pdfMap.put("path", file.getAbsolutePath());
                        pdfMap.put("name", file.getName());
                        pdfMap.put("dateModified", file.lastModified());
                        pdfList.add(pdfMap);
                    }
                }
            }
            sendSuccess(result, pdfList);
        }
    }

    private void deleteSavedPdf(String filePath, MethodChannel.Result result) {
        File file = new File(filePath);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Uri uri = MediaStore.Files.getContentUri("external");
            String selection = MediaStore.Files.FileColumns.DATA + " = ?";
            String[] selectionArgs = new String[]{filePath};

            try {
                int deletedCount = getContentResolver().delete(uri, selection, selectionArgs);
                if (deletedCount > 0) {
                    sendSuccess(result, true);
                } else {
                    if (file.exists() && file.delete()) {
                        sendSuccess(result, true);
                    } else {
                        sendSuccess(result, false);
                    }
                }
            } catch (Exception e) {
                try {
                    if (file.exists() && file.delete()) {
                        sendSuccess(result, true);
                    } else {
                        sendSuccess(result, false);
                    }
                } catch (Exception ex) {
                    sendError(result, "DELETE_ERROR", "Failed to delete: " + e.getMessage(), null);
                }
            }
        } else {
            if (file.exists()) {
                if (file.delete()) {
                    sendSuccess(result, true);
                } else {
                    sendSuccess(result, false);
                }
            } else {
                sendSuccess(result, true);
            }
        }
    }
}
