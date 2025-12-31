import 'package:latlong2/latlong.dart';

class SportCourt {
  final LatLng position;
  final String name;
  final List<String> sports;

  SportCourt({
    required this.position,
    required this.name,
    required this.sports,
  });
}