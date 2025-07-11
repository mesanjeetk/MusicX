import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:just_audio/just_audio.dart';

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

class MusicScanner extends StatefulWidget {
  const MusicScanner({super.key});

  @override
  State<MusicScanner> createState() => _MusicScannerState();
}

class _MusicScannerState extends State<MusicScanner> {
  List<FileSystemEntity> musicFiles = [];
  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];
  final List<String> targetPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
  ];
  bool isLoading = true;

  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    scanFolders();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> scanFolders() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    PermissionStatus status;
    if (sdkInt >= 33) {
      status = await Permission.audio.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      debugPrint("❌ Permission denied");
      setState(() => isLoading = false);
      return;
    }

    List<FileSystemEntity> allFiles = [];
    for (String path in targetPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final files = dir.listSync(recursive: true);
          allFiles.addAll(files.where((f) {
            final p = f.path.toLowerCase();
            return validExtensions.any((ext) => p.endsWith('.$ext'));
          }));
        } catch (e) {
          debugPrint("⚠️ Error scanning $path: $e");
        }
      }
    }

    setState(() {
      musicFiles = allFiles;
      isLoading = false;
    });
  }

  Future<void> _togglePlay(String path) async {
    if (_currentlyPlayingPath == path && _player.playing) {
      await _player.pause();
    } else {
      await _player.setFilePath(path);
      await _player.play();
    }

    setState(() {
      _currentlyPlayingPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Music Files")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : musicFiles.isEmpty
              ? const Center(child: Text("No music files found."))
              : ListView.builder(
                  itemCount: musicFiles.length,
                  itemBuilder: (context, index) {
                    final file = musicFiles[index];
                    final isPlaying = file.path == _currentlyPlayingPath && _player.playing;

                    return ListTile(
                      leading: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      title: Text(file.path.split('/').last),
                      subtitle: Text(file.path),
                      onTap: () => _togglePlay(file.path),
                    );
                  },
                ),
    );
  }
}
