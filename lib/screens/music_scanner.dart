import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/playback_manager.dart';
import 'full_player_page.dart';

class MusicScanner extends StatefulWidget {
  const MusicScanner({super.key});

  @override
  State<MusicScanner> createState() => _MusicScannerState();
}

class _MusicScannerState extends State<MusicScanner> {
  List<FileSystemEntity> musicFiles = [];
  bool isLoading = true;

  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];
  final List<String> targetPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
  ];

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    scanFolders();
  }
  
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }


  Future<void> scanFolders() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    final status = sdkInt >= 33
        ? await Permission.audio.request()
        : await Permission.storage.request();

    if (!status.isGranted) {
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
        } catch (_) {}
      }
    }

    setState(() {
      musicFiles = allFiles;
      isLoading = false;
    });
  }

  Widget _buildMiniPlayer(PlaybackManager playback) {
    final song = playback.currentSong;
    if (song == null) return const SizedBox();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FullPlayerPage()),
      ),
      child: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.music_note),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                song.path.split('/').last,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StreamBuilder<bool>(
              stream: playback.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: playback.togglePlayPause,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = Provider.of<PlaybackManager>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Music Files")),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : musicFiles.isEmpty
                    ? const Center(child: Text("No music files found."))
                    : ListView.builder(
                        itemCount: musicFiles.length,
                        itemBuilder: (context, index) {
                          final file = musicFiles[index];
                          return ListTile(
                            title: Text(file.path.split('/').last),
                            leading: const Icon(Icons.music_note),
                            onTap: () {
                              playback.setPlaylist(musicFiles, index);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FullPlayerPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          _buildMiniPlayer(playback),
        ],
      ),
    );
  }
}
