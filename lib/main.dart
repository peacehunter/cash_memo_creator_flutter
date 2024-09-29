import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CheckRouteObserver.dart';
import 'SettingsPage.dart';
import 'cash_memo.dart';
import 'l10n/gen_l10n/app_localizations.dart';
import 'memo_list.dart';

void main() {
  runApp(CashMemoApp());
}

class CashMemoApp extends StatefulWidget {
  @override
  _CashMemoAppState createState() => _CashMemoAppState();
}

class _CashMemoAppState extends State<CashMemoApp> {
  String ?selectedLanguage;
  Locale ?_locale;
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('appLanguage') ?? 'en'; // Default to English
    _locale =  Locale(selectedLanguage ??'bn', ''); // Default locale is Bengali

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadLanguagePreference();

  }
  void _updateLocale(String languageCode) {
    setState(() {
      _locale = Locale(languageCode, '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('bn', ''),
      ],
      locale: _locale, // Use the current locale
      title: 'Cash Memo Generator',
      navigatorObservers: [MyRouteObserver()],
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const MemoListScreen(),
        '/edit': (context) => CashMemo(),
        '/settings': (context) => SettingsPage(updateLocale: _updateLocale), // Pass the callback
      },
    );
  }
}
