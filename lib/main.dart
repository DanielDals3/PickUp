import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
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
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent, 
          foregroundColor: Colors.white, // Testo e icone bianche sulla toolbar blu
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

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

  final List<String> _availableSports = ['basketball', 'soccer', 'tennis', 'volleyball', 'beachvolleyball',
    'fitness', 'climbing', 'swimming', 'yoga', 'gymnastics', 'cycling', 'running', 'table_tennis', 'skiing', 
    'padel', 'gym', 'football', 'snowboarding', 'rugby_union', 'rugby', 'rugby_league', 'american_football',
    'baseball', 'softball', 'skateboard', 'skateboarding', 'golf', 'martial_arts', 'karate', 'judo', 'equestrian',
    'horse_riding', 'hockey', 'ice_hockey', 'boules', 'bocce', 'volley'];
  final Set<String> _selectedSports = {}; // Inizia vuoto = mostra tutto

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

    // 1. Dividiamo la stringa e puliamo i testi
    List<String> rawSports = (sportTag?.split(';') ?? ['unknown'])
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();

    // 2. CREIAMO UNA LISTA DI SPORT UNICI BASATA SULL'ICONA
    // Usiamo una mappa per tenere solo uno sport per ogni tipo di icona
    Map<IconData, String> uniqueIconsMap = {};
    
    for (var sport in rawSports) {
      IconData icon = _getIconDataForSport(sport);
      // Se l'icona non è già presente nella mappa, la aggiungiamo
      if (!uniqueIconsMap.containsKey(icon)) {
        uniqueIconsMap[icon] = sport;
      }
    }

    List<String> sports = uniqueIconsMap.values.toList();

    // 2. Se è un campo Multisport (più di uno sport unico)
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
        padding: const EdgeInsets.all(2),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniIcon(displayedSports[0]),
                  if (displayedSports.length >= 2) _buildMiniIcon(displayedSports[1]),
                ],
              ),
              if (displayedSports.length > 2)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniIcon(displayedSports[2]),
                    if (displayedSports.length == 4) _buildMiniIcon(displayedSports[3]),
                  ],
                ),
            ],
            ),
        ),
      );
    }

    // 3. Singolo Sport (o dopo la pulizia ne è rimasto solo uno)
    String sport = sports.isNotEmpty ? sports.first : 'unknown';

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

  // Funzione helper per le icone minuscole nel quadrato multisport
  Widget _buildMiniIcon(String sport) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Icon(
        _getIconDataForSport(sport), 
        size: 13,
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
      case 'volley':
        return Icons.sports_volleyball;
      case 'beachvolleyball':
        return Icons.sports_volleyball;
      case 'fitness':
      case 'gym':
        return Icons.fitness_center;
      case 'climbing':
        return Icons.terrain;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'gymnastics':
        return Icons.sports_gymnastics;
      case 'cycling':
        return Icons.directions_bike;
      case 'running':
        return Icons.directions_run;
      case 'table_tennis':
        return Icons.table_restaurant;
      case 'skiing':
        return Icons.downhill_skiing;
      case 'snowboarding':
        return Icons.snowboarding;
      case 'padel':
        return Icons.sports_tennis;
      case 'rugby_union':
      case 'rugby':
      case 'rugby_league':
        return Icons.sports_rugby;
      case 'american_football':
        return Icons.sports_football;
      case 'baseball':
      case 'softball':
        return Icons.sports_baseball;
      case 'skateboard':
      case 'skateboarding':
        return Icons.skateboarding;
      case 'golf':
        return Icons.sports_golf;
      case 'martial_arts':
      case 'karate':
      case 'judo':
        return Icons.sports_martial_arts;
      case 'equestrian':
      case 'horse_riding':
        return Icons.cruelty_free;
      case 'hockey':
      case 'ice_hockey':
        return Icons.sports_hockey;
      case 'boules':
      case 'bocce':
        return Icons.circle;
      default:
        return Icons.sports; 
    }
  }

  Color _getIconColorForSport(String sport) {
    switch (sport.trim()) {
      case 'unknown': 
        return Colors.red;
      case 'basketball': 
        return Colors.orange;
      case 'soccer':
      case 'football':
        return Colors.green[800]!;
      case 'tennis': 
        return Colors.lime[700]!;
      case 'padel':
        return Colors.teal[600]!;
      case 'volleyball': 
      case 'volley':
        return Colors.blue[700]!;
      case 'beachvolleyball': 
        return Colors.amber[800]!;
      case 'fitness':
      case 'gym':
        return Colors.blueGrey[700]!;
      case 'climbing':
        return Colors.brown[600]!;
      case 'swimming':
        return Colors.cyan[600]!;
      case 'yoga':
        return Colors.purple[400]!;
      case 'gymnastics':
        return Colors.pink[400]!;
      case 'cycling':
        return Colors.deepOrange[600]!;
      case 'running':
        return Colors.red[400]!;
      case 'table_tennis':
        return Colors.green[600]!;
      case 'skiing':
        return Colors.lightBlue[300]!;
      case 'snowboarding':
        return Colors.indigo[400]!;
      case 'rugby':
      case 'rugby_union':
      case 'rugby_league':
        return const Color(0xFF800020);
      case 'american_football':
        return Colors.brown[700]!;
      case 'baseball':
      case 'softball':
        return Colors.red[900]!;
      case 'skateboard':
      case 'skateboarding':
        return Colors.grey[800]!;
      case 'golf':
        return Colors.lightGreen[900]!;
      case 'martial_arts':
      case 'karate':
      case 'judo':
        return Colors.red[700]!;
      case 'equestrian':
      case 'horse_riding':
        return Colors.brown[400]!;
      case 'hockey':
      case 'ice_hockey':
        return Colors.blueAccent;
      case 'boules':
      case 'bocce':
        return Colors.blueGrey[400]!;
      default: 
        return Colors.grey[600]!;
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

    // LOGICA DI CONTEGGIO: 
    // Prendiamo la stringa "soccer;tennis;tennis", la puliamo e contiamo le occorrenze
    List<String> rawSports = (tags['sport'] ?? '').toString().split(';');
    Map<String, int> sportCounts = {};

    for (var s in rawSports) {
      String cleaned = s.trim().toLowerCase();
      if (cleaned.isNotEmpty) {
        sportCounts[cleaned] = (sportCounts[cleaned] ?? 0) + 1;
      }
    }

    // Se non ci sono sport taggati, mettiamo unknown
    if (sportCounts.isEmpty) sportCounts['unknown'] = 1;
    
    // Indirizzo
    String address = _formatAddress(tags);
    
    // Link e Telefono
    String? website = tags['website'] ?? tags['contact:website'] ?? tags['facebook'] ?? tags['url'];
    String? phone = tags['phone'] ?? tags['contact:phone'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Permette di vedere il raggio del bordo
      builder: (context) => Container(
        // Definiamo un'altezza massima dell'85% dello schermo per sicurezza
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12, bottom: 32 + MediaQuery.of(context).viewInsets.bottom, // Gestisce tastiera
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle grigia superiore
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  margin: const EdgeInsets.only(bottom: 20), 
                  decoration: BoxDecoration(
                    color: Colors.grey[300], 
                    borderRadius: BorderRadius.circular(10)
                  )
                )
              ),
              
              // Rendiamo il contenuto interno scorrevole
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(height: 12),

                      // SEZIONE SPORT: Griglia di Badge
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sportCounts.entries.map((entry) {
                          return IntrinsicWidth(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.42,
                              ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getIconColorForSport(entry.key).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getIconColorForSport(entry.key).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Impedisce alla riga di espandersi all'infinito
                                children: [
                                  Icon(_getIconDataForSport(entry.key), size: 16, color: _getIconColorForSport(entry.key)),
                                  const SizedBox(width: 8),
                                  // Aggiungiamo Flexible per evitare che testi lunghi causino overflow a destra
                                  Flexible( 
                                    child: Text(
                                      "${Translator.of(entry.key)}: ${entry.value}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _getIconColorForSport(entry.key).withValues(alpha: 0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis, // Se il testo è troppo lungo, mette i puntini
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 40),

                      // Dettagli (Indirizzo, Superficie, ecc.)
                      _buildDetailRow(Icons.location_on, Translator.of('address'), address),
                      _buildDetailRow(Icons.layers, Translator.of('surface'), tags['surface'] ?? Translator.of('not_specified')),

                      // Sito Web
                      if (website != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () => _launchURL(website),
                            child: Row(
                              children: [
                                const Icon(Icons.language, size: 20, color: Colors.blueAccent),
                                const SizedBox(width: 12),
                                Text("${Translator.of('website')}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(website, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ),

                      // Telefono
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
                                Text("${Translator.of('phone')}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(phone, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              
              // Bottone Navigazione (Fuori dallo scroll per essere sempre visibile)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () => _openMap(lat, lon),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: Text(Translator.of('take_me_here'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
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
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 15, 
                  color: Theme.of(context).textTheme.bodyMedium?.color
                ),
                children: [
                  TextSpan(
                    text: "$label: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold) // Etichetta in grassetto
                  ),
                  TextSpan(text: value), // Valore (es. la via o il tipo di superficie)
                ],
              ),
              softWrap: true,
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
    bool localDarkMode = widget.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Usiamo StatefulBuilder per permettere ai widget (switch, slider) 
        // di aggiornarsi graficamente mentre il popup è aperto
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogTheme = localDarkMode ? ThemeData.dark() : ThemeData.light();

            return Theme(
              data: dialogTheme, 
              child: AlertDialog(
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
                        value: localDarkMode,
                        onChanged: (bool value) {
                          widget.onThemeChanged(value);

                          setDialogState(() {
                            localDarkMode = value;
                          });
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
              )
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> seenLabels = {};
    final List<String> uniqueSports = _availableSports.where((sport) {
      final label = Translator.of(sport);
      if (seenLabels.contains(label)) return false;
      seenLabels.add(label);
      return true;
    }).toList();

    uniqueSports.sort((a, b) => Translator.of(a).compareTo(Translator.of(b)));

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
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: Translator.of('open_menu'), // Traduzione del tooltip
            onPressed: () => Scaffold.of(context).openDrawer(), // Apre il drawer
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: Row(
              children: [
                  MenuAnchor(
                    style: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(Theme.of(context).cardColor),
                      elevation: WidgetStateProperty.all(8),
                    ),
                    builder: (context, controller, child) {
                      return GestureDetector(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                Translator.of('sports'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.white),
                            ],
                          ),
                        ),
                      );
                    },
                    menuChildren: [
                      // --- PULSANTE SELEZIONA/DESELEZIONA TUTTO ---
                      MenuItemButton(
                        closeOnActivate: false,
                        onPressed: () {
                          setState(() {
                            if (_selectedSports.length == _availableSports.length) {
                              _selectedSports.clear(); // Deseleziona tutto
                            } else {
                              _selectedSports.clear();
                              _selectedSports.addAll(_availableSports); // Seleziona tutto
                            }
                            _showSearchButton = true;
                          });
                        },
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _selectedSports.length == _availableSports.length 
                                    ? Icons.indeterminate_check_box 
                                    : Icons.select_all,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedSports.length == _availableSports.length 
                                    ? Translator.of('deselect_all') 
                                    : Translator.of('select_all'),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1), // Linea di separazione tra il comando rapido e la lista

                      // --- LISTA DEGLI SPORT ---
                      ...uniqueSports.map((sport) {
                        final label = Translator.of(sport);
                        final isSelected = _selectedSports.any((s) => Translator.of(s) == label);

                        return MenuItemButton(
                          closeOnActivate: false,
                          onPressed: () {
                            setState(() {
                              final relatedSports = _availableSports.where((s) => Translator.of(s) == label).toList();  

                              if (isSelected) {
                                _selectedSports.removeWhere((s) => relatedSports.contains(s));
                              } else {
                                _selectedSports.addAll(relatedSports);
                              }
                              _showSearchButton = true;
                            });
                          },
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isSelected ? Colors.blueAccent : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  _getIconDataForSport(sport), 
                                  color: _getIconColorForSport(sport), 
                                  size: 20
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Translator.of(sport),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.blueAccent : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                
                const VerticalDivider(color: Colors.white24, indent: 10, endIndent: 10),

                // CONTATORE VELOCE (Mostra quanti sport hai selezionato)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedSports.isEmpty 
                        ? [Text(Translator.of('all_sports'), style: const TextStyle(color: Colors.white54, fontSize: 13))]
                        : _selectedSports.map((s) => Translator.of(s)).toSet().toList().map((label) {
                            // Troviamo uno sport rappresentativo per l'icona
                            final repSport = _availableSports.firstWhere((s) => Translator.of(s) == label);
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getIconColorForSport(repSport).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _getIconColorForSport(repSport).withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getIconDataForSport(repSport), size: 12, color: _getIconColorForSport(repSport)),
                                  const SizedBox(width: 4),
                                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),               
              ],
            ),
          ),
        ),
      ),
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