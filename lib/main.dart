import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
  MobileAds.instance.initialize().then((initializationStatus) {
    initializationStatus.adapterStatuses.forEach((key, value) {
      debugPrint('Adapter status for $key: ${value.description}');
    });
  });

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const CashMemoApp());
}

class CashMemoApp extends StatefulWidget {
  const CashMemoApp({super.key});

  @override
  _CashMemoAppState createState() => _CashMemoAppState();
}

class _CashMemoAppState extends State<CashMemoApp> with WidgetsBindingObserver {
  String? selectedLanguage;
  Locale? _locale;
  late FirebaseAnalytics analytics;
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedLanguage =
        prefs.getString('appLanguage') ?? 'en'; // Default to English
    _locale = Locale(selectedLanguage ?? 'bn', ''); // Default locale is Bengali

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadLanguagePreference();
    analytics = FirebaseAnalytics.instance;
    WidgetsBinding.instance.addObserver(this);
    // Preload an App Open Ad
    AppOpenAdManager.instance.loadAd();
  }

  void _updateLocale(String languageCode) {
    setState(() {
      _locale = Locale(languageCode, '');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Show App-open ad when app returns to foreground
      AppOpenAdManager.instance.showAdIfAvailable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      builder: (context, widget) {
        // Global error boundary for layout issues
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Material(
            child: Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please restart the app',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget ?? Container();
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0f172a), // Deep slate for authority
          primary: const Color(0xFF0f172a), // Deep slate blue
          secondary: const Color(0xFF059669), // Professional emerald
          tertiary: const Color(0xFF475569), // Sophisticated gray
          surface: const Color(0xFFffffff),
          background: const Color(0xFFf8fafc),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0f172a),
          outline: const Color(0xFFe2e8f0),
          surfaceVariant: const Color(0xFFf1f5f9),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0f172a),
          foregroundColor: Colors.white,
          shadowColor: Color(0x0A000000),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.25,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shadowColor: Color(0x05000000),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(
              color: Color(0xFFe2e8f0),
              width: 1,
            ),
          ),
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF0f172a),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
              fontFamily: 'Inter',
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0f172a),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(
              color: Color(0xFFe2e8f0),
              width: 1.5,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
              fontFamily: 'Inter',
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF0f172a), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFef4444), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Color(0xFF64748b),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          hintStyle: TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0f172a),
            letterSpacing: -1.0,
            fontFamily: 'Inter',
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
            letterSpacing: -0.75,
            fontFamily: 'Inter',
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0f172a),
            letterSpacing: -0.25,
            fontFamily: 'Inter',
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
            fontFamily: 'Inter',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF334155),
            height: 1.5,
            fontFamily: 'Inter',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748b),
            height: 1.4,
            fontFamily: 'Inter',
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0f172a),
            letterSpacing: 0.1,
            fontFamily: 'Inter',
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFe2e8f0),
          thickness: 1,
          space: 1,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFf1f5f9),
          selectedColor: Color(0xFF0f172a),
          labelStyle: TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MemoListScreen(),
        '/edit': (context) => const CashMemo(),
        '/settings': (context) =>
            SettingsPage(updateLocale: _updateLocale), // Pass the callback
      },
    );
  }
}
