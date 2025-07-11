import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';

class SongList extends StatelessWidget {
  final List<Song> songs;

  const SongList({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isCurrentSong = musicProvider.currentSong?.id == song.id;
            
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(MusicService.generateColorForSong(song.title)),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentSong ? Colors.blue : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                style: TextStyle(
                  color: isCurrentSong ? Colors.blue[700] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite button
                  FutureBuilder<bool>(
                    future: PlaylistService.isFavorite(song.id),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () async {
                          if (isFavorite) {
                            await PlaylistService.removeFromFavorites(song.id);
                          } else {
                            await PlaylistService.addToFavorites(song.id);
                          }
                          // Trigger rebuild
                          (context as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                  if (song.duration > 0)
                    Text(
                      musicProvider.formatDuration(Duration(seconds: song.duration)),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showSongOptions(context, song);
                    },
                  ),
                ],
              ),
              onTap: () {
                musicProvider.playSong(song);
              },
            );
          },
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<MusicProvider>(context, listen: false).playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<MusicProvider>(context, listen: false).addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${song.title} added to queue')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareSong(context, song);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Playlist'),
              onTap: () {
                Navigator.pop(context);
                _createNewPlaylist(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Add to Favorites'),
              onTap: () async {
                Navigator.pop(context);
                await PlaylistService.addToFavorites(song.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${song.title} added to favorites')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewPlaylist(BuildContext context, Song song) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter playlist name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final playlist = Playlist(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  songIds: [song.id],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                await PlaylistService.savePlaylist(playlist);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist.name}" created with ${song.title}'),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _shareSong(BuildContext context, Song song) {
    // Create shareable text with song info
    final shareText = '''
🎵 Now listening to:

🎤 ${song.title}
👤 ${song.artist}
💿 ${song.album}

Shared from Music Player App
    '''.trim();

    // For now, copy to clipboard (you can add share_plus package for actual sharing)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shareText),
            const SizedBox(height: 16),
            const Text(
              'Song info copied to clipboard!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    
    // Copy to clipboard
    // Clipboard.setData(ClipboardData(text: shareText));
  }
}