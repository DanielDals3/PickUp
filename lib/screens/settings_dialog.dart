import 'package:flutter/material.dart';
import '../services/translator_service.dart';
import '../main.dart'; 

class SettingsDialog {
  static void show(
    BuildContext context, {
    required ThemeMode currentThemeMode,
    required String currentNav,
    required Function(ThemeMode) onThemeChanged,
    required Function(String) onNavChanged,
    required VoidCallback onClearCache,
  }) {

    ThemeMode tempThemeMode = currentThemeMode;
    String tempNav = currentNav;

    showDialog(
      context: context,
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Color primaryColor = Theme.of(context).colorScheme.primary;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(Translator.of('settings')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(Translator.of('cache_cleared')),
                              backgroundColor: Theme.of(context).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
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