import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  AuthService() {
    _loadAuthStatus();
  }

  // Carica il token se l'utente aveva già fatto il login in passato
  Future<void> _loadAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isLoggedIn = _token != null;
    notifyListeners(); // Questo avvisa tutta l'app di aggiornarsi
  }

  // Da chiamare quando il login ha successo
  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Da chiamare per il logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}