import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  // Apre un URL generico (Sito web, telefono, mail)
  static Future<void> launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Apre il navigatore specifico (Google o Apple Maps)
  static Future<void> openMap(double lat, double lon, String preferredNav) async {
    Uri url;
    if (preferredNav == 'Apple Maps') {
      url = Uri.parse("https://maps.apple.com/?q=$lat,$lon");
    } else {
      url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    }
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch maps');
    }
  }

  static String formatAddress(Map<String, dynamic> tags) {
    String road = tags['addr:street'] ?? '';
    String houseNumber = tags['addr:housenumber'] ?? '';
    String city = tags['addr:city'] ?? '';

    if (road.isEmpty) return "Indirizzo non disponibile";
    return "$road $houseNumber, $city".trim();
  }
}