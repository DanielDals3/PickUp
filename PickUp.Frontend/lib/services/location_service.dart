import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationResult {
  final LatLng position;
  final bool isRealGps;

  LocationResult(this.position, this.isRealGps);
}

class LocationService {
  static const LatLng locationDefault = LatLng(45.4642, 9.1900); // Coordinate di default (Milano)

  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Controlla se il GPS è attivo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(locationDefault, false);
    }

    // 2. Gestisci i permessi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(locationDefault, false);
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return LocationResult(locationDefault, false);
    }

    // 3. Ottieni la posizione reale
    try {
      // 1. Prova a ottenere la posizione esatta (con timeout)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), 
        ),
      );
      
      // Se ha successo, restituisci subito questa
      return LocationResult(LatLng(position.latitude, position.longitude), true);

    } catch (e) {
      // 2. Se fallisce (es. timeout o segnale GPS debole), prova l'ultima nota
      Position? lastPos = await Geolocator.getLastKnownPosition();
      
      if (lastPos != null) {
        return LocationResult(LatLng(lastPos.latitude, lastPos.longitude), true);
      }
      
      // 3. Se neanche l'ultima nota esiste, vai al default
      return LocationResult(locationDefault, false);
    }
  }
}