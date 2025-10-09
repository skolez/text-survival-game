import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/game_state.dart';

class StatusBar extends StatefulWidget {
  final GameState gameState;

  const StatusBar({super.key, required this.gameState});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.12; // Slightly smaller: 12% max width

    return Container(
      width: maxWidth,
      decoration: AppTheme.panelDecoration.copyWith(
        color: AppTheme.backgroundColor.withValues(alpha: 0.9),
      ),
      padding: const EdgeInsets.all(6.0),
      child: FittedBox(
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - 3 stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactStat("❤️", "Health", widget.gameState.health),
                _buildCompactStat("🍖", "Hunger", widget.gameState.hunger),
                _buildCompactStat("💧", "Thirst", widget.gameState.thirst),
              ],
            ),
            const SizedBox(width: 10),
            // Right column - 3 stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactStat(
                    "😴", "Energy", 100 - widget.gameState.fatigue),
                _buildCompactStat("⛽", "Fuel", widget.gameState.fuel),
                _buildCompactStat(
                    "🎒",
                    "Weight",
                    ((widget.gameState.maxInventoryWeight -
                            widget.gameState.currentWeight) /
                        widget.gameState.maxInventoryWeight *
                        100)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String icon, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            "${value.toInt()}%",
            style: TextStyle(
              color: AppTheme.getStatusColor(value),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
