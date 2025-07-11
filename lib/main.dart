
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'screens/music_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MusicScanner(),
      debugShowCheckedModeBanner: false,
    );
  }
}
