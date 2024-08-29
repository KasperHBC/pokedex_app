import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class OpenAIService {
  static Future<String> analyzeImage(List<int> imageBytes) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final base64Image = base64Encode(imageBytes).replaceAll('\n', '');

    final requestBody = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": "Beskriv dette billede som en Pokémon. Du skal beskrive følgende om den: Kort om den, Udseende, Biologi, Levested, angreb, udviklinger (og hvordan den udvikler sig)"
            },
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,$base64Image",
                "detail": "auto"
              }
            }
          ]
        }
      ],
      "max_tokens": 1000
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      var content = data['choices'][0]['message']['content'];

      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      return _extractDescription(content);
    } else {
      throw Exception('Fejl ved billedanalyse: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getPokedexEntry(String query) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final requestBody = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "Du er en Pokedex designet til at beskrive fiktive Pokémon. Givet en beskrivelse af et objekt, bør du outputte et JSON-objekt med følgende felter: navn (et opfundet Pokémon navn), art(hvilken slags rigtig ting den minder om, eg. plante pokemen, kop pokemon, osv., weight(mellem 5-1000 kg), height(mellem 10-1000 centimeter), hp(mellem 50-255), attack(mellem 10-200), defense(mellem 10-200), speed(mellem 10-200), og type (skal være 1 pokemon typer på engelsk). Navnet skal være fantasifuldt og passe til beskrivelsen."
        },
        {
          "role": "user",
          "content": "Beskriv $query som en Pokémon."
        }
      ],
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      var content = data['choices'][0]['message']['content'];

      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        return jsonDecode(content);
      } catch (e) {
        return {
          'navn': 'Fejl',
          'art': 'Ukendt',
          'type': 'Fejl',
          'description': 'Fejl ved JSON parsing: $e'
        };
      }
    } else {
      throw Exception('Fejl ved hentning af data: ${response.statusCode}');
    }
  }

  static String _extractDescription(String content) {
    final lines = content.split('\n');
    final startIndex = lines.indexWhere((line) => line.startsWith('**Beskrivelse:**'));

    if (startIndex == -1) return content;

    return lines.skip(startIndex).join('\n').trim();
  }

  static Future<void> savePokedexEntry(Map<String, dynamic> entry, File image) async {
    final uri = Uri.parse('https://h4-jwt.onrender.com/api/Pokedex');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['Name'] = entry['navn']
        ..fields['Type'] = entry['type']
        ..fields['Art'] = entry['art']
        ..fields['Hp'] = entry['hp'].toString()
        ..fields['Attack'] = entry['attack'].toString()
        ..fields['Defense'] = entry['defense'].toString()
        ..fields['Speed'] = entry['speed'].toString()
        ..fields['Weight'] = entry['weight'].toInt().toString()
        ..fields['Height'] = entry['height'].toInt().toString()
        ..fields['Description'] = entry['description']
        ..files.add(await http.MultipartFile.fromPath('ProfilePicture', image.path));

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await response.stream.bytesToString();
      } else {
        await response.stream.bytesToString();
        throw Exception('Failed to save Pokémon entry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Exception occurred while saving Pokémon entry: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPokedexEntries() async {
    final uri = Uri.parse('https://h4-jwt.onrender.com/api/Pokedex');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch Pokémon entries: ${response.statusCode}');
    }
  }
}