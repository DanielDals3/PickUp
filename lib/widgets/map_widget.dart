import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Fondamentale per MapPosition
import 'package:latlong2/latlong.dart';
import '../services/translator.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final LatLng initialCenter;
  final Function(MapCamera, bool) onPositionChanged; 
  final bool isDarkMode;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.markers,
    required this.initialCenter,
    required this.onPositionChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14.0,
        // Qui passiamo i dati alla funzione che gestisce lo stato nella Home
        onPositionChanged: (camera, hasGesture) => onPositionChanged(camera, hasGesture),
      ),
      children: [
        TileLayer(
          key: ValueKey("${Translator.currentLanguage}_$isDarkMode"),
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.pickup.app',
          tileDisplay: const TileDisplay.fadeIn(),
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}