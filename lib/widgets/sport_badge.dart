import 'package:flutter/material.dart';
import '../utils/sport_utils.dart';
import '../services/translator_service.dart';

class SportBadge extends StatelessWidget {
  final String sportKey;
  final int count;

  const SportBadge({
    super.key, 
    required this.sportKey, 
    required this.count
  });

  @override
  Widget build(BuildContext context) {
    // Usiamo le utility centralizzate per i colori
    final Color sportColor = SportUtils.getIconColor(sportKey);
    final IconData sportIcon = SportUtils.getIconData(sportKey);

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.42,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sportColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sportColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sportIcon, size: 16, color: sportColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "${Translator.of(sportKey)}: $count",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: sportColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}