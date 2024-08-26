import 'package:flutter/material.dart';

class PokedexEntry extends StatelessWidget {
  final Map<String, dynamic> entry;

  const PokedexEntry({super.key, required this.entry});

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
            Text('Vægt: ${entry['weight'] ?? 'Ikke tilgængelig'}'),
            Text('Højde: ${entry['height'] ?? 'Ikke tilgængelig'}'),
            Text('HP: ${entry['hp'] ?? 'Ikke tilgængelig'}'),
            Text('Angreb: ${entry['attack'] ?? 'Ikke tilgængelig'}'),
            Text('Forsvar: ${entry['defense'] ?? 'Ikke tilgængelig'}'),
            Text('Hastighed: ${entry['speed'] ?? 'Ikke tilgængelig'}'),
            const SizedBox(height: 16), // Tilføj lidt afstand før beskrivelsen
            Text('Beskrivelse: ${entry['description'] ?? 'Ingen beskrivelse tilgængelig'}'),
          ],
        ),
      ),
    );
  }
}
