import 'package:flutter/material.dart';
import 'package:pokedex_app/services/openai_service.dart';

class PokedexListScreen extends StatefulWidget {
  const PokedexListScreen({super.key});

  @override
  _PokedexListScreenState createState() => _PokedexListScreenState();
}

class _PokedexListScreenState extends State<PokedexListScreen> {
  late Future<List<Map<String, dynamic>>> _pokedexEntries;

  @override
  void initState() {
    super.initState();
    _pokedexEntries = OpenAIService.fetchPokedexEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Liste'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pokedexEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Ingen Pokémon fundet.'));
          } else {
            final pokedexEntries = snapshot.data!;
            return ListView.builder(
              itemCount: pokedexEntries.length,
              itemBuilder: (context, index) {
                final entry = pokedexEntries[index];
                return ListTile(
                  leading: Image.network(entry['imageUrl']), // Antager at imageUrl er en del af entry
                  title: Text(entry['name']),
                  subtitle: Text(entry['type']),
                  onTap: () {
                    Navigator.of(context).pop(entry);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}