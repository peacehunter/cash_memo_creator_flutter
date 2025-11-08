import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_ads/AppOpenAdManager.dart';

import 'CheckRouteObserver.dart';
import 'SettingsPage.dart';
import 'cash_memo.dart';
import 'l10n/gen_l10n/app_localizations.dart';
import 'memo_list.dart';
import 'auth_gate.dart';
import 'settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Only include Firebase imports if not web
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseAnalytics? analytics;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }
  } catch (e) {
    print("Failed to initialize Firebase: \$e");
  }
  if (kIsWeb) {
    // Now, set Firebase Auth persistence for web after Firebase is initialized.
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } else {
    unawaited(MobileAds.instance.initialize());
  }
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  analytics = FirebaseAnalytics.instance;
  if (!kIsWeb) {
    MobileAds.instance.initialize().then((initializationStatus) {
      initializationStatus.adapterStatuses.forEach((key, value) {
        debugPrint('Adapter status for \$key: \${value.description}');
      });
    });
  }
  runApp(const CashMemoApp());
}

class CashMemoApp extends StatefulWidget {
  const CashMemoApp({super.key});

  @override
  CashMemoAppState createState() => CashMemoAppState();
}

class CashMemoAppState extends State<CashMemoApp> with WidgetsBindingObserver {
  String? selectedLanguage;
  Locale? _locale = const Locale('en');
  FirebaseAnalytics? analytics;
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedLanguage =
        prefs.getString('appLanguage') ?? 'en'; // Default to English
    _locale = Locale(selectedLanguage ?? 'bn'); // FIX: country omitted
    debugPrint(
        'loadLanguagePreference: selectedLanguage=[0m$selectedLanguage, _locale=$_locale');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadLanguagePreference();
    if (!kIsWeb) {
      analytics = FirebaseAnalytics.instance;
    }
    WidgetsBinding.instance.addObserver(this);
    // Preload an App Open Ad
    AppOpenAdManager.instance.loadAd();
  }

  void _updateLocale(String languageCode) {
    setState(() {
      _locale = Locale(languageCode); // FIX: country omitted
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Show App-open ad when app returns to foreground
      AppOpenAdManager.instance.showIfAvailable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('CashMemoAppState.build() _locale=[0m$_locale');
    if (_locale == null) {
      // Show a loading indicator while locale is being determined
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    // Fix for web: ensure all routes are compatible, and platform plugins are no-ops
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      locale: _locale,
      title: 'Cash Memo Generator',
      navigatorObservers: [MyRouteObserver()],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0f172a),
          primary: const Color(0xFF0f172a),
          secondary: const Color(0xFF059669),
          tertiary: const Color(0xFF475569),
          surface: const Color(0xFFffffff),
          background: const Color(0xFFf8fafc),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0f172a),
          outline: const Color(0xFFe2e8f0),
          surfaceVariant: const Color(0xFFf1f5f9),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/edit': (context) =>
            const Scaffold(body: Center(child: Text('Edit placeholder'))),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
