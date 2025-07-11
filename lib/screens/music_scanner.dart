import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/permission_service.dart';
import '../services/playback_manager.dart';
import 'full_player_page.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicScanner extends StatefulWidget {
  const MusicScanner({super.key});

  @override
  State<MusicScanner> createState() => _MusicScannerState();
}

class _MusicScannerState extends State<MusicScanner> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initialize(); // Recheck permissions when returning to app
    }
  }

  Future<void> _initialize() async {
    setState(() => isLoading = true);

    final granted = await PermissionService.ensureAllPermissions();
    if (!granted) {
      setState(() => isLoading = false);
      return;
    }

    scanFolders();
  }

  Future<void> scanFolders() async {
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
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Permission denied or no music files found.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => openAppSettings(),
                              icon: const Icon(Icons.settings),
                              label: const Text("Open App Settings"),
                            ),
                          ],
                        ),
                      )
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
