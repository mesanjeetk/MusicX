import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';

class MusicAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  
  // Streams
  final BehaviorSubject<List<Song>> _songsSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<Song?> _currentSongSubject = BehaviorSubject.seeded(null);
  
  // Getters
  Stream<List<Song>> get songs => _songsSubject.stream;
  Stream<Song?> get currentSong => _currentSongSubject.stream;
  Stream<Duration> get position => _player.positionStream;
  Stream<Duration?> get duration => _player.durationStream;
  Stream<PlayerState> get playerState => _player.playerStateStream;
  
  MusicAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    await _player.setAudioSource(_playlist);
    
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ));
    });

    // Listen to sequence state changes
    _player.sequenceStateStream.listen((sequenceState) {
      final currentItem = sequenceState?.currentSource;
      if (currentItem != null) {
        final index = _playlist.children.indexOf(currentItem);
        if (index != -1) {
          _currentSongSubject.add(_songsSubject.value[index]);
        }
      }
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems
        .map((item) => AudioSource.uri(Uri.parse(item.id)))
        .toList();
    
    await _playlist.addAll(audioSources);
    
    final songs = mediaItems.map((item) => Song(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      path: item.id,
      albumArt: item.artUri?.toString(),
      duration: item.duration?.inSeconds ?? 0,
    )).toList();
    
    _songsSubject.add(songs);
    
    // Update media items
    queue.add(mediaItems);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> onNotificationDeleted() async {
    await _player.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.stop();
  }

  // Custom methods
  Future<void> setSongs(List<Song> songs) async {
    await _playlist.clear();
    
    final mediaItems = songs.map((song) => MediaItem(
      id: song.path,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(seconds: song.duration),
      artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
    )).toList();
    
    await addQueueItems(mediaItems);
  }

  Future<void> playFromIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  void dispose() {
    await _player.dispose();
    _songsSubject.close();
    _currentSongSubject.close();
  }
}