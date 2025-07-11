import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All Audio Files',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioListPage(),
    );
  }
}

class AudioListPage extends StatefulWidget {
  const AudioListPage({super.key});

  @override
  State<AudioListPage> createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await _checkAudioPermission()) {
        fetchSongs();
      } else {
        _showPermissionDeniedDialog();
      }
    }
  }

  Future<bool> _checkAudioPermission() async {
    // For Android 13+ use READ_MEDIA_AUDIO
    if (Platform.isAndroid && androidInfo != null && androidInfo!.version.sdkInt >= 33) {
      final status = await Permission.audio.request();
      return status.isGranted;
    }

    // For Android < 13 use storage
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "This app needs permission to read your music files. Please grant it from app settings."),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          )
        ],
      ),
    );
  }

  Future<void> fetchSongs() async {
    final songs = await _audioQuery.querySongs();
    setState(() {
      _songs = songs;
    });
  }

  AndroidDeviceInfo? androidInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDeviceInfo();
  }

  void _loadDeviceInfo() async {
    final info = await DeviceInfoPlugin().androidInfo;
    setState(() {
      androidInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Songs")),
      body: _songs.isEmpty
          ? const Center(child: Text("No Songs Found or Permission Not Granted"))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? "Unknown Artist"),
                );
              },
            ),
    );
  }
}
