import 'package:flutter/material.dart';

class SportUtils {
  static IconData getIconData(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'unknown':
        return Icons.device_unknown;
      case 'basketball':
        return Icons.sports_basketball;
      case 'soccer':
      case 'football':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
      case 'volley':
        return Icons.sports_volleyball;
      case 'beachvolleyball':
        return Icons.sports_volleyball;
      case 'fitness':
      case 'gym':
        return Icons.fitness_center;
      case 'climbing':
        return Icons.terrain;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'gymnastics':
        return Icons.sports_gymnastics;
      case 'cycling':
        return Icons.directions_bike;
      case 'running':
        return Icons.directions_run;
      case 'table_tennis':
        return Icons.table_restaurant;
      case 'skiing':
        return Icons.downhill_skiing;
      case 'snowboarding':
      case 'snowboard':
        return Icons.snowboarding;
      case 'padel':
        return Icons.sports_tennis;
      case 'rugby_union':
      case 'rugby':
      case 'rugby_league':
        return Icons.sports_rugby;
      case 'american_football':
        return Icons.sports_football;
      case 'baseball':
      case 'softball':
        return Icons.sports_baseball;
      case 'skateboard':
      case 'skateboarding':
        return Icons.skateboarding;
      case 'golf':
        return Icons.sports_golf;
      case 'martial_arts':
      case 'karate':
      case 'judo':
        return Icons.sports_martial_arts;
      case 'equestrian':
      case 'horse_riding':
        return Icons.cruelty_free;
      case 'hockey':
      case 'ice_hockey':
        return Icons.sports_hockey;
      case 'boules':
      case 'bocce':
        return Icons.circle;
      case 'boxing':
        return Icons.sports_mma;
      case 'calisthenics':
        return Icons.accessibility_new;
      case 'roller_hockey':
        return Icons.roller_skating;
      default:
        return Icons.sports; 
    }
  }

  static Color getIconColor(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'unknown': 
        return Colors.red;
      case 'basketball': 
        return Colors.orange;
      case 'soccer':
      case 'football':
        return Colors.green[800]!;
      case 'tennis': 
        return Colors.lime[700]!;
      case 'padel':
        return Colors.teal[600]!;
      case 'volleyball': 
      case 'volley':
        return Colors.blue[700]!;
      case 'beachvolleyball': 
        return Colors.amber[800]!;
      case 'fitness':
      case 'gym':
        return Colors.blueGrey[700]!;
      case 'climbing':
        return Colors.brown[600]!;
      case 'swimming':
        return Colors.cyan[600]!;
      case 'yoga':
        return Colors.purple[400]!;
      case 'gymnastics':
        return Colors.pink[400]!;
      case 'cycling':
        return Colors.deepOrange[600]!;
      case 'running':
        return Colors.red[400]!;
      case 'table_tennis':
        return Colors.green[600]!;
      case 'skiing':
        return Colors.lightBlue[300]!;
      case 'snowboarding':
      case 'snowboard':
        return Colors.indigo[400]!;
      case 'rugby':
      case 'rugby_union':
      case 'rugby_league':
        return const Color(0xFF800020);
      case 'american_football':
        return Colors.brown[700]!;
      case 'baseball':
      case 'softball':
        return Colors.red[900]!;
      case 'skateboard':
      case 'skateboarding':
        return Colors.grey[800]!;
      case 'golf':
        return Colors.lightGreen[900]!;
      case 'martial_arts':
      case 'karate':
      case 'judo':
        return Colors.red[700]!;
      case 'equestrian':
      case 'horse_riding':
        return Colors.brown[400]!;
      case 'hockey':
      case 'ice_hockey':
        return Colors.blueAccent;
      case 'boules':
      case 'bocce':
        return Colors.blueGrey[400]!;
      case 'boxing':
        return Colors.orangeAccent;
      case 'calisthenics':
        return Color(0xFF388E3C);
      case 'roller_hockey':
        return Color(0xFF006064);
      default: 
        return Colors.grey[600]!;
    }
  }

  static Widget buildMiniIcon(String sport) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Icon(
        getIconData(sport), 
        size: 13,
        color: getIconColor(sport)
      ),
    );
  }
}