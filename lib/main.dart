import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler.dart';
import 'services/music_service.dart';
import 'providers/music_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions
  await _requestPermissions();
  
  // Initialize audio service
  final audioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player.channel.audio',
      androidNotificationChannelName: 'Music Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  
  runApp(MusicPlayerApp(audioHandler: audioHandler));
}

Future<void> _requestPermissions() async {
  final permissions = <Permission>[
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.notification,
  ];
  
  // For Android 13+ (API 33+)
  if (await Permission.audio.isPermanentlyDenied == false) {
    permissions.add(Permission.audio);
  }
  
  await permissions.request();
}

class MusicPlayerApp extends StatelessWidget {
  final AudioHandler audioHandler;
  
  const MusicPlayerApp({Key? key, required this.audioHandler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioHandler>.value(value: audioHandler),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        Provider(create: (_) => MusicService()),
      ],
      child: MaterialApp(
        title: 'Music Player',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1a1a1a),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2a2a2a),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}