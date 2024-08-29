import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pokedex_app/services/openai_service.dart';
import 'package:pokedex_app/screens/pokedex_list_screen.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  _PokedexScreenState createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  File? _image;
  bool _isLoading = false;
  bool _showDetails = false;
  Map<String, dynamic> _pokedexEntry = {};

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      File compressedFile = await _compressImage(File(image.path));
      setState(() {
        _image = compressedFile;
      });
      await _analyzeImage();
    }
  }

  Future<File> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_compressed.jpg";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
    );

    return File(result!.path);
  }

 Future<void> _analyzeImage() async {
  if (_image == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final imageBytes = await _image!.readAsBytes();
    final description = await OpenAIService.analyzeImage(imageBytes);
    await _getEntry(description);
    
    // Prøv at gemme i databasen, men håndter fejl uden at påvirke UI
    try {
      await OpenAIService.savePokedexEntry(_pokedexEntry, _image!);
    } catch (e) {
      print('Failed to save Pokémon entry to database: $e');
    }
  } catch (e) {
    setState(() {
      _pokedexEntry = {
        'navn': 'Fejl',
        'art': 'Ukendt',
        'type': 'Fejl',
        'description': 'Fejl ved billedanalyse: $e',
      };
    });
    print('Exception occurred: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _getEntry(String imageDescription) async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await OpenAIService.getPokedexEntry(imageDescription);
    setState(() {
      _pokedexEntry = result;
      _pokedexEntry['description'] = imageDescription;
      // Kontroller om 'name' findes og sæt 'navn' til dens værdi hvis den gør
      if (_pokedexEntry.containsKey('name')) {
        _pokedexEntry['navn'] = _pokedexEntry['name'];
      }
    });
  } catch (e) {
    setState(() {
      _pokedexEntry = {
        'navn': 'Fejl',
        'art': 'Ukendt',
        'type': 'Fejl',
        'description': 'Fejl ved hentning af data: $e',
      };
    });
    print('Exception occurred while fetching entry: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  Future<void> _selectFromList() async {
    final selectedEntry = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PokedexListScreen()),
    );

    if (selectedEntry != null) {
      setState(() {
        _pokedexEntry = selectedEntry;
        _image = null; 
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AI Pokedex'),
    ),
    body: Stack(
      children: [
        // Baggrundsfarve baseret på Pokémon-type
        Container(
          color: _getBackgroundColor(_pokedexEntry['type']),
          height: MediaQuery.of(context).size.height * 0.4,
        ),
        SafeArea(
          child: Column(
            children: [
              // Top sektion med navn, type og nummer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pokedexEntry['navn'] ?? 'Pokémon',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            _pokedexEntry['type'] ?? 'Type',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black26,
                        ),
                      ],
                    ),
                    Text(
                      '#${_pokedexEntry['id'] ?? '000'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Rundt Pokémon billede
              if (_image != null)
                Center(
                  child: ClipOval(
                    child: Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (_pokedexEntry['imageUrl'] != null)
                Center(
                  child: ClipOval(
                    child: Image.network(
                      _pokedexEntry['imageUrl'],
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Knapperne til at tage et billede og vælge fra liste ved siden af hinanden
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getImage,
                    child: const Text('Tag billede'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _selectFromList,
                    child: const Text('Vælg fra liste'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: _showDetails
                      ? PokedexDescription(description: _pokedexEntry['description'] ?? 'Ingen beskrivelse tilgængelig')
                      : PokedexStats(entry: _pokedexEntry),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _toggleDetails,
                child: Text(_showDetails ? 'Vis Basis Information' : 'Vis Beskrivelse'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // Metode til at bestemme baggrundsfarve baseret på Pokémon-type
  Color _getBackgroundColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'normal':
        return Colors.brown[300]!;
      case 'fire':
        return Colors.redAccent;
      case 'water':
        return Colors.blueAccent;
      case 'electric':
        return Colors.yellowAccent;
      case 'grass':
        return Colors.green;
      case 'ice':
        return Colors.cyanAccent[400]!;
      case 'fighting':
        return Colors.orangeAccent[700]!;
      case 'poison':
        return Colors.purpleAccent;
      case 'ground':
        return Colors.brown;
      case 'flying':
        return Colors.lightBlueAccent;
      case 'psychic':
        return Colors.pinkAccent;
      case 'bug':
        return Colors.lightGreenAccent[700]!;
      case 'rock':
        return Colors.grey;
      case 'ghost':
        return Colors.deepPurpleAccent;
      case 'dragon':
        return Colors.indigoAccent;
      case 'dark':
        return Colors.black54;
      case 'steel':
        return Colors.blueGrey;
      case 'fairy':
        return Colors.pink[200]!;
      default:
        return Colors.grey;
    }
  }
}

// Stat-visning med progress bars
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
            _buildStatRow('Vægt (kg)', entry['weight'], 1000), // Vægt antager en max værdi på 1000 kg
            _buildStatRow('Højde (cm)', entry['height'], 1000),  // Højde antager en max værdi på 10 meter
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

    // Bestem farven baseret på progress
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

// Beskrivelsesvisning
class PokedexDescription extends StatelessWidget {
  final String description;

  const PokedexDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
