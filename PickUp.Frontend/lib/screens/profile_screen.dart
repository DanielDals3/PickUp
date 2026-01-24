import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pickup/screens/settings_dialog.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile; // Variabile dove salveremo temporaneamente la foto scelta
  final ImagePicker _picker = ImagePicker();

  // Funzione per scattare o scegliere la foto
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Comprimiamo l'immagine per non appesantire il DB dopo
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Errore selezione immagine: $e");
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('http://tuo-ip-server:3000/users/upload-avatar')
    );
    
    // 'file' deve essere uguale al nome dentro @UseInterceptors(FileInterceptor('file'))
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    
    var response = await request.send();
    
    if (response.statusCode == 201) {
      print('Immagine caricata correttamente!');
    }
  }

  // Menu a comparsa dal basso
  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galleria'),
              onTap: () async {
                Navigator.pop(context);
                
                bool canOpen = false;
                if (Platform.isAndroid || Platform.isIOS) {
                  // Su Mobile chiediamo il permesso
                  var status = await Permission.photos.request();
                  canOpen = status.isGranted;
                } else {
                  // Su macOS/Windows/Linux i permessi sono gestiti dalla Sandbox
                  canOpen = true; 
                }

                if (canOpen) _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () async {
                Navigator.pop(context);

                bool canOpen = false;
                if (Platform.isAndroid || Platform.isIOS) {
                  var status = await Permission.camera.request();
                  canOpen = status.isGranted;
                } else {
                  canOpen = true;
                }

                if (canOpen) _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TITOLO GRANDE
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translator.of('profile'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 28),
                      onPressed: () => SettingsDialog.show(
                        context,
                        currentThemeMode: widget.currentThemeMode,
                        currentNav: widget.currentNav,
                        currentLang: widget.currentLang,
                        onThemeChanged: widget.onThemeChanged,
                        onNavChanged: widget.onNavChanged,
                        onLangChanged: widget.onLangChanged,
                        onClearCache: widget.onClearCache,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. HEADER CON FOTO DINAMICA
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showPickerMenu, // Cliccando sull'iconcina camera
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
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
              
              // ... Resto dei tuoi widget (Statistiche, Sport, ecc.) ...
              _buildStatsSection(),
              const SizedBox(height: 30),
              _buildSportsSection(),
              const SizedBox(height: 30),
              _buildMenuSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
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
    );
  }

  Widget _buildSportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Impostazioni"),
        _buildMenuItem(Icons.history, "Storico partite"),
        _buildMenuItem(Icons.notifications_none, "Notifiche"),
        _buildMenuItem(Icons.logout, "Esci", isDestructive: true),
      ],
    );
  }

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