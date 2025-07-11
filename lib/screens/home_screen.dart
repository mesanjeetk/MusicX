import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/permission_service.dart';
import '../widgets/song_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/player_screen.dart';
import '../services/music_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
                  onPressed: () => _showSearchDialog(),
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
                  (context, index) {
                    final songs = _searchQuery.isEmpty 
                        ? musicProvider.songs
                        : MusicService.searchSongs(musicProvider.songs, _searchQuery);
                    
                    return Column(
                      children: [
                        if (_searchQuery.isNotEmpty) _buildSearchHeader(songs.length),
                        SongList(songs: songs),
                      ],
                    );
                  },
                  childCount: 1,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final albumGroups = MusicService.groupSongsByAlbum(musicProvider.songs);
        
        return ListView.builder(
          itemCount: albumGroups.length,
          itemBuilder: (context, index) {
            final albumName = albumGroups.keys.elementAt(index);
            final albumSongs = albumGroups[albumName]!;
            
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(MusicService.generateColorForSong(albumName)),
                  ),
                  child: const Icon(Icons.album, color: Colors.white),
                ),
                title: Text(albumName),
                subtitle: Text('${albumSongs.length} songs'),
                onTap: () {
                  // TODO: Navigate to album detail
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final artistGroups = MusicService.groupSongsByArtist(musicProvider.songs);
        
        return ListView.builder(
          itemCount: artistGroups.length,
          itemBuilder: (context, index) {
            final artistName = artistGroups.keys.elementAt(index);
            final artistSongs = artistGroups[artistName]!;
            
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Color(MusicService.generateColorForSong(artistName)),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(artistName),
                subtitle: Text('${artistSongs.length} songs'),
                onTap: () {
                  // TODO: Navigate to artist detail
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return const Center(
      child: Text('Playlists - Coming Soon'),
    );
  }

  Widget _buildSearchHeader(int resultCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Found $resultCount songs for "$_searchQuery"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Music'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title, artist, or album...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}