import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/permission_service.dart';
import '../services/playback_manager.dart';
import '../services/cache_service.dart';
import 'full_player_page.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicScanner extends StatefulWidget {
  const MusicScanner({super.key});

  @override
  State<MusicScanner> createState() => _MusicScannerState();
}

class _MusicScannerState extends State<MusicScanner> {
  final List<FileSystemEntity> _musicFiles = [];
  final Set<String> _uniquePaths = {};
  final List<String> validExtensions = ['mp3', 'wav', 'm4a', 'ogg'];
  final List<String> targetPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);

    final granted = await PermissionService.ensureAllPermissions();
    if (!granted) {
      setState(() => _loading = false);
      return;
    }
    await CacheService.removeDeletedSongsFromCache();     
    final cachedFiles = await CacheService.loadCachedSongs();
    for (final file in cachedFiles) {
      _uniquePaths.add(file.path);
      _musicFiles.add(file);
    }

    setState(() => _loading = false);
    _scanParentDirectories();
    _scanSubDirectoriesAsync();
  }

  Future<void> _scanParentDirectories() async {
    bool updated = false;
    for (final path in targetPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final entries = dir.listSync(recursive: false);
        for (final file in entries) {
          if (_isValidAudio(file) && _uniquePaths.add(file.path)) {
            _musicFiles.add(file);
            updated = true;
          }
        }
      }
    }
  
    if (updated) setState(() {});
    await CacheService.saveSongs(_musicFiles);
  }


  Future<void> _scanSubDirectoriesAsync() async {
    bool updated = false;
    for (final path in targetPaths) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        await for (final file in dir.list(recursive: true)) {
          if (_isValidAudio(file) && _uniquePaths.add(file.path)) {
            _musicFiles.add(file);
            updated = true;
          }
        }
      }
    }
  
    if (updated) setState(() {});
    await CacheService.saveSongs(_musicFiles);
  }


  bool _isValidAudio(FileSystemEntity file) {
    final lower = file.path.toLowerCase();
    return validExtensions.any((ext) => lower.endsWith('.$ext'));
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
        color: Colors.grey[900],
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

    return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ),
    ), child: Scaffold(
      appBar: AppBar(title: const Text("Music Files")),
      body: Column(
        children: [
          Expanded(
            child: _loading && _musicFiles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _musicFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("No music files found."),
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
                        itemCount: _musicFiles.length,
                        itemBuilder: (context, index) {
                          final file = _musicFiles[index];
                          return ListTile(
                            title: Text(file.path.split('/').last..replaceAll(RegExp(r'\.(mp3|wav|m4a|ogg)$', caseSensitive: false), '')),
                            leading: const Icon(Icons.music_note),
                            onTap: () {
                              final isSameSong = playback.currentSong?.path == file.path;
                              if (!isSameSong) {
                                playback.setPlaylist(_musicFiles, index);
                              }
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
    ));
  }
}
