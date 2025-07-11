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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Now Playing"),
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 100),
                    const SizedBox(height: 20),
                    Text(
                      song.path.split('/').last,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: clamped.inSeconds.toDouble(),
                      min: 0,
                      max: total.inSeconds.toDouble(),
                      onChanged: (v) =>
                          playback.seekTo(Duration(seconds: v.toInt())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(clamped)),
                        Text(_formatDuration(total)),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                              icon: Icon(isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle),
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
