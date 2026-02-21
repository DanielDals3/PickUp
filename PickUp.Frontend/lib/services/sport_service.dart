import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pickup/models/sport.dart';
import '../core/api_config.dart'; // Controlla il path

class SportService {
  // Singleton
  static final SportService _instance = SportService._internal();
  factory SportService() => _instance;
  SportService._internal();

  List<Sport> _allAvailableSports = [];
  List<Sport> get allSports => _allAvailableSports;

  Future<void> initSports() async {
    if (_allAvailableSports.isNotEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.url}/sports/list'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Usiamo utf8.decode per gestire correttamente caratteri speciali o accenti
        final List<dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        
        _allAvailableSports = jsonResponse.map((sportJson) {
          try {
            return Sport.fromJson(sportJson);
          } catch (e) {
            print('❌ Errore mapping singolo sport: $sportJson -> $e');
            return null; // Evitiamo che un singolo errore blocchi tutto
          }
        }).whereType<Sport>().toList(); // Rimuove eventuali null
            
      }
    } catch (e) {
      print('⚠️ Errore di rete nel caricamento degli sport: $e');
    }
  }
}