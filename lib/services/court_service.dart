import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/sport_court.dart';

class CourtService {
  static List<SportCourt> sortCourts({
    required List<SportCourt> courts,
    required  LatLng currentPos,
    required bool isGpsActive,
  }) {
    final Map<String, SportCourt> uniqueCourts = {};
    for (var court in courts) {
      uniqueCourts[court.id] = court;
    }

    List<SportCourt> distinctList = uniqueCourts.values.toList();

    if (isGpsActive) {
      // Ordina per DISTANZA
      distinctList.sort((a, b) {
        double distA = Geolocator.distanceBetween(
            currentPos.latitude, currentPos.longitude, a.position.latitude, a.position.longitude);
        double distB = Geolocator.distanceBetween(
            currentPos.latitude, currentPos.longitude, b.position.latitude, b.position.longitude);
        return distA.compareTo(distB);
      });
    } else {
      // Ordina per NOME
      distinctList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return distinctList;
  }

  static double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
  }
}