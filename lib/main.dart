import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
  
  runApp(MyApp(
    initialThemeMode: initialTheme, 
    initialNav: savedNav
  ));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final String initialNav;
  const MyApp({super.key, required this.initialThemeMode, required this.initialNav});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _appThemeMode;
  late String _preferredNav;

  @override
  void initState() {
    super.initState();
    _appThemeMode = widget.initialThemeMode;
    _preferredNav = widget.initialNav;
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      
      themeMode: _appThemeMode,

      // TEMA CHIARO (Il tuo originale)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32), 
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),

      // TEMA SCURO (Il tuo originale)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF81C784),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1C19),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF212121),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // Passiamo lo stato alla nuova HomeScreen
      home: HomeScreen(
        currentThemeMode: _appThemeMode,
        currentNav: _preferredNav,
        onThemeChanged: _updateTheme,
        onNavChanged: _updateNav,
      ),
    );
  }
}