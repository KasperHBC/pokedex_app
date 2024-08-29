import 'package:flutter/material.dart';

class TopSection extends StatelessWidget {
  final Map<String, dynamic> pokedexEntry;
  final VoidCallback onBackPressed;

  const TopSection({
    super.key,
    required this.pokedexEntry,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: onBackPressed,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pokedexEntry['navn'] ?? 'Pokémon',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(
                  pokedexEntry['type'] ?? 'Type',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black26,
              ),
            ],
          ),
          Text(
            '#${pokedexEntry['id'] ?? '000'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}