import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pickup/models/sport_court.dart';
import 'package:pickup/screens/bookings_screen.dart';
import 'package:pickup/screens/chat_list_screen.dart';
import 'package:pickup/screens/community_screen.dart';
import 'package:pickup/screens/profile_screen.dart';
import 'package:pickup/services/court_service.dart';
import 'package:pickup/services/location_service.dart';
import 'package:pickup/utils/sport_utils.dart';
import 'package:pickup/widgets/court_details_sheet.dart';
import 'package:pickup/widgets/court_list_sheet.dart';
import 'package:pickup/widgets/map_widget.dart';
import '../services/api_service.dart';
import '../services/translator_service.dart';
import '../widgets/sport_badge.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- STATO DELL'APP ---
  final MapController _mapController = MapController();
  List<SportCourt> _courts = [];
  bool _isLoading = false;
  bool _showSearchButton = false;

  LatLng _currentMapCenter = const LatLng(45.4642, 9.1900); // Milano default
  bool _isGpsActive = false;
  bool _isSatellite = false;
  int _currentIndex = 2;

  final List<String> _selectedSports = [];
  List<Marker> _displayedMarkers = [];
  Map<String, int> _sportCounts = {}; 

  @override
  void initState() {
    super.initState();
    // Ora è dentro la classe corretta!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation(true);
    });
  }

  // --- AZIONI ---
  void _syncMarkers(){
    setState(() {
        // 1. Filtriamo i dati
        final filteredCourts = _courts.where((court) {
          if (_selectedSports.isEmpty) return true;
            // Controlla se almeno uno degli sport del campo è tra quelli selezionati
            return court.sports.any((sport) => _selectedSports.contains(sport));
        }).toList();

        // 2. Trasformiamo in Marker e salviamo nella variabile di stato
        _displayedMarkers = filteredCourts.map((court) {
          return Marker(
            key: ValueKey("marker_${court.id}"),
            point: court.position,
            width: 40,  
            height: 40,
            child: GestureDetector(
              onTap: () => _showCourtDetails(court),
              // Usiamo FaIcon qui dentro come abbiamo visto prima
              child: _getMarkerIcon(court.sports.join(';')), 
            ),
          );
        }).toList();

        // 3. Calcoliamo i conteggi per gli sport mostrati
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
        _sportCounts = counts;
    });
  }

  void _clearCacheAndMarkers() {
    setState(() {
      _courts.clear();
      _courts = []; 
    });

    _syncMarkers();
  }

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

  void _moveToLocation(final LatLng target, [bool isInitial = false]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(target, 14.5);
        });
    
    // Delay per i visibleBounds
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isInitial) {
        _fetchMultiSportCourts();
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
      _displayedMarkers = [];
      _sportCounts = {};
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

        if (!mounted) return;

        setState(() {
          _courts = (data['elements'] as List)
              .map((e) => SportCourt.fromOSM(e))
              .toList();
              
        }); 
      }

      _syncMarkers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _showMapSettings(BuildContext context) {
    
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (modalContext) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(Translator.of('map_settings'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),

                    const SizedBox(height: 15),
                    
                    // SEZIONE SPORT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Translator.of('filter_per_sport'), 
                            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          if (_selectedSports.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedSports.clear());
                                setModalState(() {});
                                _syncMarkers();
                              },
                              child: Text(Translator.of('reset_filters'), 
                                style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: SportUtils.availableSports.map((sport) {
                          bool isSelected = _selectedSports.contains(sport);
                          String translatedName = Translator.of(sport);
                          Color sportColor = SportUtils.getIconColor(sport);
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(translatedName),
                              avatar: Icon(SportUtils.getIconData(sport), 
                                size: 16, 
                                color: isSelected ? sportColor : Colors.grey),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSports.add(sport); // Aggiungi alla lista
                                  } else {
                                    _selectedSports.remove(sport); // Rimuovi dalla lista
                                  }
                                });
                                setModalState(() {}); // Forza il refresh visivo della tendina
                                _syncMarkers(); // Aggiorna i marker sulla mappa
                              },
                              selectedColor: sportColor.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isSelected ? sportColor : Colors.grey.shade300,
                                width: 1.0, 
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              labelStyle: TextStyle(
                                color: isSelected ? sportColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const Divider(height: 30),

                    // ALTRE IMPOSTAZIONI (Satellite e GPS)
                    ListTile(
                      leading: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
                      title: Text(Translator.of('satellite_view')),
                      trailing: Switch(
                        value: _isSatellite,
                        onChanged: (val) {
                          setState(() => _isSatellite = val);
                          setModalState(() {});
                        },
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: Text(Translator.of('my_location')),
                      onTap: () {
                        _initializeLocation(false);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMapBody() {
    return Stack(
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

        // 2. TASTO REFRESH
        Positioned(
          top: 10,
          right: 15,
          child: SafeArea(
            child: FloatingActionButton.small(
              heroTag: "refreshSearchBtn",
              backgroundColor: _showSearchButton ? Theme.of(context).colorScheme.primary : Colors.white,
              onPressed: _isLoading ? null : _fetchMultiSportCourts,
              child: _isLoading 
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _showSearchButton ? Colors.white : null))
                : Icon(Icons.refresh, color: _showSearchButton ? Colors.white : Theme.of(context).colorScheme.primary),
            ),
          ),
        ),

        // 3. TASTO UNICO IMPOSTAZIONI MAPPA
        Positioned(
          right: 15,
          bottom: 80, // Sopra la navbar
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.layers_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _showMapSettings(context), // Apre la tendina
          ),
        ),

        // 4. ZONA RISULTATI (Badge + Lista)
        if (_sportCounts.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: _sportCounts.entries
                        .where((e) => SportUtils.availableSports.contains(e.key))
                        .map((e) => SportBadge(sportKey: e.key, count: e.value))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: "listBtn",
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.format_list_bulleted),
                    label: Text("${Translator.of('see_results')} (${_displayedMarkers.length})"),
                    onPressed: _openFieldsList,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(icon, 
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
        size: 22
      ),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      
      // IL TASTO CENTRALE (HOME/MAPPA)
      floatingActionButton: FloatingActionButton(
        heroTag: "homeBtn",
        shape: const CircleBorder(),
        backgroundColor: _currentIndex == 2 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[300],
        onPressed: () => setState(() => _currentIndex = 2),
        child: const Icon(Icons.map, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // LA TOOLBAR IN BASSO
      bottomNavigationBar: BottomAppBar(
        height: 60,
        shape: const CircularNotchedRectangle(), // Crea l'incavo per il tasto mappa
        notchMargin: 6.0,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.calendar_today_outlined),
            _buildNavItem(1, Icons.people_outline),
            const SizedBox(width: 48),
            _buildNavItem(3, Icons.chat_bubble_outline),
            _buildNavItem(4, Icons.person_outline),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          const BookingsScreen(),                     // Bookings Screen    
          const CommunityScreen(),                    // Community Screen
          _buildMapBody(),                            // Maps Screen
          const ChatListScreen(),                     // Chat List Screen
          ProfileScreen(
            currentLang: Translator.currentLanguage,
            currentThemeMode: widget.currentThemeMode,
            currentNav: widget.currentNav,
            onLangChanged: widget.onLanguageChanged,
            onThemeChanged: widget.onThemeChanged,
            onNavChanged: widget.onNavChanged,
            onClearCache: _clearCacheAndMarkers,
          ),                      // Profile Screen
        ],
      ),
    );
  }
}