import 'package:flutter/material.dart';
import '../services/translator_service.dart';
import '../utils/app_utils.dart';

class MainDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final Locale? currentLocale;
  final Function(String?) onLanguageChanged;

  const MainDrawer({
    super.key,
    this.currentLocale,
    required this.onOpenSettings,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {

    final String currentLangCode = currentLocale?.languageCode ?? 'system';

    return Drawer(
      child: Column( // Usiamo Column per poter mettere il footer in fondo
        children: [
          // HEADER
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Center(
              child: Text(
                'PickUp',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // CAMBIO LINGUA
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
            title: Text(Translator.of('language')),
            trailing: DropdownButton<String>(
              value: currentLangCode,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                  onLanguageChanged(newValue);
                  Navigator.pop(context); // Chiude il drawer dopo il cambio
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

          const Spacer(),
          const Divider(height: 1),

          // IMPOSTAZIONI
          ListTile(
            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary),
            title: Text(Translator.of('settings')),
            onTap: () {
              Navigator.pop(context); // Chiude il drawer
              onOpenSettings();       // Chiama la funzione della Home
            },
          ),

          const Divider(height: 1),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Developed by", 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), 
                      fontSize: 10,
                      letterSpacing: 0.5,
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "CONSULTITS",
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 2.5, 
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "v 1.0.0",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ], // Fine della Column del Drawer
      ),
    );
  }
}