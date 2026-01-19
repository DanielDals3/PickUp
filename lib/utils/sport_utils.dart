import 'package:flutter/material.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SportUtils {
  static List<String> get availableSports => _availableSports;

  static final List<String> _availableSports = ['basketball', 'soccer', 'tennis', 'volleyball', 'beachvolleyball',
    'fitness', 'climbing', 'swimming', 'yoga', 'gymnastics', 'cycling', 'running', 'table_tennis', 'skiing', 
     'padel', 'gym', 'football', 'snowboarding', 'rugby_union', 'rugby', 'rugby_league', 'american_football',
     'baseball', 'softball', 'skateboard', 'skateboarding', 'golf', 'martial_arts', 'karate', 'judo', 'equestrian',
     'horse_riding', 'hockey', 'ice_hockey', 'boules', 'bocce', 'volley', 'boxing', 'calisthenics','snowboard',
     'roller_hockey' ];

  static IconData getIconData(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'unknown':
        return FontAwesomeIcons.question;
      case 'basketball':
        return FontAwesomeIcons.basketball;
      case 'soccer':
      case 'football':
        return FontAwesomeIcons.futbol;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
      case 'volley':
      case 'beachvolleyball':
        return FontAwesomeIcons.volleyball;
      case 'fitness':
      case 'gym':
        return FontAwesomeIcons.dumbbell;
      case 'climbing':
        return FontAwesomeIcons.mountain;
      case 'swimming':
        return FontAwesomeIcons.personSwimming;
      case 'yoga':
        return FontAwesomeIcons.spa;
      case 'gymnastics':
        return FontAwesomeIcons.childReaching;
      case 'cycling':
        return FontAwesomeIcons.bicycle;
      case 'running':
        return FontAwesomeIcons.personRunning;
      case 'table_tennis':
        return FontAwesomeIcons.tableTennisPaddleBall;
      case 'skiing':
        return FontAwesomeIcons.personSkiing;
      case 'snowboarding':
      case 'snowboard':
        return FontAwesomeIcons.personSnowboarding;
      case 'padel':
        return Icons.sports_tennis;
      case 'rugby_union':
      case 'rugby':
      case 'rugby_league':
        return Icons.sports_rugby;
      case 'american_football':
        return FontAwesomeIcons.football;
      case 'baseball':
      case 'softball':
        return FontAwesomeIcons.baseball;
      case 'skateboard':
      case 'skateboarding':
        return Icons.skateboarding;
      case 'golf':
        return FontAwesomeIcons.golfBallTee;
      case 'martial_arts':
      case 'karate':
      case 'judo':
        return Icons.sports_martial_arts;
      case 'equestrian':
      case 'horse_riding':
        return FontAwesomeIcons.horse;
      case 'hockey':
      case 'ice_hockey':
        return FontAwesomeIcons.hockeyPuck;
      case 'boules':
      case 'bocce':
        return FontAwesomeIcons.circle;
      case 'boxing':
        return Icons.sports_mma;
      case 'calisthenics':
        return Icons.accessibility_new;
      case 'roller_hockey':
        return Icons.roller_skating;
      default:
        return FontAwesomeIcons.medal; 
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
        return Colors.grey;
      case 'ice_hockey':
        return Colors.blueAccent;
      case 'boules':
      case 'bocce':
        return Colors.blueGrey[400]!;
      case 'boxing':
        return Colors.orangeAccent;
      case 'calisthenics':
        return const Color(0xFF388E3C);
      case 'roller_hockey':
        return const Color(0xFF006064);
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

  static List<String> get uniqueSports {
    final Set<String> seenLabels = {};
    final List<String> list = SportUtils._availableSports.where((sport) {
      final label = Translator.of(sport);
      if (seenLabels.contains(label)) return false;
      seenLabels.add(label);
      return true;
    }).toList();
    
    list.sort((a, b) => Translator.of(a).compareTo(Translator.of(b)));
    return list;
  }

  static List<String> getCleanedSportsForCourt(List<String> rawSports) {
    return rawSports
        .map((s) => s.trim().toLowerCase())
        .where((s) => _availableSports.contains(s))
        .toSet() // Rimuove duplicati ID (es. football e soccer)
        .toList();
  }
}