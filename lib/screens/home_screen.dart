import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pickup/models/sport_court.dart';
import 'package:pickup/services/court_service.dart';
import 'package:pickup/services/location_service.dart';
import 'package:pickup/utils/sport_utils.dart';
import 'package:pickup/widgets/court_details_sheet.dart';
import 'package:pickup/widgets/court_list_sheet.dart';
import 'package:pickup/widgets/main_drawer.dart';
import 'package:pickup/widgets/map_widget.dart';
import 'package:pickup/widgets/search_button.dart';
import '../services/api_service.dart';
import '../services/translator_service.dart';
import '../widgets/sport_badge.dart';
import '../screens/settings_dialog.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentNav;
  final Locale? currentLocale;
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onNavChanged;
  final Function(String?) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentNav,
    this.currentLocale,
    required this.onThemeChanged,
    required this.onNavChanged,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATO DELL'APP ---
  final MapController _mapController = MapController();
  List<SportCourt> _courts = [];
  bool _isLoading = false;
  bool _showSearchButton = false;
  
  LatLng _currentMapCenter = const LatLng(45.4642, 9.1900); // Milano default
  bool _isGpsActive = false;
  bool _isSatellite = false;

  final List<String> _selectedSports = [];

  @override
  void initState() {
    super.initState();
    // Ora è dentro la classe corretta!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation(true);
    });
  }

  // Markers filtrati in tempo reale
  List<Marker> get _displayedMarkers {
    // 1. Filtriamo i dati
    final filteredCourts = _courts.where((court) {
    if (_selectedSports.isEmpty) return true;
      // Controlla se almeno uno degli sport del campo è tra quelli selezionati
      return court.sports.any((sport) => _selectedSports.contains(sport));
    }).toList();

    // 2. Trasformiamo i dati filtrati in Widget
    return filteredCourts.map((court) {
      return Marker(
        key: ValueKey("marker_${court.id}"),
        point: court.position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showCourtDetails(
            court
          ),
          child: _getMarkerIcon(court.sports.join(';')), 
        ),
      );
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
    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _currentMapCenter = result.position;
      _isGpsActive = result.isRealGps;
      _isLoading = false;
    });

    _moveToLocation(result.position, isInitial);
  }

  void _moveToLocation(final target, [bool isInitial = false]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(target, 14.5);
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
      _courts = [];
    });

    String sportsQuery = _selectedSports.isEmpty 
        ? SportUtils.availableSports.join('|') 
        : _selectedSports.join('|');

    // Query che cerca diversi tipi di sport contemporaneamente
    final url = 'https://overpass-api.de/api/interpreter?data=[out:json];nw["sport"~"$sportsQuery"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});out center;';

    try {
      final response = await ApiService.fetchOverpassData(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // List<Marker> newMarkers = [];

        if (!mounted) return;

        setState(() {
          _courts = (data['elements'] as List)
              .map((e) => SportCourt.fromOSM(e))
              .toList();
              
          _showSearchButton = false;
        }); 
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
      currentThemeMode: widget.currentThemeMode,
      currentNav: widget.currentNav,
      onThemeChanged: widget.onThemeChanged,
      onNavChanged: widget.onNavChanged,
      onClearCache: () => setState(() => _courts = []),
    );
  }

  void _showCourtDetails(SportCourt court) {    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Importante per i bordi arrotondati del Container interno
      builder: (context) => CourtDetailsSheet(
        court: court,
        preferredNav: widget.currentNav,
        availableSports: SportUtils.availableSports, // Variabile di stato della HomeScreen
      ),
    );
  }

  void _openFieldsList() {
    final sorted = CourtService.sortCourts(
      courts: _courts,
      currentPos: _currentMapCenter,
      isGpsActive: _isGpsActive,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourtListSheet(
        courts: sorted,
        currentPos: _currentMapCenter,
        showDistance: _isGpsActive, // Mostra i km solo se non è il default di Milano
        onCourtTap: (court) {
          Navigator.pop(context);
          _mapController.move(court.position, 17);
        },
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
      if (!SportUtils.availableSports.contains(sport)) {
        // Filtra solo sport gestiti
        continue;
      }

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
      decoration: const BoxDecoration(
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
    final bool allSelected = _selectedSports.length == SportUtils.availableSports.length;

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
                _selectedSports.addAll(SportUtils.availableSports);
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
        ...SportUtils.uniqueSports.map((sport) {
          final label = Translator.of(sport);
          final isSelected = _selectedSports.any((s) => Translator.of(s) == label);

          return MenuItemButton(
            closeOnActivate: false,
            onPressed: () {
              setState(() {
                final relatedSports = SportUtils.availableSports.where((s) => Translator.of(s) == label).toList();
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
        onLanguageChanged: widget.onLanguageChanged,
        currentLocale: widget.currentLocale,
      ),
      
      // USIAMO IL GPS DELLO SCAFFOLD (È la soluzione più robusta per Android/iOS)
      floatingActionButton: FloatingActionButton(
        heroTag: "gpsBtn", // Importante dare un tag unico
        onPressed: () => _initializeLocation(false),
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(
          Icons.my_location, 
          color: Theme.of(context).colorScheme.primary
        ),
      ),

      body: Stack(
        children: [
          // 1. MAPPA
          MapWidget(
            mapController: _mapController,
            markers: _displayedMarkers,
            initialCenter: _currentMapCenter,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
            isSatellite: _isSatellite,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _showSearchButton = true;
                  _currentMapCenter = camera.center;
                });
              }
            },
          ),

          // 2. TASTO SATELLITE
          Positioned(
            right: 15,
            bottom: 90, 
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: "satBtn",
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () => setState(() => _isSatellite = !_isSatellite),
                child: Icon(
                  _isSatellite ? Icons.map : Icons.satellite_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // 3. ZONA RISULTATI
          if (_sportCounts.isNotEmpty && !_showSearchButton)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge degli sport (Wrap li manda a capo se sono troppi)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _sportCounts.entries
                            .where((e) => SportUtils.availableSports.contains(e.key))
                            .map((e) => SportBadge(sportKey: e.key, count: e.value))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      // Tasto "Vedi Risultati"
                      FloatingActionButton.extended(
                        heroTag: "listBtn",
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.format_list_bulleted),
                        label: Text("${Translator.of('see_results')} (${_courts.length})"),
                        onPressed: _openFieldsList,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. OVERLAYS (Ricerca e Caricamento)
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          
          if (_showSearchButton)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10), // Distanza dalla AppBar
                  child: SearchButton(onPressed: _fetchMultiSportCourts),
                ),
              ),
          ),
        ],
      ),
    );
  }
}