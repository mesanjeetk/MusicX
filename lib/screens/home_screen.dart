import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/permission_service.dart';
import '../widgets/song_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildSongsTab(),
                    _buildAlbumsTab(),
                    _buildArtistsTab(),
                    _buildPlaylistsTab(),
                  ],
                ),
              ),
              if (musicProvider.currentSong != null)
                MiniPlayer(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Songs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.album),
                label: 'Albums',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Artists',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text('Songs'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Implement search
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    // Check permissions and reload songs
                    final hasPermissions = await PermissionService.hasAllEssentialPermissions();
                    if (hasPermissions) {
                      musicProvider.loadSongs();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Storage permission required to load music'),
                          action: SnackBarAction(
                            label: 'Grant',
                            onPressed: null, // Will be handled by permission widget
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Implement menu
                  },
                ),
              ],
            ),
            if (musicProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (musicProvider.songs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No music found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SongList(songs: musicProvider.songs),
                  childCount: 1,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    return const Center(
      child: Text('Albums - Coming Soon'),
    );
  }

  Widget _buildArtistsTab() {
    return const Center(
      child: Text('Artists - Coming Soon'),
    );
  }

  Widget _buildPlaylistsTab() {
    return const Center(
      child: Text('Playlists - Coming Soon'),
    );
  }
}