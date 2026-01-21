import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // --- CARICAMENTO TEMA ---
  final String? savedTheme = prefs.getString('theme_mode');
  ThemeMode initialTheme = ThemeMode.system;
  if (savedTheme == 'ThemeMode.light') initialTheme = ThemeMode.light;
  if (savedTheme == 'ThemeMode.dark') initialTheme = ThemeMode.dark;

  // --- CARICAMENTO NAVIGATORE ---
  String? savedNav = prefs.getString('preferred_nav');

  // 2. Se è la prima volta (null), decidiamo in base al sistema operativo
  if (savedNav == null) {
    if (Platform.isIOS) {
      savedNav = 'Apple Maps';
    } else {
      savedNav = 'Google Maps';
    }
    // Salviamo subito la scelta predefinita per il futuro
    await prefs.setString('preferred_nav', savedNav);
  }

  // --- CARICAMENTO LINGUA ---
  String? savedLanguage = prefs.getString('language_code');
  Locale? initialLocale;
  if (savedLanguage != null && savedLanguage != 'system') {
    initialLocale = Locale(savedLanguage);
  }

  runApp(
    MyApp(
      initialThemeMode: initialTheme,
      initialNav: savedNav,
      initialLocale: initialLocale,
    ),
  );
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final String initialNav;
  final Locale? initialLocale;

  const MyApp({
    super.key,
    required this.initialThemeMode,
    required this.initialNav,
    required this.initialLocale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _appThemeMode;
  late String _preferredNav;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _appThemeMode = widget.initialThemeMode;
    _preferredNav = widget.initialNav;
    _locale = widget.initialLocale;
  }

  // Funzione per aggiornare e SALVARE il tema
  void _updateTheme(ThemeMode mode) async {
    setState(() => _appThemeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  // Funzione per aggiornare e SALVARE il navigatore
  void _updateNav(String nav) async {
    setState(() => _preferredNav = nav);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_nav', nav);
  }

  // Funzione per aggiornare e SALVARE la lingua
  void _updateLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (languageCode == null || languageCode == 'system') {
        _locale = null; // Torna a lingua di sistema
        prefs.setString('language_code', 'system');
      } else {
        _locale = Locale(languageCode);
        prefs.setString('language_code', languageCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      // Prende la lingua del dispositivo (es. 'it' o 'en')
      final deviceLocale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      // Se il device è in una lingua che non abbiamo, usiamo 'it' come fallback
      Translator.currentLanguage = (deviceLocale == 'en') ? 'en' : 'it';
    } else {
      Translator.currentLanguage = _locale!.languageCode;
    }

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,

      locale: _locale,
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: _appThemeMode,

      // TEMA CHIARO
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          primary: const Color(0xFF00C853),
          secondary: const Color(0xFF263238),
          surface: const Color(0xFFF8FAF8),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00C853),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00C853),
          foregroundColor: Colors.white,
        ),
      ),

      // TEMA SCURO
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          surface: const Color(0xFF0A0C0A),
          primary: const Color(0xFF00E676),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121412),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // Passiamo lo stato alla nuova HomeScreen
      home: HomeScreen(
        currentThemeMode: _appThemeMode,
        currentNav: _preferredNav,
        currentLocale: _locale,
        onThemeChanged: _updateTheme,
        onNavChanged: _updateNav,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}
