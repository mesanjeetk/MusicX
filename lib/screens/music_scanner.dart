import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'full_player_page.dart';

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
      debugPrint("\u274c Permission denied");
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
          debugPrint("\u26a0\ufe0f Error scanning $path: $e");
        }
      }
    }

    setState(() {
      musicFiles = allFiles;
      isLoading = false;
    });
  }

  Widget _buildMiniPlayer(BuildContext context) {
    if (_currentlyPlayingPath == null) return const SizedBox();
    final fileName = _currentlyPlayingPath!.split('/').last;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullPlayerPage(
              musicFiles: musicFiles,
              currentIndex: musicFiles.indexWhere((f) => f.path == _currentlyPlayingPath),
              player: _player,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.music_note),
            const SizedBox(width: 8),
            Expanded(child: Text(fileName, overflow: TextOverflow.ellipsis)),
            StreamBuilder<bool>(
              stream: _player.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
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
                          final fileName = file.path.split('/').last;

                          return ListTile(
                            title: Text(fileName),
                            leading: const Icon(Icons.music_note),
                            onTap: () {
                              setState(() {
                                _currentlyPlayingPath = file.path;
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullPlayerPage(
                                    musicFiles: musicFiles,
                                    currentIndex: index,
                                    player: _player,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          _buildMiniPlayer(context),
        ],
      ),
    );
  }
}