class Translator {
  static String currentLanguage = 'it';

  static const Map<String, Map<String, String>> _data = {
    'it': {
      'app_title': 'PickUp',
      'search_here': 'Cerca in questa zona',
      'language': 'Lingua',
      'settings': 'Impostazioni',
      'dark_mode': 'Modalità Scura',
      'search_radius': 'Raggio di ricerca',
      'navigator': 'Navigatore',
      'units': 'Unità di misura',
      'clear_cache': 'Svuota cache mappa',
      'cache_cleared': 'Cache svuotata!',
      'developed_by': 'Sviluppato da',
      'address': 'Indirizzo',
      'surface': 'Superficie',
      'take_me_here': 'Portami qui',
      'not_specified': 'Non specificata',
      'unknown': 'Sconosciuto',
      'basketball': 'Basket',
      'soccer': 'Calcio',
      'tennis': 'Tennis',
      'volleyball': 'Pallavolo',
      'beachvolleyball': 'Beach Volley',
      'open_menu': 'Apri menu',
    },
    'en': {
      'app_title': 'PickUp',
      'search_here': 'Search in this area',
      'language': 'Language',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'search_radius': 'Search radius',
      'navigator': 'Navigator',
      'units': 'Units',
      'clear_cache': 'Clear map cache',
      'cache_cleared': 'Cache cleared!',
      'developed_by': 'Developed by',
      'address': 'Address',
      'surface': 'Surface',
      'take_me_here': 'Take me here',
      'not_specified': 'Not specified',
      'unknown': 'Unknown',
      'basketball': 'Basketball',
      'soccer': 'Soccer',
      'tennis': 'Tennis',
      'volleyball': 'Volleyball',
      'beachvolleyball': 'Beach Volley',
      'open_menu': 'Open menu',
    }
  };

  static String of(String key) {
    return _data[currentLanguage]?[key.toLowerCase()] ?? key;
  }
}