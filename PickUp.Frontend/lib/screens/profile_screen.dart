import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pickup/core/api_config.dart';
import 'package:pickup/models/sport.dart';
import 'package:pickup/pages/login_page.dart';
import 'package:pickup/screens/settings_dialog.dart';
import 'package:pickup/services/auth_service.dart';
import 'package:pickup/services/sport_service.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:pickup/utils/sport_utils.dart';
import 'package:provider/provider.dart';

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
  List<Sport> userSports = [];      // Sport dell'utente
  List<Sport> allSports = [];       // Tutti gli sport disponibili
  bool isLoading = true;
  bool _wasLoggedIn = false;  // Per tracciare i cambiamenti di stato del login/logout

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isLoggedIn) return;

    try {
      // Qui chiamerai i tuoi servizi API reali
      // const userId = "123";
      // val user = await apiService.getUser(userId);
      var sports = SportService().allSports;

      setState(() {
        // Esempio dati mockati (sostituisci con chiamate http)
        userSports = [Sport(id: 1, name: "Calcio")];
        allSports = sports;
        isLoading = false;
      });
    } catch (e) {
      print("Errore caricamento: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

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
      Uri.parse('${ApiConfig.url}/users/upload-avatar')
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

  Widget _buildGuestView() {
    return Scaffold(
      body: Padding( // Corretto Center con padding non valido
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              Translator.of('profile_guest_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              Translator.of('profile_guest_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Text(Translator.of('login_btn').toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Carica i dati solo se passa da NON loggato a LOGGATO
    if (auth.isLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    } 
    // Se l'utente fa logout, resettiamo il flag per il prossimo login
    else if (!auth.isLoggedIn && _wasLoggedIn) {
      _wasLoggedIn = false;
    }

    if (!auth.isLoggedIn) {
      return _buildGuestView();
    }

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
              _buildMenuSection(auth),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSportDialog() {
    List<Sport> tempSelected = List.from(userSports);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- TITOLO ---
                  Text(
                    Translator.of('choose_your_sports'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- LISTA SCROLLABILE ---
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: allSports.map((sport) {
                          final bool isSelected = tempSelected.any((s) => s.id == sport.id);
                          final Color sportColor = SportUtils.getIconColor(sport.name);

                          return FilterChip(
                            label: Text(Translator.of(sport.name.toLowerCase())),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  if (!tempSelected.any((s) => s.id == sport.id)) {
                                    tempSelected.add(sport);
                                  }
                                } else {
                                  tempSelected.removeWhere((s) => s.id == sport.id);
                                }
                              });
                            },
                            // Estetica migliorata
                            avatar: Icon(
                              SportUtils.getIconData(sport.name),
                              size: 18,
                              color: isSelected ? Colors.white : sportColor,
                            ),
                            selectedColor: sportColor,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TASTO CONFERMA ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Qui aggiorniamo la UI principale
                        setState(() {
                          userSports = List.from(tempSelected);
                        });
                        
                        // TODO: Invia la lista aggiornata al Backend
                        // _updateSportsOnServer(userSports);
                        
                        Navigator.pop(context); // Chiude il dialog solo qui!
                      },
                      child: Text(
                        Translator.of('confirm').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSportsSection() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(Translator.of('mysports')),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAddSportDialog,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: userSports.map((sport) => _buildSportBadge(sport)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSportBadge(Sport sport) {
    final Color sportColor = SportUtils.getIconColor(sport.name);

    return Chip(
      avatar: Icon(
        SportUtils.getIconData(sport.name), 
        size: 16, 
        color: sportColor
      ),
      label: Text(
        Translator.of(sport.name.toLowerCase()),
        style: TextStyle(
          color: sportColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: sportColor.withValues(alpha: 0.1),
      side: BorderSide(color: sportColor.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildMenuSection(AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Translator.of('settings')),
        _buildMenuItem(Icons.history, "Storico partite"),
        _buildMenuItem(Icons.notifications_none, "Notifiche"),
        _buildMenuItem(
          Icons.logout, 
          "Esci", 
          isDestructive: true,
          onTap: () async {
            await auth.logout();
            // Lo stato cambierà e il build mostrerà automaticamente la GuestView
          },
        ), 
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

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}