import 'package:flutter/material.dart';
import '../services/translator.dart';
import '../utils/app_utils.dart';

class MainDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final Function(String) onLanguageChanged;

  const MainDrawer({
    super.key,
    required this.onOpenSettings,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              value: Translator.currentLanguage,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onLanguageChanged(newValue);
                  Navigator.pop(context); // Chiude il drawer dopo il cambio
                }
              },
              items: const [
                DropdownMenuItem(value: 'it', child: Text('Italiano 🇮🇹')),
                DropdownMenuItem(value: 'en', child: Text('English 🇺🇸')),
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

          // FOOTER (Sito Web / Credits)
          InkWell(
            onTap: () => AppUtils.launchURL("https://consultits.it"),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Developed by", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(
                    "CONSULTITS",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}