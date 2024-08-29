import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pokedex_app/services/openai_service.dart';
import 'package:pokedex_app/screens/pokedex_list_screen.dart';
import 'package:pokedex_app/widgets/top_section.dart';
import 'package:pokedex_app/widgets/button_row.dart';
import 'package:pokedex_app/widgets/pokedex_stats.dart';
import 'package:pokedex_app/widgets/pokedex_description.dart';

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
    final splitted = filePath.substring(0, lastIndex);
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
        _pokedexEntry = _normalizeEntry(result);
        _pokedexEntry['description'] = imageDescription;
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

  Map<String, dynamic> _normalizeEntry(Map<String, dynamic> entry) {
    if (entry.containsKey('species')) {
      entry['art'] = entry['species'];
      entry.remove('species');
    }
    return entry;
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
          Container(
            color: _getBackgroundColor(_pokedexEntry['type']),
            height: MediaQuery.of(context).size.height * 0.4,
          ),
          SafeArea(
            child: Column(
              children: [
                TopSection(
                  pokedexEntry: _pokedexEntry,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
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
                ButtonRow(
                  isLoading: _isLoading,
                  onGetImage: _getImage,
                  onSelectFromList: _selectFromList,
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