import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../services/audio_handler.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioHandler = context.read<AudioHandler>() as MusicAudioHandler;
    
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              StreamBuilder<Duration>(
                stream: audioHandler.positionStream,
                builder: (context, positionSnapshot) {
                  return StreamBuilder<Duration?>(
                    stream: audioHandler.durationStream,
                    builder: (context, durationSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final duration = durationSnapshot.data ?? Duration.zero;
                      
                      return Slider(
                        value: duration.inMilliseconds > 0
                            ? position.inMilliseconds.toDouble()
                            : 0.0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          audioHandler.seek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: Colors.purple,
                        inactiveColor: Colors.grey[600],
                      );
                    },
                  );
                },
              ),
              
              // Player info and controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Album art placeholder
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Song info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mediaItem.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mediaItem.artist ?? '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Controls
                    StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, playbackSnapshot) {
                        final playbackState = playbackSnapshot.data;
                        final processingState = playbackState?.processingState;
                        final playing = playbackState?.playing ?? false;
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: () => audioHandler.skipToPrevious(),
                              color: Colors.white,
                            ),
                            
                            // Play/Pause button
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  processingState == AudioProcessingState.loading
                                      ? Icons.hourglass_empty
                                      : playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  if (playing) {
                                    audioHandler.pause();
                                  } else {
                                    audioHandler.play();
                                  }
                                },
                                color: Colors.white,
                              ),
                            ),
                            
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: () => audioHandler.skipToNext(),
                              color: Colors.white,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Time indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder<Duration>(
                      stream: audioHandler.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    StreamBuilder<Duration?>(
                      stream: audioHandler.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}