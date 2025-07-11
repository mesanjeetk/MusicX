import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/playback_manager.dart';
import 'screens/music_scanner.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaybackManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MusicScanner(),
    );
  }
}
