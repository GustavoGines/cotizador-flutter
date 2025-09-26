// lib/main.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/convertidor_screen.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Analytics
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_AR');

  // 1) Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) Obtener versión (de pubspec.yaml)
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = packageInfo.version; // +build not needed

  // 3) Analytics: setear user property y loguear apertura
  final analytics = FirebaseAnalytics.instance;
  await analytics.setUserProperty(name: 'app_version', value: appVersion);
  await analytics.logAppOpen();

  // 4) Lanzar app
  runApp(MyApp(analytics: analytics, appVersion: appVersion));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.analytics, required this.appVersion});
  final FirebaseAnalytics? analytics;
  final String appVersion;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cotizador Dólar API',
      debugShowCheckedModeBanner: false,

      // Idiomas
      supportedLocales: const [Locale('es', 'AR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Tema
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      ),

      // Observer de navegación (pantallas vistas)
      navigatorObservers: [
        if (widget.analytics != null)
          FirebaseAnalyticsObserver(analytics: widget.analytics!),
      ],

      home: ConvertidorScreen(
        isDark: _isDark,
        onThemeChanged: (value) => setState(() => _isDark = value),
        appVersion: widget.appVersion, // 👉 pasamos versión
        analytics: widget.analytics, // 👉 opcional para eventos en la UI
      ),
    );
  }
}
