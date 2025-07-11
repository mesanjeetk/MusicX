import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/music_provider.dart';
import 'services/audio_handler.dart';
import 'widgets/permission_handler_widget.dart';
import 'screens/home_screen.dart';
import 'services/sleep_timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio service
  final audioHandler = await AudioService.init<MusicAudioHandler>(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musicplayer.channel.audio',
      androidNotificationChannelName: 'Music Player',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
  
  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final MusicAudioHandler audioHandler;
  
  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MusicProvider(audioHandler)),
        ChangeNotifierProvider(create: (context) => SleepTimerService()),
      ],
      child: MaterialApp(
        title: 'Music Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
        ),
        home: const PermissionHandlerWidget(
          child: HomeScreen(),
        ),
      ),
    );
  }
}