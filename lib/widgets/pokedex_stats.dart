import 'package:flutter/material.dart';

class PokedexStats extends StatelessWidget {
  final Map<String, dynamic> entry;

  const PokedexStats({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Navn: ${entry['navn'] ?? 'Ikke tilgængelig'}', style: Theme.of(context).textTheme.titleLarge),
            Text('Art: ${entry['art'] ?? 'Ikke tilgængelig'}'),
            Text('Type: ${entry['type'] ?? 'Ikke tilgængelig'}'),
            const SizedBox(height: 16),
            _buildStatRow('HP', entry['hp'], 255),
            _buildStatRow('Angreb', entry['attack'], 200),
            _buildStatRow('Forsvar', entry['defense'], 200),
            _buildStatRow('Hastighed', entry['speed'], 200),
            _buildStatRow('Vægt (kg)', entry['weight'], 1000),
            _buildStatRow('Højde (cm)', entry['height'], 1000),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String statName, dynamic statValue, int maxValue) {
    double progress = 0.0;
    if (statValue is int || statValue is double) {
      progress = (statValue as num) / maxValue;
    }

    Color progressColor;
    if (progress < 0.3) {
      progressColor = Colors.red;
    } else if (progress < 0.7) {
      progressColor = Colors.yellow;
    } else {
      progressColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(statName, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: progressColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statValue != null ? statValue.toString() : 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}