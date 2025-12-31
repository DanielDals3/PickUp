import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pickup/services/location_service.dart';
import 'package:pickup/utils/app_utils.dart';
import 'package:pickup/utils/sport_utils.dart';
import 'package:pickup/widgets/court_details_sheet.dart';
import 'package:pickup/widgets/main_drawer.dart';
import 'package:pickup/widgets/map_widget.dart';
import 'package:pickup/widgets/search_button.dart';
import '../services/api_service.dart';
import '../services/translator.dart';
import '../widgets/sport_badge.dart';
import '../screens/settings_dialog.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomeScreen({
    super.key, 
    required this.isDarkMode, 
    required this.onThemeChanged
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATO DELL'APP ---
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = false;
  bool _showSearchButton = false;
  
  double _searchRadius = 5.0;
  String _selectedUnit = "km";
  String _preferredNav = "Google Maps";
  LatLng _currentMapCenter = const LatLng(45.4642, 9.1900); // Milano default

  final List<String> _availableSports = ['basketball', 'soccer', 'tennis', 'volleyball', 'beachvolleyball',
    'fitness', 'climbing', 'swimming', 'yoga', 'gymnastics', 'cycling', 'running', 'table_tennis', 'skiing', 
     'padel', 'gym', 'football', 'snowboarding', 'rugby_union', 'rugby', 'rugby_league', 'american_football',
     'baseball', 'softball', 'skateboard', 'skateboarding', 'golf', 'martial_arts', 'karate', 'judo', 'equestrian',
     'horse_riding', 'hockey', 'ice_hockey', 'boules', 'bocce', 'volley', 'boxing', 'calisthenics','snowboard',
     'roller_hockey' ];
  final List<String> _selectedSports = [];

  @override
  void initState() {
    super.initState();
    // Ora è dentro la classe corretta!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation(true);
    });
  }

  // --- LOGICA DI FILTRAGGIO ---
  // Lista degli sport univoci tradotti e ordinati (per il menu)
  List<String> get _uniqueSports {
    final Set<String> seenLabels = {};
    final List<String> list = _availableSports.where((sport) {
      final label = Translator.of(sport);
      if (seenLabels.contains(label)) return false;
      seenLabels.add(label);
      return true;
    }).toList();
    list.sort((a, b) => Translator.of(a).compareTo(Translator.of(b)));
    return list;
  }

  // Markers filtrati in tempo reale
  List<Marker> get _displayedMarkers {
    if (_selectedSports.isEmpty) return _markers;
    return _markers.where((marker) {
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
  }

  Map<String, int> get _sportCounts {
    Map<String, int> counts = {};
    for (var marker in _displayedMarkers) {
      if (marker.key is ValueKey<String?>) {
        final String? sportTag = (marker.key as ValueKey<String?>).value;
        if (sportTag != null) {
          final List<String> sports = sportTag.split('|').last.split(',');
          for (var s in sports) {
            final cleanSport = s.trim().toLowerCase();
            counts[cleanSport] = (counts[cleanSport] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }

  // --- AZIONI ---
  Future<void> _initializeLocation(bool isInitial) async {
    setState(() => _isLoading = true);

    // CHIAMATA AL SERVICE
    LatLng targetLocation = await LocationService.getCurrentLocation();

    _moveToLocation(targetLocation, isInitial);
  }

  void _moveToLocation(LatLng target, [bool isInitial = false]) {
    if (!mounted) return;

    setState(() {
      _currentMapCenter = target;
      _isLoading = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _mapController.move(target, 14.5);
      }
    });
    
    // Delay per i visibleBounds
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isInitial) {
        _fetchMultiSportCourts();
      } else {
        setState(() => _showSearchButton = true);
      }
    });
  }

  Future<void> _fetchMultiSportCourts() async {
    if (!mounted) return; 

    // Otteniamo i confini della mappa
    final bounds = _mapController.camera.visibleBounds;
    // Protezione se i bounds non sono ancora pronti
    if (bounds.south == bounds.north) return;

    setState(() {
      _isLoading = true;
      _showSearchButton = false;
      _markers = [];
    });

    String sportsQuery = _selectedSports.isEmpty 
        ? _availableSports.join('|') 
        : _selectedSports.join('|');

    // Query che cerca diversi tipi di sport contemporaneamente
    final url = 'https://overpass-api.de/api/interpreter?data=[out:json];nw["sport"~"$sportsQuery"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});out center;';

    try {
      final response = await ApiService.fetchOverpassData(url);
      
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

      setState(() {
        _isLoading = false;
        _showSearchButton = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSettings() {
    SettingsDialog.show(
      context,
      currentRadius: _searchRadius,
      isDarkMode: widget.isDarkMode,
      currentNav: _preferredNav,
      unit: _selectedUnit,
      onRadiusChanged: (v) => setState(() => _searchRadius = v),
      onThemeChanged: (v) => widget.onThemeChanged(v),
      onNavChanged: (v) => setState(() => _preferredNav = v),
      onClearCache: () => setState(() => _markers = []),
    );
  }

  void _showCourtDetails(double lat, double lon, Map<String, dynamic> tags) {
    String courtName = tags['name'] ?? Translator.of('unknown');

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
    String address = AppUtils.formatAddress(tags);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Importante per i bordi arrotondati del Container interno
      builder: (context) => CourtDetailsSheet(
        name: courtName,
        sportCounts: sportCounts,
        address: address,
        tags: tags,
        lat: lat,
        lon: lon,
        preferredNav: _preferredNav, // Variabile di stato della HomeScreen
        availableSports: _availableSports, // Variabile di stato della HomeScreen
      ),
    );
  }

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
      if (!_availableSports.contains(sport)) // Filtra solo sport gestiti
        continue;

      IconData icon = SportUtils.getIconData(sport);
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
                  SportUtils.buildMiniIcon(displayedSports[0]),
                  if (displayedSports.length >= 2) SportUtils.buildMiniIcon(displayedSports[1]),
                ],
              ),
              if (displayedSports.length > 2)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SportUtils.buildMiniIcon(displayedSports[2]),
                    if (displayedSports.length == 4) SportUtils.buildMiniIcon(displayedSports[3]),
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
      child: Icon(SportUtils.getIconData(sport), color: SportUtils.getIconColor(sport), size: 28),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(Translator.of('app_title')),
      centerTitle: true,
      foregroundColor: Colors.white,
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
          ),
          child: Row(
            children: [
              _buildSportsMenu(), // Il pulsante con il MenuAnchor
              const VerticalDivider(color: Colors.white24, indent: 10, endIndent: 10),
              _buildSelectedSportsBar(), // La riga scorrevole degli sport selezionati
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportsMenu() {
    final bool allSelected = _selectedSports.length == _availableSports.length;

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Theme.of(context).cardColor),
        elevation: WidgetStateProperty.all(8),
      ),
      builder: (context, controller, child) => GestureDetector(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
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
      ),
      menuChildren: [
        // --- PULSANTE SELEZIONA/DESELEZIONA TUTTO ---
        MenuItemButton(
          closeOnActivate: false,
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedSports.clear();
              } else {
                _selectedSports.clear();
                _selectedSports.addAll(_availableSports);
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
                  allSelected ? Icons.indeterminate_check_box : Icons.select_all,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  allSelected ? Translator.of('deselect_all') : Translator.of('select_all'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // --- LISTA DEGLI SPORT ---
        ..._uniqueSports.map((sport) {
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
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    SportUtils.getIconData(sport),
                    color: SportUtils.getIconColor(sport),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis, // Aggiunge i puntini (...) se troppo lungo
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedSportsBar() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _selectedSports.isEmpty 
            ? [Text(Translator.of('all_sports'), style: const TextStyle(color: Colors.white54, fontSize: 13))]
            : _selectedSports.map((sport) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SportUtils.getIconColor(sport).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SportUtils.getIconColor(sport).withValues(alpha: 0.5))
                  ),
                  child: Row(
                    children: [
                      Icon(SportUtils.getIconData(sport), size: 12, color: SportUtils.getIconColor(sport)),
                      const SizedBox(width: 4),
                      Text(Translator.of(sport), style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: MainDrawer(
        onOpenSettings: _openSettings,
        onLanguageChanged: (newLang) {
          setState(() {
            Translator.currentLanguage = newLang;
          });
        },
      ),
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            markers: _displayedMarkers,
            initialCenter: _currentMapCenter,
            isDarkMode: widget.isDarkMode,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _showSearchButton = true;
                  _currentMapCenter = camera.center;
                });
              }
            },
          ),
          
          if (_sportCounts.isNotEmpty && !_showSearchButton)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sportCounts.entries
                    .where((e) => _availableSports.contains(e.key))
                    .map((e) => SportBadge(sportKey: e.key, count: e.value))
                    .toList(),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
          
          if (_showSearchButton)
            SearchButton(onPressed: _fetchMultiSportCourts),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _initializeLocation(false),
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(
          Icons.my_location, 
          color: Theme.of(context).colorScheme.primary
        ),
      ),
    );
  }
}