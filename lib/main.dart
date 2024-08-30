import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pokedex_app/screens/pokedex_screen.dart';
import 'package:pokedex_app/screens/pokedex_list_screen.dart'; 

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI MercanDex',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PokedexScreen(),
      routes: {
        '/pokedexList': (context) => const PokedexListScreen(), 
      },
    );
  }
}