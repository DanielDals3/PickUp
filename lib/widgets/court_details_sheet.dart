import 'package:flutter/material.dart';
import 'package:pickup/models/sport_court.dart';
import '../utils/app_utils.dart';
import '../utils/sport_utils.dart';
import '../services/translator_service.dart';

class CourtDetailsSheet extends StatelessWidget {
  final SportCourt court;
  final String preferredNav;
  final List<String> availableSports;

  const CourtDetailsSheet({
    super.key,
    required this.court,
    required this.preferredNav,
    required this.availableSports,
  });

  @override
  Widget build(BuildContext context) {
    // Estrazione dati opzionali
    final tags = court.rawTags;
    String? website = tags['website'] ?? tags['contact:website'] ?? tags['facebook'] ?? tags['url'];
    String? phone = tags['phone'] ?? tags['contact:phone'];
    String address = AppUtils.formatAddress(tags);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 12, 
          bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name == "unknown" ? Translator.of("unknown") : court.name, 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                    ),
                    const Divider(height: 20),
                    
                    // SEZIONE SPORT
                    _buildSportGrid(context),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(),
                    ),

                    // DETTAGLI PRINCIPALI (con la tua logica Text.rich)
                    _buildDetailRow(Icons.location_on, Translator.of('address'), address, context),
                    _buildDetailRow(
                      Icons.layers, 
                      Translator.of('surface'), 
                      tags['surface'] ?? Translator.of('not_specified'), 
                      context
                    ),

                    // LINK ESTERNI
                    if (website != null) 
                      _buildLinkRow(Icons.language, Translator.of('website'), website, Colors.blueAccent, context),
                    if (phone != null) 
                      _buildLinkRow(Icons.phone, Translator.of('phone'), phone, Colors.green, context, isPhone: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildNavigationButton(context),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTI PRIVATI ---

  Widget _buildHandle() => Center(
    child: Container(
      width: 40, 
      height: 4, 
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300], 
        borderRadius: BorderRadius.circular(10)
      ),
    ),
  );

  Widget _buildSportGrid(BuildContext context) {
    final counts = court.sportCounts;

    return Wrap(
      spacing: 8, 
      runSpacing: 8,
      children: counts.entries.where((e) => availableSports.contains(e.key)).map((e) {
        final color = SportUtils.getIconColor(e.key);
        return IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(SportUtils.getIconData(e.key), size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  "${Translator.of(e.key)}: ${e.value}",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // La tua funzione preferita con Text.rich migliorata
  Widget _buildDetailRow(IconData icon, String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 15, 
                  color: Theme.of(context).textTheme.bodyMedium?.color
                ),
                children: [
                  TextSpan(
                    text: "$label: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(text: value),
                ],
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(IconData icon, String label, String value, Color iconColor, BuildContext context, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => isPhone 
            ? AppUtils.launchURL("tel:${value.replaceAll(RegExp(r'[^0-9+]'), '')}") 
            : AppUtils.launchURL(value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 15),
                  children: [
                    TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      minimumSize: const Size(double.infinity, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
    ),
    onPressed: () => AppUtils.openMap(court.position.latitude, court.position.longitude, preferredNav),
    icon: const Icon(Icons.directions, color: Colors.white),
    label: Text(
      Translator.of('take_me_here'), 
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
    ),
  );
}