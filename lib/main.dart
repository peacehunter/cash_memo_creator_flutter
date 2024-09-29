import 'package:flutter/material.dart';
import 'CheckRouteObserver.dart';
import 'memo_list.dart';
import 'cash_memo.dart';
import 'SettingsPage.dart'; // Import the settings page
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cash_memo_creator/l10n/gen_l10n/app_localizations.dart';

void main() {
  runApp(CashMemoApp());
}

class CashMemoApp extends StatelessWidget {
  final MyRouteObserver myRouteObserver = MyRouteObserver();

  CashMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate, // Your generated localization delegate

        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,  // Adds Cupertino localization support
        GlobalWidgetsLocalizations.delegate,

      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('bn', ''), // Bengali
      ],

      locale: const Locale('bn', ''), // Set the locale to Bengali

      title: 'Cash Memo Generator',
      navigatorObservers: [myRouteObserver],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MemoListScreen(),
        '/edit': (context) => CashMemo(),
        '/settings': (context) => SettingsPage(), // Add the settings route
      },
    );
  }
}
