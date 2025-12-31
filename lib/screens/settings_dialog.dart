import 'package:flutter/material.dart';
import '../services/translator.dart';

// Importa la chiave globale se l'hai messa in main.dart per la SnackBar
import '../main.dart'; 

class SettingsDialog {
  static void show(
    BuildContext context, {
    required double currentRadius,
    required bool isDarkMode,
    required String currentNav,
    required String unit,
    required Function(double) onRadiusChanged,
    required Function(bool) onThemeChanged,
    required Function(String) onNavChanged,
    required VoidCallback onClearCache,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Variabili locali per gestire lo stato interno del dialogo
        double tempRadius = currentRadius;
        bool localDarkMode = isDarkMode;
        String tempNav = currentNav;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(Translator.of('settings')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DARK MODE
                    SwitchListTile(
                      title: Text(Translator.of('dark_mode')),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      value: localDarkMode,
                      onChanged: (bool value) {
                        setDialogState(() => localDarkMode = value);
                        onThemeChanged(value); // Notifica la Home
                      },
                    ),
                    const Divider(),
                    
                    // RAGGIO DI RICERCA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "${Translator.of('search_radius')}: ${tempRadius.toInt()} $unit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Slider(
                          value: tempRadius,
                          min: 1,
                          max: 50,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (v) {
                            setDialogState(() => tempRadius = v);
                            onRadiusChanged(v); // Notifica la Home
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    // NAVIGATORE
                    ListTile(
                      title: Text(Translator.of('navigator')),
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

                    // PULISCI CACHE
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: Text(Translator.of('clear_cache'), style: const TextStyle(color: Colors.red)),
                      onPressed: () {
                        onClearCache(); // Chiama la funzione passata dalla Home
                        Navigator.pop(context); // Chiude il dialogo

                        scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(Translator.of('cache_cleared')),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}