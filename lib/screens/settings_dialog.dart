import 'package:flutter/material.dart';
import '../services/translator_service.dart';
import '../main.dart'; 

class SettingsDialog {
  static void show(
    BuildContext context, {
    required ThemeMode currentThemeMode,
    required String currentNav,
    required String currentLang,
    required Function(ThemeMode) onThemeChanged,
    required Function(String) onNavChanged,
    required Function(String) onLangChanged,
    required VoidCallback onClearCache,
  }) {

    ThemeMode tempThemeMode = currentThemeMode;
    String tempNav = currentNav;

    showDialog(
      context: context,
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Calcoliamo la larghezza (es. 90% della larghezza schermo)
            double dialogWidth = MediaQuery.of(context).size.width * 0.9;
            final Color primaryColor = Theme.of(context).colorScheme.primary;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              title: Row(
                children: [
                  Icon(Icons.settings, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(Translator.of('settings')),
                ],
              ),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                     // LINGUA
                     ListTile(
                       leading: Icon(Icons.language, color: primaryColor),
                       title: Text(Translator.of('language')),
                       contentPadding: EdgeInsets.zero,
                       trailing: DropdownButton<String>(
                         value: currentLang,
                         underline: const SizedBox(),
                         onChanged: (String? newVal) {
                           if (newVal != null) {
                             onLangChanged(newVal);
                             setDialogState(() {
                               currentLang = newVal;
                               Translator.currentLanguage = newVal; 
                             });// Rinfresca il dialogo
                           }
                         },
                         items: [
                           DropdownMenuItem(
                             value: 'system', 
                             child: Text(Translator.of('system_language')), // Aggiungi questa chiave nel Translator
                           ),
                           const DropdownMenuItem(value: 'it', child: Text('Italiano 🇮🇹')),
                           const DropdownMenuItem(value: 'en', child: Text('English 🇺🇸')),
                         ],
                       ),
                     ),
                     const Divider(),

                     // DARK MODE
                     ListTile(
                       leading: Icon(Icons.palette_outlined, color: primaryColor),
                       title: Text(Translator.of('theme')),
                       contentPadding: EdgeInsets.zero,
                       trailing: DropdownButton<ThemeMode>(
                         value: tempThemeMode,
                         underline: const SizedBox(),
                         onChanged: (ThemeMode? newValue) {
                           if (newValue != null) {
                             setDialogState(() {
                               tempThemeMode = newValue;
                             });
                             onThemeChanged(newValue);
                           }
                         },
                         items: [
                           DropdownMenuItem(
                             value: ThemeMode.system, 
                             child: Text(Translator.of('theme_system')), // "Automatico"
                           ),
                           DropdownMenuItem(
                             value: ThemeMode.light, 
                             child: Text(Translator.of('theme_light')), // "Chiaro"
                           ),
                           DropdownMenuItem(
                             value: ThemeMode.dark, 
                             child: Text(Translator.of('theme_dark')), // "Scuro"
                           ),
                         ],
                       ),
                     ),
                     const Divider(),

                     // NAVIGATORE PREFERITO
                     ListTile(
                       leading: Icon(Icons.map_outlined, color: primaryColor),
                       title: Text(Translator.of('navigator')),
                       contentPadding: EdgeInsets.zero,
                       trailing: DropdownButton<String>(
                         value: tempNav,
                         underline: const SizedBox(),
                         onChanged: (v) {
                           if (v != null) {
                             setDialogState(() => tempNav = v);
                             onNavChanged(v);
                           }
                         },
                         items: const [
                           DropdownMenuItem(value: 'Google Maps', child: Text('Google')),
                           DropdownMenuItem(value: 'Apple Maps', child: Text('Apple')),
                         ],
                       ),
                    ),
                     const Divider(),

                     // PULISCI CACHE
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: TextButton.icon(
                         icon: const Icon(Icons.delete_sweep, color: Colors.red),
                         label: Text(
                           Translator.of('clear_cache'), 
                           style: const TextStyle(color: Colors.red)
                         ),
                         onPressed: () {
                           onClearCache(); 
                           Navigator.pop(context); 

                           if (scaffoldMessengerKey.currentState != null) {
                             scaffoldMessengerKey.currentState!.hideCurrentSnackBar(); // Pulisce eventuali snackbar vecchi
                             scaffoldMessengerKey.currentState!.showSnackBar(
                               SnackBar(
                                 content: Text(Translator.of('cache_cleared')),
                                 backgroundColor: Colors.redAccent,
                                 behavior: SnackBarBehavior.floating,
                                 duration: const Duration(seconds: 2),
                               ),
                             );
                           }
                         },
                       ),
                     ),
                   ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Translator.of('close'), style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}