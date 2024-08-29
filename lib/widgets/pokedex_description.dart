import 'package:flutter/material.dart';

class PokedexDescription extends StatelessWidget {
  final String description;

  const PokedexDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final sections = _parseDescription(description);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: section['title'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: section['content']),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, String>> _parseDescription(String description) {
    final lines = description.split('\n');
    final sections = <Map<String, String>>[];
    String? currentTitle;
    StringBuffer currentContent = StringBuffer();

    for (var line in lines) {
      if (line.startsWith('**') && line.endsWith('**')) {
        if (currentTitle != null) {
          sections.add({
            'title': currentTitle,
            'content': currentContent.toString(),
          });
        }
        currentTitle = line.replaceAll('**', '');
        currentContent = StringBuffer();
      } else {
        currentContent.writeln(line);
      }
    }

    if (currentTitle != null) {
      sections.add({
        'title': currentTitle,
        'content': currentContent.toString(),
      });
    }

    return sections;
  }
}