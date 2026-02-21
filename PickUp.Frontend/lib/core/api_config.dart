import 'dart:io';

class ApiConfig {
  // Se testi su emulatore Android, 'localhost' non funziona, devi usare '10.0.2.2'
  // Se testi su macOS/iOS simulator, puoi usare 'localhost'
  static String get baseUrl {
    if (Platform.isAndroid) {
      // L'emulatore Android vede il tuo Mac a questo indirizzo speciale
      return 'http://10.0.2.2:8080'; 
    } else if (Platform.isIOS || Platform.isMacOS) {
      // Simulatori iOS e App MacOS possono usare localhost
      return 'http://127.0.0.1:8080';
    } else {
      // Per test su dispositivi fisici nella stessa rete WiFi, usa l'IP del Mac (es. 192.168.1.XX)
      return 'http://localhost:8080';
    }
  }

  // Endpoint specifici
  static String get url => baseUrl;
}