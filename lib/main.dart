import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'constants/translator.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PickUpApp(),
  ));
}

class PickUpApp extends StatefulWidget {
  const PickUpApp({super.key});

  @override
  State<PickUpApp> createState() => _PickUpAppState();
}

class _PickUpAppState extends State<PickUpApp> {
  bool _isDarkMode = false; // Stato globale del tema

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Questa riga permette all'app di cambiare tema istantaneamente
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        colorSchemeSeed: Colors.blueAccent,
        useMaterial3: true,
      ),
      // Passiamo lo stato e la funzione per cambiarlo alla mappa
      home: PickUpMap(
        isDarkMode: _isDarkMode,
        onThemeChanged: (bool val) {
          setState(() {
            _isDarkMode = val;
          });
        },
      ),
    );
  }
}

class PickUpMap extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const PickUpMap({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  State<PickUpMap> createState() => _PickUpMapState();
}

class _PickUpMapState extends State<PickUpMap> {
  static const LatLng milanDefault = LatLng(45.4642, 9.1900);
  
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  final List<String> _availableSports = ['basketball', 'soccer', 'tennis', 'volleyball', 'beachvolleyball'];
  final Set<String> _selectedSports = {}; // Inizia vuoto = mostra tutto
  Set<String> _lastSearchedSports = {}; // Memorizza i filtri dell'ultima chiamata API

  LatLng _currentMapCenter = milanDefault;
  bool _showSearchButton = false;
  bool _isLoading = false;

  double _searchRadius = 10.0; // Per il raggio di ricerca
  String _selectedUnit = 'km'; // Per l'unità di misura
  String _preferredNav = 'Google Maps'; // Per il navigatore

  @override
  void initState() {
    super.initState();
    _initializeLocation(true);
  }

  List<Marker> get _displayedMarkers {  
    if (_selectedSports.isEmpty) {
      return _markers;
    }

    return _markers.where((marker) {
    // Recuperiamo lo sport che abbiamo salvato nella 'key' del marker
    // Lo facciamo castando la key a ValueKey<String>
    final String? markerSport = (marker.key as ValueKey<String>?)?.value;
    
    // Teniamo il marker solo se il suo sport è tra quelli selezionati
    return _selectedSports.contains(markerSport);
  }).toList();
  }

  Future<void> _initializeLocation(bool isInitial) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Controlla se i servizi GPS del telefono sono accesi
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _loadDefaultLocation();
      return;
    }

    // 2. Controlla lo stato del permesso
    permission = await Geolocator.checkPermission();

    // 3. Se il permesso è stato negato in precedenza (o è la prima volta), chiedilo
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _loadDefaultLocation();
        return;
      }
    }

    // 4. Se il permesso è negato per sempre (l'utente ha scelto "Non chiedere più")
    if (permission == LocationPermission.deniedForever) {
      _loadDefaultLocation();
      return;
    }

    // 5. Se siamo qui, il permesso è concesso (granted o whileInUse)
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      LatLng userLocation = LatLng(position.latitude, position.longitude);
      
      _moveToLocation(userLocation, isInitial);

    } catch (e) {
      _loadDefaultLocation();
    }
  }

  void _loadDefaultLocation() {
    _moveToLocation(milanDefault);
  }

  void _moveToLocation(LatLng target, [bool isInitial = false]) {
    if (!mounted) return;

      setState(() => _currentMapCenter = target);
      _mapController.move(target, 14.5);
      
      // Ritardo per permettere al controller di aggiornare i visibleBounds
      Future.delayed(const Duration(milliseconds: 400), () {
        
        if (isInitial) {
          _fetchMultiSportCourts();
        }
        else {
          setState(() {
            _showSearchButton = true;
          });
        }
      });
    
  }

  // Funzione per assegnare l'icona corretta in base allo sport
  Widget _getMarkerIcon(String? sportTag) {
    IconData iconData;
    Color iconColor;

    List<String> sports = sportTag?.split(';') ?? ['unknown'];

    if (sports.length > 1) {
      // Prendiamo i primi 4
      final displayedSports = sports.take(4).toList();
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blueGrey, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(4), // Aumentato leggermente per dare aria
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center( // Centra il blocco icone
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Prima riga
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMiniIcon(displayedSports[0]),
                    if (displayedSports.length >= 2) _buildMiniIcon(displayedSports[1]),
                  ],
                ),
                // Seconda riga (solo se ci sono 3 o 4 sport)
                if (displayedSports.length > 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniIcon(displayedSports[2]),
                      if (displayedSports.length == 4) _buildMiniIcon(displayedSports[3]),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    String sport = sports.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(_getIconDataForSport(sport), color: _getIconColorForSport(sport), size: 28),
    );
  }

  Widget _buildMiniIcon(String sport) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Icon(
        _getIconDataForSport(sport), 
        size: 12, // Leggermente più grande del tuo 10 per visibilità
        color: _getIconColorForSport(sport)
      ),
    );
  }

  IconData _getIconDataForSport(String sport) {
    switch (sport.trim()) {
      case 'unknown':
        return Icons.device_unknown;
      case 'basketball':
        return Icons.sports_basketball;
      case 'soccer':
      case 'football':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'beachvolleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports_handball; 
    }
  }

  Color _getIconColorForSport(String sport) {
    switch (sport.trim()) {
      case 'unknown': return Colors.red;
      case 'basketball': return Colors.orange;
      case 'soccer': return Colors.green[800]!;
      case 'tennis': return Colors.lime[700]!;
      case 'volleyball': return Colors.blue[700]!;
      case 'beachvolleyball': return Colors.amber[800]!;
      default: return Colors.grey;
    }
  }

  Future<void> _fetchMultiSportCourts() async {
    if (!mounted) return;

    final bounds = _mapController.camera.visibleBounds;
    if (bounds.south == bounds.north) return; // Protezione se i bounds non sono pronti

    setState(() {
      _isLoading = true;
      _showSearchButton = false;
      _markers = [];
    });

    String sportsQuery = _selectedSports.isEmpty 
        ? _availableSports.join('|') 
        : _selectedSports.join('|');

    // Query che cerca diversi tipi di sport contemporaneamente
    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=[out:json];nw["sport"~"$sportsQuery"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});out center;'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Marker> newMarkers = [];

        for (var element in data['elements']) {
          double? lat = element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
          double? lon = element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();
          
          if (lat != null && lon != null) {
            final String id = element['id'].toString();
            final Map<String, dynamic> tags = element['tags'] ?? {};
            final String sportType = tags['sport'] ?? "unknown";

            newMarkers.add(
              Marker(
                key: ValueKey("${sportType}_$id"),
                point: LatLng(lat, lon),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showCourtDetails(lat, lon, tags),
                  child: _getMarkerIcon(sportType),
                ),
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _markers = newMarkers;
            _showSearchButton = false;
            _lastSearchedSports = Set.from(_selectedSports);
          });
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCourtDetails(double lat, double lon, Map<String, dynamic> tags) {
    String name = tags['name'] ?? Translator.of('unknown');
    String sport = (tags['sport'] ?? Translator.of('unknown')).toString().toUpperCase();
    
    // 1. Recupero Indirizzo
    String address = _formatAddress(tags);
    
    // 2. Recupero Link (controlla più tag possibili dove OSM salva i link)
    String? website = tags['website'] ?? tags['contact:website'] ?? tags['facebook'] ?? tags['url'];
    String? phone = tags['phone'] ?? tags['contact:phone'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(sport, style: TextStyle(fontSize: 14, color: Colors.blueAccent[700], fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // Riga Indirizzo
            _buildDetailRow(Icons.location_on, Translator.of('address'), address),
            
            // Riga Superficie (già presente)
            _buildDetailRow(Icons.layers, Translator.of('surface'), tags['surface'] ?? Translator.of('not_specified')),

            // 3. Riga Sito Web (mostrata solo se esiste)
            if (website != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    _launchURL(website);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.language, size: 20, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text("${Translator.of('website')}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(website, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),

            // 4. Riga Telefono (mostrata solo se esiste)
            if (phone != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                    _launchURL("tel:$cleanPhone");
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.green),
                      const SizedBox(width: 12),
                      Text("${Translator.of('phone')}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(phone, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),
            
            // Bottone Navigazione (Google Maps)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () {
                _openMap(lat, lon);
              },
              icon: const Icon(Icons.directions, color: Colors.white),
              label: Text(Translator.of('take_me_here'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Allinea l'icona in alto se il testo va a capo
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey[600]), // Icona a sinistra
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold) // Etichetta in grassetto
                  ),
                  TextSpan(text: value), // Valore (es. la via o il tipo di superficie)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street'] ?? '';
    final housenumber = tags['addr:housenumber'] ?? '';
    final city = tags['addr:city'] ?? '';
    
    if (street.isEmpty && city.isEmpty) return Translator.of('address_not_available');
    
    // Unisce i pezzi: "Via Roma, 10, Milano"
    return [
      street,
      if (housenumber.isNotEmpty) housenumber,
      if (city.isNotEmpty) city
    ].join(', ');
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    }
  }

  Future<void> _openMap(double lat, double lon) async {
    Uri url;

    if (_preferredNav == 'Apple Maps') {
      // Forza Apple Maps (utile se l'utente è su iOS o preferisce il link Apple)
      url = Uri.parse("https://maps.apple.com/?q=$lat,$lon");
    } else {
      // Default: Google Maps (funziona tramite browser su iOS o app su Android)
      url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = Uri.parse("geo:$lat,$lon?q=$lat,$lon");
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl);
      } else {
        throw Translator.of('error_open_map');
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Usiamo StatefulBuilder per permettere ai widget (switch, slider) 
        // di aggiornarsi graficamente mentre il popup è aperto
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.blueAccent),
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
                      value: widget.isDarkMode,
                      onChanged: (bool value) {
                        widget.onThemeChanged(value);
                        setDialogState(() {}); // Aggiorna il popup
                      },
                    ),
                    const Divider(),
                    
                    // RAGGIO DI RICERCA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("${Translator.of('search_radius')}: ${_searchRadius.toInt()} $_selectedUnit"),
                        ),
                        Slider(
                          value: _searchRadius,
                          min: 1, max: 50,
                          onChanged: (v) {
                            setState(() => _searchRadius = v); // Aggiorna la mappa
                            setDialogState(() {}); // Aggiorna lo slider nel popup
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    // NAVIGATORE
                    ListTile(
                      title: Text(Translator.of('navigator')),
                      trailing: DropdownButton<String>(
                        value: _preferredNav,
                        onChanged: (v) {
                          setState(() => _preferredNav = v!);
                          setDialogState(() {});
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
                        setState(() => _markers = []);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(Translator.of('cache_cleared'))),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se l'utente cambia filtri senza ricaricare, nascondiamo i marker non pertinenti
    final List<Marker> displayedMarkers = _markers.where((marker) {
    // Se nessun filtro è selezionato, mostra tutti i marker presenti in memoria
    if (_selectedSports.isEmpty) return true;

    // Recuperiamo lo sport dal tag Key del marker
    if (marker.key is ValueKey<String?>) {
      final String? sportMarker = (marker.key as ValueKey<String?>).value; 

      if (sportMarker == null) return false;

      final String sportsOfMarker = sportMarker.split('|').last.toLowerCase();
      
      return _selectedSports.any((filter) => 
        sportsOfMarker.contains(filter.toLowerCase())
      );
    }
    return false;
  }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.of('app_title')),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: Translator.of('open_menu'), // Traduzione del tooltip
            onPressed: () => Scaffold.of(context).openDrawer(), // Apre il drawer
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60), 
          child: Container(
            height: 60,
            color: Colors.blueGrey[900],
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: _availableSports.map((sport) {
                final isSelected = _selectedSports.contains(sport);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(Translator.of(sport), style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.blueGrey[700],
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedSports.add(sport);
                        } else {
                          _selectedSports.remove(sport);
                        }

                        bool filtersChanged = !(_lastSearchedSports.length == _selectedSports.length && 
                            _lastSearchedSports.containsAll(_selectedSports));

                        // Se i filtri sono diversi da quelli dell'ultima ricerca, mostra il tasto.
                        // Se è tornato alla configurazione originale, nascondilo.
                        if (filtersChanged) {
                          _showSearchButton = true;
                        } else {
                          // Opzionale: controlla anche la distanza GPS prima di nascondere
                          _showSearchButton = false; 
                        }
                      });
                    },
                  ),
                );
              }).toList(
            ),
          ),
        ),
      ),),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[900]),
              child: const Center(
                child: Text('PickUp', style: TextStyle(color: Colors.white, fontSize: 28)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blueAccent),
              title: Text(Translator.of('language')),
              trailing: DropdownButton<String>(
                value: Translator.currentLanguage,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => Translator.currentLanguage = newValue);
                    Navigator.pop(context);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'it', child: Text('Italiano 🇮🇹')),
                  DropdownMenuItem(value: 'en', child: Text('English 🇺🇸')),
                ],
              ),
            ),
            
            const Divider(),

            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: Text(Translator.of('settings')),
              onTap: () {
                Navigator.pop(context); // Chiude il drawer
                _showSettingsDialog();  // Apre il popup
              },
            ),            
            
            const Spacer(), // Spinge tutto quello che segue in fondo

            const Divider(),
            InkWell(
              onTap: () => {_launchURL("https://consultits.it")},
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(Translator.of('developed_by'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text(
                      "CONSULTITS",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter,
              initialZoom: 14.0,
              onMapReady: () {
                if (_currentMapCenter != milanDefault) {
                  _mapController.move(_currentMapCenter, 14.5);
                }
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _showSearchButton = true;
                    _currentMapCenter = position.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                key: ValueKey("${Translator.currentLanguage}_${widget.isDarkMode}"),
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.pickup.app',
                evictErrorTileStrategy: EvictErrorTileStrategy.none,
                tileDisplay: const TileDisplay.fadeIn()
              ),
              MarkerLayer(markers: displayedMarkers),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          if (_showSearchButton)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: () => _fetchMultiSportCourts(),
                  label: Text(Translator.of('search_here'), style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _initializeLocation(false), // Ri-esegue il check posizione e sposta la mappa
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blueAccent),
      ),
    );
  }
}