import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Fondamentale per MapPosition
import 'package:latlong2/latlong.dart';
import '../services/translator_service.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final LatLng initialCenter;
  final Function(MapCamera, bool) onPositionChanged; 
  final bool isDarkMode;
  final bool isSatellite;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.markers,
    required this.initialCenter,
    required this.onPositionChanged,
    required this.isDarkMode,
    required this.isSatellite,
  });

  @override
  Widget build(BuildContext context) {
    String urlTemplate;

    if (isSatellite) {
      urlTemplate = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
    } else {
      urlTemplate = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }

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
          key: ValueKey("${Translator.currentLanguage}_{$isDarkMode}_{$isSatellite"),
          urlTemplate: urlTemplate,
          userAgentPackageName: 'com.pickup.app',
          tileDisplay: const TileDisplay.fadeIn(),
        ),
        Opacity(
        opacity: isDarkMode ? 0.8 : 1.0, // Leggermente trasparente se tema scuro
        child: TileLayer(
          key: ValueKey("${isSatellite}_$isDarkMode"), 
          urlTemplate: urlTemplate,
          userAgentPackageName: 'com.pickup.app',
          tileDisplay: const TileDisplay.fadeIn(),
        ),
      ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}