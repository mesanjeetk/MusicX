import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';

class MusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late AudioPlayer _player;
  final BehaviorSubject<List<Song>> _playlist = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndex = BehaviorSubject.seeded(0);
  
  MusicAudioHandler() {
    _init();
  }
  
  Future<void> _init() async {
    _player = AudioPlayer();
    
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;
      
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.stop],
          systemActions: const {MediaAction.stop},
          processingState: AudioProcessingState.loading,
        ));
      } else if (playing != true) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: AudioProcessingState.ready,
        ));
      } else if (processingState != ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: AudioProcessingState.ready,
        ));
      } else {
        // Song completed, skip to next
        if (_currentIndex.value < _playlist.value.length - 1) {
          skipToNext();
        }
      }
    });
    
    // Listen to position changes
    _player.positionStream.listen((position) {
      final duration = _player.duration;
      if (duration != null) {
        playbackState.add(playbackState.value.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _currentIndex.value,
        ));
      }
    });
    
    // Listen to current song changes
    _currentIndex.stream.listen((index) {
      if (index < _playlist.value.length) {
        final song = _playlist.value[index];
        mediaItem.add(MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          duration: song.duration,
          artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
        ));
      }
    });
  }
  
  // Playlist management
  Future<void> updatePlaylist(List<Song> songs) async {
    _playlist.add(songs);
    queue.add(songs.map((song) => MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
    )).toList());
  }
  
  Future<void> playFromIndex(int index) async {
    if (index >= 0 && index < _playlist.value.length) {
      _currentIndex.add(index);
      final song = _playlist.value[index];
      await _player.setFilePath(song.path);
      await play();
    }
  }
  
  @override
  Future<void> play() async {
    await _player.play();
  }
  
  @override
  Future<void> pause() async {
    await _player.pause();
  }
  
  @override
  Future<void> stop() async {
    await _player.stop();
  }
  
  @override
  Future<void> skipToNext() async {
    final currentIndex = _currentIndex.value;
    if (currentIndex < _playlist.value.length - 1) {
      await playFromIndex(currentIndex + 1);
    }
  }
  
  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _currentIndex.value;
    if (currentIndex > 0) {
      await playFromIndex(currentIndex - 1);
    }
  }
  
  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  @override
  Future<void> skipToQueueItem(int index) async {
    await playFromIndex(index);
  }
  
  // Getters for streams
  Stream<List<Song>> get playlistStream => _playlist.stream;
  Stream<int> get currentIndexStream => _currentIndex.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  Song? get currentSong {
    final index = _currentIndex.value;
    if (index < _playlist.value.length) {
      return _playlist.value[index];
    }
    return null;
  }
  
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
  
  @override
  Future<void> onNotificationDeleted() async {
    await stop();
  }
}