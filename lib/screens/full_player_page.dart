import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/playback_manager.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  String _formatDuration(Duration d) =>
      d.toString().split('.').first.padLeft(8, "0");

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = Provider.of<PlaybackManager>(context);
    final song = playback.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(child: Text("No song is currently playing.")),
      );
    }

    final fileName = song.path.split('/').last.replaceAll(RegExp(r'\.(mp3|m4a|wav|ogg)$'), '');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                    // Rotating Artwork with Border
                    _RotatingBorder(
                      controller: _controller,
                      child: Image.asset(
                        'assets/logo.png',
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
                        color: Colors.white,
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
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey[700],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(clamped), style: const TextStyle(color: Colors.white70)),
                        Text(_formatDuration(total), style: const TextStyle(color: Colors.white70)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 40),
                          color: Colors.white,
                          onPressed: playback.playPrevious,
                        ),
                        StreamBuilder<bool>(
                          stream: playback.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 64,
                              color: Colors.white,
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
                          color: Colors.white,
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

class _RotatingBorder extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _RotatingBorder({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Transform.rotate(
          angle: controller.value * 2 * pi,
          child: Container(
            width: 250,
            height: 250,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Colors.purple,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(child: child),
          ),
        );
      },
    );
  }
}
