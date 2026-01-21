import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:pickup/utils/sport_utils.dart';
import '../models/sport_court.dart';

class CourtListSheet extends StatelessWidget {
  final List<SportCourt> courts;
  final LatLng currentPos;
  final bool showDistance;
  final Function(SportCourt) onCourtTap;

  const CourtListSheet({
    super.key,
    required this.courts,
    required this.currentPos,
    required this.showDistance,
    required this.onCourtTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.9,
      minChildSize: 0.2,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Maniglia per il trascinamento
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  Translator.of("see_results"),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: courts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final court = courts[index];

                    final cleanSports = SportUtils.getCleanedSportsForCourt(court.sports);

                    final Set<String> displaySet = cleanSports.map((s) => Translator.of(s)).toSet();
                    final String sportsLabel = displaySet.isEmpty 
                        ? Translator.of("unknown") 
                        : displaySet.join(", ");

                    final String mainSport = cleanSports.isNotEmpty ? cleanSports.first : 'unknown';
                                        
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: SportUtils.getIconColor(mainSport).withValues(alpha: 0.1),
                        child: Icon(
                          SportUtils.getIconData(mainSport), 
                          color: SportUtils.getIconColor(mainSport),
                        ),
                      ),
                      title: Text(
                        court.name == 'unknown' ? Translator.of("unknown") : court.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(sportsLabel, style: const TextStyle(fontSize: 12)),
                      trailing: showDistance 
                        ? _buildDistanceWidget(court.position) 
                        : const Icon(Icons.chevron_right, size: 18),
                      onTap: () => onCourtTap(court),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistanceWidget(LatLng courtPos) {
    double d = Geolocator.distanceBetween(
      currentPos.latitude, currentPos.longitude, 
      courtPos.latitude, courtPos.longitude
    );
    String label = d > 1000 ? "${(d/1000).toStringAsFixed(1)} km" : "${d.toInt()} m";
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        const Text("da te", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

