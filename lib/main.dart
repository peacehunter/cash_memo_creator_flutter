import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CheckRouteObserver.dart';
import 'SettingsPage.dart';
import 'cash_memo.dart';
import 'l10n/gen_l10n/app_localizations.dart';
import 'memo_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  FirebaseAnalytics analytics;
  try {
    await Firebase.initializeApp();
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
   // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  MobileAds.instance.initialize()
      .then((initializationStatus) {
    initializationStatus.adapterStatuses.forEach((key, value) {
      debugPrint('Adapter status for $key: ${value.description}');
    });
  });

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(CashMemoApp());
}

class CashMemoApp extends StatefulWidget {
  @override
  _CashMemoAppState createState() => _CashMemoAppState();
}

class _CashMemoAppState extends State<CashMemoApp> {
  String ?selectedLanguage;
  Locale ?_locale;
  late FirebaseAnalytics analytics ;
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
    analytics = FirebaseAnalytics.instance;

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
        '/': (context) =>  const MemoListScreen(),
        '/edit': (context) => CashMemo(),
        '/settings': (context) => SettingsPage(updateLocale: _updateLocale), // Pass the callback
      },
    );
  }
}
