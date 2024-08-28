import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io'; 

class OpenAIService {
  static Future<Map<String, dynamic>> getPokedexEntry(String query) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    var requestBody = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "Du er en Pokedex designet til at beskrive fiktive Pokémon. Givet en beskrivelse af et objekt, bør du outputte et JSON-objekt med følgende felter: navn (et opfundet Pokémon navn), art, weight, height, hp, attack, defense, speed, og type (skal være 1 pokemoner typer). Navnet skal være fantasifuldt og passe til beskrivelsen."
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

    print("Request body: $requestBody");
    print("Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      // Sørg for at dekode body'en korrekt som UTF-8
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      var content = data['choices'][0]['message']['content'];

      // Fjern markdown code block syntax hvis tilstede
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      print("Parsed content after removing markdown: $content");

      try {
        return jsonDecode(content); // Dette returnerer et Map<String, dynamic>
      } catch (e) {
        print("Error parsing JSON: $e");
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

  static Future<String> analyzeImage(List<int> imageBytes) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final base64Image = base64Encode(imageBytes).replaceAll('\n', ''); 

    var requestBody = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": "Beskriv dette billede som en Pokémon, med et fantasifuldt navn og detaljer om dets art, type, og andre relevante egenskaber som passer til det, der ses på billedet."
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

    print("Request body: $requestBody");
    print("Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      // Sørg for at dekode body'en korrekt som UTF-8
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      var content = data['choices'][0]['message']['content'];

      // Fjern markdown code block syntax hvis tilstede
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      print("Parsed content after removing markdown: $content");

      // Ekstraher kun den relevante del af beskrivelsen
      String filteredDescription = _extractDescription(content);

      return filteredDescription;
    } else {
      throw Exception('Fejl ved billedanalyse: ${response.statusCode}');
    }
  }

  static String _extractDescription(String content) {
    // Del op i linjer
    List<String> lines = content.split('\n');

    // Find linjer, der starter med **Beskrivelse:**, og fjern alt før det
    int startIndex = lines.indexWhere((line) => line.startsWith('**Beskrivelse:**'));

    // Hvis Beskrivelse ikke findes, returner hele content
    if (startIndex == -1) return content;

    // Sammensæt beskrivelsen fra startIndex og frem
    return lines.skip(startIndex).join('\n').trim();
  }
  static Future<void> savePokedexEntry(Map<String, dynamic> entry, File image) async {
    final uri = Uri.parse('https://h4-jwt.onrender.com/api/Pokedex');

    try {
      var request = http.MultipartRequest('POST', uri)
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
        print('Pokémon entry saved successfully');
        final responseBody = await response.stream.bytesToString();
        print('Response body: $responseBody');
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Failed to save Pokémon entry: ${response.statusCode}');
        print('Response body: $responseBody');
        throw Exception('Failed to save Pokémon entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while saving Pokémon entry: $e');
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