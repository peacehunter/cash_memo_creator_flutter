

package com.tuhin.cash_memo_creator;

import io.flutter.embedding.android.FlutterActivity;

import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;

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
                            // Handle method calls from Flutter
                            Log.d("flutter_test", "Method called: " + call.method);

                            if (call.method.equals("pdf_print")) {
                                pdfPrint();
                                result.success("PDF print triggered.");
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void pdfPrint() {
        Log.d("flutter_test", "PDF print method called");
        // Your PDF printing logic here
    }
}
