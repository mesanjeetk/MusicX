import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/playback_manager.dart';

class FullPlayerPage extends StatelessWidget {
  const FullPlayerPage({super.key});

  String _formatDuration(Duration d) =>
      d.toString().split('.').first.padLeft(8, "0");

  @override
  Widget build(BuildContext context) {
    final playback = Provider.of<PlaybackManager>(context);
    final song = playback.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(child: Text("No song is currently playing.")),
      );
    }

    final fileName = song.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Now Playing"),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Duration?>(
        stream: playback.durationStream,
        builder: (context, durSnap) {
          final total = durSnap.data ?? Duration.zero;

          return StreamBuilder<Duration>(
            stream: playback.positionStream,
            builder: (context, posSnap) {
              final position = posSnap.data ?? Duration.zero;
              final clamped = position > total ? total : position;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://via.placeholder.com/300x300.png?text=No+Artwork',
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      fileName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Unknown Artist",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Seek Bar
                    Slider(
                      value: clamped.inSeconds.toDouble(),
                      min: 0,
                      max: total.inSeconds.toDouble().clamp(1, double.infinity),
                      onChanged: total.inSeconds == 0
                          ? null
                          : (v) => playback.seekTo(Duration(seconds: v.toInt())),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(clamped)),
                        Text(_formatDuration(total)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 40),
                          onPressed: playback.playPrevious,
                        ),
                        StreamBuilder<bool>(
                          stream: playback.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              onPressed: playback.togglePlayPause,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 40),
                          onPressed: playback.playNext,
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
