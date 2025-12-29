# 🏀 PickUp - Trova il tuo campo sportivo

**PickUp** è un'applicazione Flutter intuitiva progettata per aiutare gli sportivi a localizzare campi da basket, calcio, tennis e beach volley intorno a loro. Utilizzando i dati di OpenStreetMap (via Overpass API), l'app mostra in tempo reale le strutture sportive disponibili sulla mappa.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## ✨ Funzionalità

-   📍 **Localizzazione GPS**: Trova la tua posizione attuale con un click.
-   🗺️ **Mappa Interattiva**: Visualizzazione fluida dei campi sportivi tramite `flutter_map`.
-   🔍 **Filtri Multi-Sport**: Filtra tra Basket, Calcio, Tennis e Beach Volley.
-   🌓 **Markers Intelligenti**: Icone personalizzate che mostrano più sport se il campo è polivalente.
-   📋 **Dettagli Completi**: Visualizza indirizzo, tipo di superficie, illuminazione e contatti.
-   🚗 **Navigazione Diretta**: Avvia Google Maps o Apple Maps direttamente dal popup dei dettagli.
-   📞 **Contatto Rapido**: Chiama il centro sportivo o visita il sito web con un tocco.

## 🚀 Come iniziare

### Prerequisiti

* Flutter SDK installato
* Un emulatore (Android/iOS) o un dispositivo fisico

### Installazione

1.  **Clona il repository:**
    ```bash
    git clone [https://github.com/DanielDals3/PickUp.git](https://github.com/DanielDals3/PickUp.git)
    ```
2.  **Installa le dipendenze:**
    ```bash
    flutter pub get
    ```
3.  **Configura i permessi:**
    Assicurati che `AndroidManifest.xml` (Android) e `Info.plist` (iOS) abbiano i permessi necessari per GPS e `url_launcher` (già configurati in questo repo).

4.  **Avvia l'app:**
    ```bash
    flutter run
    ```

## 🛠️ Tecnologie utilizzate

-   **Framework**: [Flutter](https://flutter.dev)
-   **Mappe**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap)
-   **Dati**: [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
-   **Geolocalizzazione**: [geolocator](https://pub.dev/packages/geolocator)
-   **Utility**: [url_launcher](https://pub.dev/packages/url_launcher) (per chiamate e mappe esterne)

---
Realizzato con ❤️ per la community degli sportivi.
