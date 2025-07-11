import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/permission_service.dart';
import '../services/playlist_service.dart';
import '../widgets/song_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/player_screen.dart';
import '../services/music_service.dart';
import "../models/song.dart";

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
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showAppMenu(context);
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
        
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              snap: true,
              title: Text('Albums'),
            ),
            if (albumGroups.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No albums found'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final albumName = albumGroups.keys.elementAt(index);
                    final albumSongs = albumGroups[albumName]!;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          _showAlbumSongs(context, albumName, albumSongs);
                        },
                      ),
                    );
                  },
                  childCount: albumGroups.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final artistGroups = MusicService.groupSongsByArtist(musicProvider.songs);
        
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              snap: true,
              title: Text('Artists'),
            ),
            if (artistGroups.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No artists found'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artistName = artistGroups.keys.elementAt(index);
                    final artistSongs = artistGroups[artistName]!;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          _showArtistSongs(context, artistName, artistSongs);
                        },
                      ),
                    );
                  },
                  childCount: artistGroups.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Playlists'),
          actions: [
            // Add playlist button can be added here
          ],
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            // Favorites playlist
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                title: const Text('Favorites'),
                subtitle: const Text('Your favorite songs'),
                onTap: () {
                  _showFavorites(context);
                },
              ),
            ),
            // Recently played
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue,
                  ),
                  child: const Icon(Icons.history, color: Colors.white),
                ),
                title: const Text('Recently Played'),
                subtitle: const Text('Your recent listening history'),
                onTap: () {
                  _showRecentlyPlayed(context);
                },
              ),
            ),
            // Most played
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green,
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white),
                ),
                title: const Text('Most Played'),
                subtitle: const Text('Your most played songs'),
                onTap: () {
                  _showMostPlayed(context);
                },
              ),
            ),
          ]),
        );
      ],
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

  void _showAppMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Music Player'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A powerful, lag-free music player with background playback and notification controls.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlbumSongs(BuildContext context, String albumName, List<Song> songs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(albumName),
            backgroundColor: Color(MusicService.generateColorForSong(albumName)),
            foregroundColor: Colors.white,
          ),
          body: SongList(songs: songs),
        ),
      ),
    );
  }

  void _showArtistSongs(BuildContext context, String artistName, List<Song> songs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(artistName),
            backgroundColor: Color(MusicService.generateColorForSong(artistName)),
            foregroundColor: Colors.white,
          ),
          body: SongList(songs: songs),
        ),
      ),
    );
  }

  void _showFavorites(BuildContext context) async {
    final favoriteIds = await PlaylistService.getFavoriteSongIds();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final favoriteSongs = musicProvider.songs
        .where((song) => favoriteIds.contains(song.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Favorites'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: favoriteSongs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No favorite songs yet'),
                    ],
                  ),
                )
              : SongList(songs: favoriteSongs),
        ),
      ),
    );
  }

  void _showRecentlyPlayed(BuildContext context) async {
    final recentIds = await PlaylistService.getRecentlyPlayedIds();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final recentSongs = recentIds
        .map((id) => musicProvider.songs.firstWhere(
              (song) => song.id == id,
              orElse: () => Song(
                id: '',
                title: '',
                artist: '',
                album: '',
                path: '',
                duration: 0,
              ),
            ))
        .where((song) => song.id.isNotEmpty)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Recently Played'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: recentSongs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No recently played songs'),
                    ],
                  ),
                )
              : SongList(songs: recentSongs),
        ),
      ),
    );
  }

  void _showMostPlayed(BuildContext context) async {
    final mostPlayedIds = await PlaylistService.getMostPlayedIds();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final mostPlayedSongs = mostPlayedIds
        .map((id) => musicProvider.songs.firstWhere(
              (song) => song.id == id,
              orElse: () => Song(
                id: '',
                title: '',
                artist: '',
                album: '',
                path: '',
                duration: 0,
              ),
            ))
        .where((song) => song.id.isNotEmpty)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Most Played'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: mostPlayedSongs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No most played songs yet'),
                    ],
                  ),
                )
              : SongList(songs: mostPlayedSongs),
        ),
      ),
    );
  }
}