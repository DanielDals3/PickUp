import 'package:latlong2/latlong.dart';

class SportCourt {
  final String id;
  final LatLng position;
  final String name;
  final List<String> sports;
  final Map<String, dynamic> rawTags; // Utile per i dettagli extra (indirizzo, etc.)

  SportCourt({
    required this.id,
    required this.position,
    required this.name,
    required this.sports,
    required this.rawTags,
  });

  factory SportCourt.fromOSM(Map<String, dynamic> element) {
    final tags = element['tags'] ?? {};
    final double lat = element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
    final double lon = element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();

    // Pulizia degli sport: da "soccer;tennis" a ["soccer", "tennis"]
    List<String> sportsList = (tags['sport'] ?? 'unknown')
        .toString()
        .split(';')
        .map((s) => s.trim().toLowerCase())
        .toList();

    return SportCourt(
      id: element['id'].toString(),
      position: LatLng(lat, lon),
      name: tags['name'] ?? 'unknown',
      sports: sportsList,
      rawTags: tags,
    );
  }

  Map<String, int> get sportCounts {
    Map<String, int> counts = {};
    for (var s in sports) {
      counts[s] = (counts[s] ?? 0) + 1;
    }
    if (counts.isEmpty) counts['unknown'] = 1;
    return counts;
  }
}