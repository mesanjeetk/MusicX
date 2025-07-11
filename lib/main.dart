import 'package:flutter/material.dart';
// import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'services/playback_manager.dart';
import 'screens/splash_screen.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();

  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.yourapp.audio',
  //   androidNotificationChannelName: 'Music Playback',
  //   androidNotificationOngoing: true,
  // );
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
      home: const SplashScreen(),
    );
  }
}
