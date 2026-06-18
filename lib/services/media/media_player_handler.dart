import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

/// Background audio handler that wraps audioplayers and publishes
/// MediaItem + PlaybackState to the Android MediaStyle notification.
///
/// Audio files are loaded as a queue; navigation (prev/next) works
/// both from the in-app UI and the system notification/lockscreen.
///
/// Video files don't play through this handler — they use VideoPlayerController
/// directly. The handler still receives video metadata so the notification
/// can display the video title.
class MediaPlayerHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  // ── Internal audio player ─────────────────────────────────
  final ap.AudioPlayer _player = ap.AudioPlayer();

  // ── Queue state ───────────────────────────────────────────
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;

  // ── Cached state ──────────────────────────────────────────
  ap.PlayerState _playerState = ap.PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ── Video sync mode ───────────────────────────────────────
  /// true = audio mode (handler plays audio)
  /// false = video mode (handler only holds metadata, no audio)
  bool _isVideoMode = false;

  // ═══════════════════════════════════════════════════════════
  //  Constructor
  // ═══════════════════════════════════════════════════════════

  MediaPlayerHandler() {
    // Wire audioplayers events → handler streams
    _player.onPositionChanged.listen(_onPositionChanged);
    _player.onDurationChanged.listen(_onDurationChanged);
    _player.onPlayerStateChanged.listen(_onPlayerStateChanged);
    _player.onPlayerComplete.listen((_) async {
      if (_currentIndex < _queue.length - 1) {
        await skipToNext();
      } else {
        _playerState = ap.PlayerState.stopped;
        _pushPlaybackState();
      }
    });

    // Push initial idle state so the handler is ready
    _pushPlaybackState();
  }

  // ═══════════════════════════════════════════════════════════
  //  Public API for MediaViewerView
  // ═══════════════════════════════════════════════════════════

  /// Load a list of audio [items] and start playing at [initialIndex].
  ///
  /// [items] must have `extras['localPath']` set to the local file path.
  Future<void> loadAudioQueue({
    required List<MediaItem> items,
    int initialIndex = 0,
  }) async {
    _isVideoMode = false;
    _queue
      ..clear()
      ..addAll(items);
    queue.add(List.unmodifiable(_queue));
    _currentIndex = initialIndex.clamp(0, _queue.isEmpty ? 0 : _queue.length - 1);
    await _playCurrentItem();
  }

  /// Switch to video mode: stop audio playback and publish video metadata
  /// to the notification (title, duration). Actual video plays externally.
  Future<void> setVideoMode({
    required String filePath,
    required String title,
    Duration? duration,
  }) async {
    _isVideoMode = true;
    // Stop any playing audio
    await _player.stop();
    _playerState = ap.PlayerState.stopped;
    _queue.clear();
    queue.add(const []);

    final item = MediaItem(
      id: filePath,
      title: title,
      duration: duration,
    );
    mediaItem.add(item);
    _duration = duration ?? Duration.zero;
    _position = Duration.zero;
    _pushPlaybackState(overridePlaying: false);
  }

  /// Sync video playback state to the notification (called from VideoPlayerController listener).
  void syncVideoPlayback({required bool isPlaying, required Duration position}) {
    if (!_isVideoMode) return;
    _position = position;
    _pushPlaybackState(overridePlaying: isPlaying);
  }

  /// Stop all playback and clear state.
  Future<void> stopAll() async {
    _isVideoMode = false;
    _queue.clear();
    queue.add(const []);
    mediaItem.add(null);
    await _player.stop();
    _playerState = ap.PlayerState.stopped;
    _position = Duration.zero;
    _duration = Duration.zero;
    _pushPlaybackState();
  }

  // ═══════════════════════════════════════════════════════════
  //  BaseAudioHandler overrides
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> play() async {
    if (_isVideoMode) return; // Video plays externally
    if (_queue.isEmpty) return;
    if (_playerState == ap.PlayerState.stopped ||
        _playerState == ap.PlayerState.completed) {
      await _playCurrentItem();
    } else {
      await _player.resume();
    }
  }

  @override
  Future<void> pause() async {
    if (_isVideoMode) return;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isVideoMode) return;
    _position = position;
    await _player.seek(position);
    _pushPlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    if (_isVideoMode) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _playCurrentItem();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isVideoMode) return;
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentItem();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (_isVideoMode) return;
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrentItem();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stopAll();
    await super.onTaskRemoved();
  }

  // ═══════════════════════════════════════════════════════════
  //  Getters for the view
  // ═══════════════════════════════════════════════════════════

  int get currentQueueIndex => _currentIndex;
  bool get isVideoMode => _isVideoMode;

  // ═══════════════════════════════════════════════════════════
  //  Private helpers
  // ═══════════════════════════════════════════════════════════

  Future<void> _playCurrentItem() async {
    if (_queue.isEmpty) return;
    final item = _queue[_currentIndex];
    mediaItem.add(item);
    final localPath = item.extras?['localPath'] as String?;
    if (localPath == null || localPath.isEmpty) return;
    _position = Duration.zero;
    _duration = item.duration ?? Duration.zero;
    await _player.play(ap.DeviceFileSource(localPath));
  }

  void _onPositionChanged(Duration pos) {
    _position = pos;
    _pushPlaybackState();
  }

  void _onDurationChanged(Duration dur) {
    _duration = dur;
    if (_currentIndex < _queue.length) {
      final old = _queue[_currentIndex];
      final updated = old.copyWith(duration: dur);
      _queue[_currentIndex] = updated;
      queue.add(List.unmodifiable(_queue));
      mediaItem.add(updated);
    }
  }

  void _onPlayerStateChanged(ap.PlayerState state) {
    _playerState = state;
    _pushPlaybackState();
  }

  /// Push current playback state to the notification stream.
  void _pushPlaybackState({bool? overridePlaying}) {
    final playing = overridePlaying ?? (_playerState == ap.PlayerState.playing);
    final hasPrev = !_isVideoMode && _currentIndex > 0;
    final hasNext = !_isVideoMode && _currentIndex < _queue.length - 1;

    final controls = <MediaControl>[
      if (hasPrev) MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      if (hasNext) MediaControl.skipToNext,
    ];

    // Build compact action indices for notification collapsed view (max 3)
    int idx = 0;
    final compact = <int>[];
    if (hasPrev) compact.add(idx++);
    compact.add(idx++); // play/pause always shown
    if (hasNext) compact.add(idx);

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: compact,
      processingState: switch (_playerState) {
        ap.PlayerState.playing || ap.PlayerState.paused => AudioProcessingState.ready,
        ap.PlayerState.completed => AudioProcessingState.completed,
        _ => AudioProcessingState.idle,
      },
      playing: playing,
      updatePosition: _position,
      bufferedPosition: _duration,
      speed: 1.0,
    ));
  }
}
