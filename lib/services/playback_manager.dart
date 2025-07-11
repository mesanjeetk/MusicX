import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class PlaybackManager extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  List<FileSystemEntity> _songs = [];
  int _currentIndex = -1;

  FileSystemEntity? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _songs.length)
          ? _songs[_currentIndex]
          : null;

  bool get isPlaying => player.playing;

  Stream<bool> get playingStream => player.playingStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<Duration> get positionStream => player.positionStream;

  PlaybackManager() {
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongEnd();
      }
    });
  }

  void setPlaylist(List<FileSystemEntity> songs, int index) {
    _songs = songs;
    _currentIndex = index;
    _playCurrent();
  }
  String _cleanFileName(String path) {
    final name = path.split('/').last;
    return name.replaceAll(RegExp(r'\.(mp3|wav|m4a|ogg)$', caseSensitive: false), '');
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _songs.length) return;

    final file = _songs[_currentIndex];
    final path = file.path;

    await player.setAudioSource(
      AudioSource.uri(
        Uri.file(path),
        tag: MediaItem(
          id: path,
          title: _cleanFileName(path),
          artist: 'Unknown Artist',
          album: 'Local Files',
          artUri: Uri.parse(
            'https://via.placeholder.com/300x300.png?text=No+Artwork',
          ),
        ),
      ),
    );

    await player.play();
    notifyListeners();
  }

  void _handleSongEnd() {
    if (_songs.isEmpty) return;

    if (_currentIndex < _songs.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0; 
    }

    _playCurrent();
  }

  void togglePlayPause() {
    isPlaying ? player.pause() : player.play();
  }

  void seekTo(Duration position) {
    player.seek(position);
  }

  void playNext() {
    if (_songs.isEmpty) return;
    if (_currentIndex < _songs.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0;
    }
    _playCurrent();
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playCurrent();
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
