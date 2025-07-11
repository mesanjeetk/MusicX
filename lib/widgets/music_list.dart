import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/music_provider.dart';
import '../services/audio_handler.dart';

class MusicList extends StatelessWidget {
  const MusicList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading music from device...'),
              ],
            ),
          );
        }
        
        if (provider.songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No music found on device'),
                SizedBox(height: 8),
                Text(
                  'Make sure you have music files in your Music or Downloads folder',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: provider.songs.length,
          itemBuilder: (context, index) {
            final song = provider.songs[index];
            
            return StreamBuilder<MediaItem?>(
              stream: context.read<AudioHandler>().mediaItem,
              builder: (context, snapshot) {
                final currentSong = snapshot.data;
                final isPlaying = currentSong?.id == song.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPlaying ? Colors.purple : Colors.grey[700],
                    child: Icon(
                      isPlaying ? Icons.music_note : Icons.music_note_outlined,
                      color: isPlaying ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      color: isPlaying ? Colors.purple : null,
                    ),
                  ),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showSongOptions(context, song);
                    },
                  ),
                  onTap: () async {
                    final audioHandler = context.read<AudioHandler>() as MusicAudioHandler;
                    await audioHandler.updatePlaylist(provider.songs);
                    await audioHandler.playFromIndex(index);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  
  void _showSongOptions(BuildContext context, song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Song Info'),
              onTap: () {
                Navigator.pop(context);
                _showSongInfo(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSongInfo(BuildContext context, song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${song.artist}'),
            if (song.album != null) Text('Album: ${song.album}'),
            if (song.duration != null) 
              Text('Duration: ${_formatDuration(song.duration!)}'),
            Text('Path: ${song.path}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}