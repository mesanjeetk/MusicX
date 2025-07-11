import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../widgets/music_list.dart';
import '../widgets/player_controls.dart';
import '../widgets/search_bar.dart' as custom;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MusicProvider>(context, listen: false).loadMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MusicProvider>(context, listen: false).loadMusic();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const custom.SearchBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                MusicList(),
                ArtistList(),
                AlbumList(),
              ],
            ),
          ),
          const PlayerControls(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Artists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.album),
            label: 'Albums',
          ),
        ],
      ),
    );
  }
}

class ArtistList extends StatelessWidget {
  const ArtistList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final artists = provider.allArtists;
        
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            final songs = provider.getSongsByArtist(artist);
            
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(artist),
              subtitle: Text('${songs.length} songs'),
              onTap: () {
                // Navigate to artist detail screen
              },
            );
          },
        );
      },
    );
  }
}

class AlbumList extends StatelessWidget {
  const AlbumList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final albums = provider.allAlbums;
        
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.album),
              ),
              title: Text(album),
              onTap: () {
                // Navigate to album detail screen
              },
            );
          },
        );
      },
    );
  }
}