import 'package:flutter/material.dart';
import '../models/game_state.dart';

class StatusBar extends StatelessWidget {
  final GameState gameState;

  const StatusBar({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[900],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatBar("Health", gameState.health, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBar("Hunger", gameState.hunger, Colors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildStatBar("Thirst", gameState.thirst, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBar("Fatigue", 100 - gameState.fatigue, Colors.green)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildStatBar("Fuel", gameState.fuel, Colors.purple)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Weight: ${gameState.currentWeight.toStringAsFixed(1)}/${gameState.maxInventoryWeight}kg",
                    style: TextStyle(
                      color: gameState.currentWeight > gameState.maxInventoryWeight * 0.8 
                          ? Colors.red 
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    final percentage = (value / 100.0).clamp(0.0, 1.0);
    
    // Determine color based on value
    Color barColor = color;
    if (percentage < 0.25) {
      barColor = Colors.red;
    } else if (percentage < 0.5) {
      barColor = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ${value.toInt()}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
