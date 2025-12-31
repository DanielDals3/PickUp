import 'package:flutter/material.dart';
import '../utils/sport_utils.dart';
import '../services/translator.dart';

class FilterBar extends StatelessWidget {
  final List<String> availableSports;
  final List<String> selectedSports;
  final Function(String) onSportToggled;

  const FilterBar({
    super.key,
    required this.availableSports,
    required this.selectedSports,
    required this.onSportToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: availableSports.length,
        itemBuilder: (context, index) {
          final sport = availableSports[index];
          final isSelected = selectedSports.contains(sport);
          final color = SportUtils.getIconColor(sport);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              avatar: Icon(
                SportUtils.getIconData(sport),
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              label: Text(
                Translator.of(sport),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              onSelected: (_) => onSportToggled(sport),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? color : Colors.transparent),
              ),
            ),
          );
        },
      ),
    );
  }
}