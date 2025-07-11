import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FullPlayerPage extends StatefulWidget {
  final List<FileSystemEntity> musicFiles;
  final int currentIndex;
  final AudioPlayer player;

  const FullPlayerPage({
    super.key,
    required this.musicFiles,
    required this.currentIndex,
    required this.player,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
    _playCurrent();
  }

  Future<void> _playCurrent() async {
    final path = widget.musicFiles[currentIndex].path;
    await widget.player.setFilePath(path);
    widget.player.play();
    setState(() {});
  }

  void _playNext() {
    if (currentIndex < widget.musicFiles.length - 1) {
      currentIndex++;
      _playCurrent();
    }
  }

  void _playPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      _playCurrent();
    }
  }

  String _formatDuration(Duration d) {
    return d.toString().split('.').first.padLeft(8, "0");
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.musicFiles[currentIndex];
    final fileName = file.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Now Playing"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Duration?>(
        stream: widget.player.durationStream,
        builder: (context, snapshot) {
          final total = snapshot.data ?? Duration.zero;

          return StreamBuilder<Duration>(
            stream: widget.player.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              final clampedPos = position > total ? total : position;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 100),
                    const SizedBox(height: 20),
                    Text(fileName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 20),

                    Slider(
                      value: clampedPos.inSeconds.toDouble(),
                      min: 0,
                      max: total.inSeconds.toDouble(),
                      onChanged: (value) {
                        widget.player.seek(Duration(seconds: value.toInt()));
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(clampedPos)),
                        Text(_formatDuration(total)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 40),
                          onPressed: currentIndex > 0 ? _playPrevious : null,
                        ),
                        StreamBuilder<bool>(
                          stream: widget.player.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  widget.player.pause();
                                } else {
                                  widget.player.play();
                                }
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 40),
                          onPressed: currentIndex < widget.musicFiles.length - 1
                              ? _playNext
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
