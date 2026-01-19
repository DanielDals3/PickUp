import 'package:flutter/material.dart';
import 'package:pickup/screens/settings_dialog.dart';
import 'package:pickup/services/translator_service.dart';

class ProfileScreen extends StatelessWidget {
  final String currentLang;
  final ThemeMode currentThemeMode;
  final String currentNav;
  final Function(String) onLangChanged;
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onNavChanged;
  final VoidCallback onClearCache;

  const ProfileScreen({
    super.key,
    required this.currentLang,
    required this.currentThemeMode,
    required this.currentNav,
    required this.onLangChanged,
    required this.onThemeChanged,
    required this.onNavChanged,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Allinea il titolo a sinistra
            children: [
              // 1. TITOLO GRANDE
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 8, 10), // Ridotto padding destro per l'icona
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translator.of('profile'), // Usa il tuo Translator anche qui!
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 28),
                      onPressed: () {
                        // Qui richiami il tuo SettingsDialog
                        SettingsDialog.show(
                          context,
                          currentThemeMode: currentThemeMode,
                          currentNav: currentNav,
                          currentLang: currentLang,
                          onThemeChanged: onThemeChanged,
                          onNavChanged: onNavChanged,
                          onLangChanged: onLangChanged,
                          onClearCache: onClearCache,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. HEADER CON FOTO E INFO
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                        // Tasto rapido per cambiare foto
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Mario Rossi",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Text("Livello Oro • Roma", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. STATISTICHE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn("Partite", "24"),
                      _buildStatDivider(),
                      _buildStatColumn("Vinte", "18"),
                      _buildStatDivider(),
                      _buildStatColumn("Feedback", "4.9"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 4. SEZIONE SPORT
              _buildSectionTitle("I miei Sport"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSportBadge(context, Icons.sports_soccer, "Calcio"),
                    _buildSportBadge(context, Icons.sports_tennis, "Tennis"),
                    _buildSportBadge(context, Icons.sports_volleyball, "Volley"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 5. LISTA MENU
              _buildSectionTitle("Impostazioni"),
              _buildMenuItem(Icons.history, "Storico partite"),
              _buildMenuItem(Icons.notifications_none, "Notifiche"),
              _buildMenuItem(Icons.logout, "Esci", isDestructive: true),

              const SizedBox(height: 100), // Padding per la BottomNavBar
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DI SUPPORTO ---

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSportBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}