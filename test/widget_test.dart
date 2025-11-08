// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cash_memo_creator/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  setupFirebaseCoreMocks();

  testWidgets('Verify presence of Memos and Saved PDFs tabs',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashMemoApp());

    // Verify that the "Memos" tab is present.
    expect(find.text('Memos'), findsOneWidget);

    // Verify that the "Saved PDFs" tab is present.
    expect(find.text('Saved PDFs'), findsOneWidget);
  });
}

