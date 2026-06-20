import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/media/media_player_handler.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

// ═══════════════════════════════════════════════════════════════════
//  MediaViewerView
// ═══════════════════════════════════════════════════════════════════

class MediaViewerView extends StatefulWidget {
  const MediaViewerView({super.key, required this.tab});
  final EditorTab tab;

  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView>
    with WidgetsBindingObserver {
  late String _currentFilePath;
  String? _currentLocalPath;
  bool _loading = false;
  List<String> _siblings = [];
  bool _showPlaylist = false;

  // ── Video ──────────────────────────────────────────────────────
  VideoPlayerController? _videoController;

  // ── Audio state (fed by handler streams) ──────────────────────
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _audioIsPlaying = false;
  StreamSubscription<PlaybackState>? _playbackStateSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;

  // ══════════════════════════════════════════════════════════════
  //  Lifecycle
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentFilePath = widget.tab.filePath!;
    _currentLocalPath = widget.tab.localPath;
    _siblings = context.read<WorkspaceProvider>().getMediaFilesOfSameType(
          _currentFilePath,
          forcedMode: widget.tab.forcedMediaMode,
        );
    _initPlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAudioSubs();
    _disposeVideo();
    // ⚠️ Do NOT stop the handler here — audio continues in background.
    super.dispose();
  }

  /// App lifecycle: pause video when going to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    }
  }

  void _disposeVideo() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _videoController = null;
  }

  void _cancelAudioSubs() {
    _playbackStateSub?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub = null;
    _mediaItemSub = null;
  }

  // ══════════════════════════════════════════════════════════════
  //  Player init
  // ══════════════════════════════════════════════════════════════

  bool _treatAsImage() =>
      widget.tab.forcedMediaMode == MediaOpenMode.image ||
      (widget.tab.forcedMediaMode == null && FileTypeUtils.isImage(_currentFilePath));

  bool _treatAsVideo() =>
      widget.tab.forcedMediaMode == MediaOpenMode.video ||
      (widget.tab.forcedMediaMode == null && FileTypeUtils.isVideo(_currentFilePath));

  bool _treatAsAudio() =>
      widget.tab.forcedMediaMode == MediaOpenMode.audio ||
      (widget.tab.forcedMediaMode == null && FileTypeUtils.isAudio(_currentFilePath));

  Future<void> _initPlayer() async {
    _cancelAudioSubs();
    _disposeVideo();

    if (_currentLocalPath == null) return;
    final handler = context.read<MediaPlayerHandler>();

    if (_treatAsVideo()) {
      // ── Video ───────────────────────────────────────────────
      // Tell handler to show video metadata in notification
      await handler.setVideoMode(
        filePath: _currentFilePath,
        title: p.basenameWithoutExtension(_currentFilePath),
      );

      _videoController = VideoPlayerController.file(File(_currentLocalPath!));
      try {
        await _videoController!.initialize();
        if (!mounted) return;
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(false);
        _videoController!.addListener(_onVideoTick);

        // Update handler with real duration
        handler.setVideoMode(
          filePath: _currentFilePath,
          title: p.basenameWithoutExtension(_currentFilePath),
          duration: _videoController!.value.duration,
        );
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    } else if (_treatAsAudio()) {
      // ── Audio ───────────────────────────────────────────────
      final isFtp = _currentFilePath.startsWith('@ftp/');
      List<MediaItem> mediaItems;
      int startIndex = 0;

      if (isFtp) {
        // FTP: single item (already downloaded to _currentLocalPath)
        mediaItems = [_buildMediaItem(_currentFilePath, _currentLocalPath!)];
      } else {
        // Local: load full sibling queue → enables notification skip
        mediaItems =
            _siblings.map((path) => _buildMediaItem(path, path)).toList();
        startIndex =
            _siblings.indexOf(_currentFilePath).clamp(0, _siblings.length - 1);
      }

      await handler.loadAudioQueue(items: mediaItems, initialIndex: startIndex);
      _subscribeAudio(handler);
    }
  }

  /// Build a MediaItem from a local file path.
  MediaItem _buildMediaItem(String filePath, String localPath) {
    return MediaItem(
      id: filePath,
      title: p.basenameWithoutExtension(filePath),
      album: p.basename(p.dirname(filePath)),
      extras: {'localPath': localPath},
    );
  }

  /// Subscribe to handler streams to update audio UI state.
  void _subscribeAudio(MediaPlayerHandler handler) {
    _playbackStateSub = handler.playbackState.stream.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioIsPlaying = state.playing;
        _audioPosition = state.position; // computed from updatePosition + elapsed
      });
    });

    _mediaItemSub = handler.mediaItem.stream.listen((item) {
      if (!mounted || item == null) return;
      // Handler may switch tracks from notification — sync view state
      if (item.id != _currentFilePath) {
        setState(() {
          _currentFilePath = item.id;
          _currentLocalPath =
              item.extras?['localPath'] as String? ?? item.id;
        });
        _showTrackNotification(p.basename(item.id));
      }
      if (item.duration != null) {
        setState(() => _audioDuration = item.duration!);
      }
    });
  }

  void _onVideoTick() {
    if (!mounted) return;
    setState(() {});
    // Keep handler in sync for notification
    if (_videoController != null && _videoController!.value.isInitialized) {
      context.read<MediaPlayerHandler>().syncVideoPlayback(
            isPlaying: _videoController!.value.isPlaying,
            position: _videoController!.value.position,
          );
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Navigation
  // ══════════════════════════════════════════════════════════════

  int get _currentIndex =>
      _siblings.indexWhere((s) => s == _currentFilePath);
  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < _siblings.length - 1;

  void _playPrev() {
    if (_treatAsAudio() && !_currentFilePath.startsWith('@ftp/')) {
      context.read<MediaPlayerHandler>().skipToPrevious();
    } else {
      final idx = _currentIndex;
      if (idx > 0) _switchFile(_siblings[idx - 1]);
    }
  }

  void _playNext() {
    if (_treatAsAudio() && !_currentFilePath.startsWith('@ftp/')) {
      context.read<MediaPlayerHandler>().skipToNext();
    } else {
      final idx = _currentIndex;
      if (idx >= 0 && idx < _siblings.length - 1) _switchFile(_siblings[idx + 1]);
    }
  }

  Future<void> _switchFile(String path) async {
    if (path == _currentFilePath) return;
    setState(() => _loading = true);

    final provider = context.read<WorkspaceProvider>();
    String? localPath;
    if (path.startsWith('@ftp/')) {
      localPath = await provider.downloadFtpFileToTemp(path);
    } else {
      localPath = path;
    }

    if (!mounted) return;
    setState(() {
      _currentFilePath = path;
      _currentLocalPath = localPath;
      _loading = false;
    });
    _initPlayer();
    _showTrackNotification(p.basename(path));
  }

  // ══════════════════════════════════════════════════════════════
  //  Seek helpers
  // ══════════════════════════════════════════════════════════════

  Duration _clamp(Duration v, Duration mn, Duration mx) {
    if (v < mn) return mn;
    if (v > mx) return mx;
    return v;
  }

  void _seekVideo(Duration delta) {
    final ctrl = _videoController;
    if (ctrl == null) return;
    ctrl.seekTo(_clamp(
        ctrl.value.position + delta, Duration.zero, ctrl.value.duration));
  }

  void _seekAudio(Duration delta) {
    final target = _clamp(
        _audioPosition + delta, Duration.zero, _audioDuration);
    context.read<MediaPlayerHandler>().seek(target);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════
  //  In-app track notification
  // ══════════════════════════════════════════════════════════════

  void _showTrackNotification(String name) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _treatAsVideo()
                  ? Icons.videocam_rounded
                  : Icons.music_note_rounded,
              size: 15,
              color: VsCodeColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: TextStyle(color: VsCodeColors.foreground, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: VsCodeColors.sidebar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  Fullscreen
  // ══════════════════════════════════════════════════════════════

  Future<void> _openFullscreen() async {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    // Capture navigator & scaffoldMessenger before any await to avoid
    // use_build_context_synchronously warnings.
    final nav = Navigator.of(context, rootNavigator: true);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await nav.push(
      MaterialPageRoute(
        builder: (_) => _VideoFullscreenPage(
          controller: ctrl,
          formatDuration: _fmt,
        ),
      ),
    );

    // Restore portrait after exiting fullscreen
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Future.delayed(const Duration(milliseconds: 100));
    await SystemChrome.setPreferredOrientations([]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  // ══════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: VsCodeColors.editor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: _loading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: VsCodeColors.accent),
                              SizedBox(height: 16),
                              Text(l10n.loadingFile,
                                  style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 13)),
                            ],
                          )
                        : _buildPreview(),
                  ),
                ),
                // Playlist slide panel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _showPlaylist && _siblings.length > 1 ? 220 : 0,
                  child: _showPlaylist && _siblings.length > 1
                      ? _buildPlaylistPanel()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hasPlaylist = _siblings.length > 1;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: VsCodeColors.tabBar,
        border: Border(bottom: BorderSide(color: VsCodeColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Entire left area is tappable to toggle playlist
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasPlaylist
                    ? () => setState(() => _showPlaylist = !_showPlaylist)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      if (hasPlaylist) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _showPlaylist
                                ? VsCodeColors.accent.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 16,
                            color: _showPlaylist
                                ? VsCodeColors.accent
                                : VsCodeColors.foregroundDim,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          p.basename(_currentFilePath),
                          style: TextStyle(color: VsCodeColors.foreground, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasPlaylist)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VsCodeColors.foreground.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_siblings.length}',
                  style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Preview dispatch ────────────────────────────────────────────

  Widget _buildPreview() {
    final l10n = context.l10n;
    if (_currentLocalPath == null) {
      return Text(l10n.cannotLoadFile,
          style: TextStyle(color: VsCodeColors.foreground));
    }
    if (_treatAsImage()) {
      return InteractiveViewer(
        maxScale: 4.0,
        child: Image.file(File(_currentLocalPath!), fit: BoxFit.contain),
      );
    }
    if (_treatAsVideo()) return _buildVideoPlayer();
    if (_treatAsAudio()) return _buildAudioPlayer();
    return Text(l10n.formatNotSupported,
        style: TextStyle(color: VsCodeColors.foreground));
  }

  // ── Video player ────────────────────────────────────────────────

  Widget _buildVideoPlayer() {
    final l10n = context.l10n;
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return CircularProgressIndicator(color: VsCodeColors.accent);
    }

    final position = ctrl.value.position;
    final duration = ctrl.value.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                  aspectRatio: ctrl.value.aspectRatio,
                  child: VideoPlayer(ctrl)),
              Positioned(
                right: 8,
                bottom: 8,
                child: _overlayBtn(
                  icon: Icons.fullscreen_rounded,
                  tooltip: l10n.fullscreen,
                  onTap: _openFullscreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildProgressBar(
          progress: progress,
          position: position,
          duration: duration,
          onChanged: (val) => ctrl.seekTo(
              Duration(milliseconds: (val * duration.inMilliseconds).toInt())),
        ),
        _buildAVControls(
          isPlaying: ctrl.value.isPlaying,
          onPlayPause: () =>
              setState(() => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play()),
          onSeekBack: () => _seekVideo(const Duration(seconds: -10)),
          onSeekForward: () => _seekVideo(const Duration(seconds: 10)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Audio player ────────────────────────────────────────────────

  Widget _buildAudioPlayer() {
    final progress = _audioDuration.inMilliseconds > 0
        ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art placeholder
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                VsCodeColors.accent.withValues(alpha: 0.3),
                VsCodeColors.editor,
              ]),
              boxShadow: [
                BoxShadow(
                  color: VsCodeColors.accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(Icons.music_note_rounded,
                size: 64, color: VsCodeColors.accent),
          ),
          const SizedBox(height: 24),
          Text(
            p.basename(_currentFilePath),
            style: TextStyle(
                color: VsCodeColors.foreground,
                fontSize: 15,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          _buildProgressBar(
            progress: progress,
            position: _audioPosition,
            duration: _audioDuration,
            onChanged: (val) => context.read<MediaPlayerHandler>().seek(
                Duration(
                    milliseconds: (val * _audioDuration.inMilliseconds).toInt())),
          ),
          const SizedBox(height: 8),
          _buildAVControls(
            isPlaying: _audioIsPlaying,
            onPlayPause: () {
              final h = context.read<MediaPlayerHandler>();
              _audioIsPlaying ? h.pause() : h.play();
            },
            onSeekBack: () => _seekAudio(const Duration(seconds: -10)),
            onSeekForward: () => _seekAudio(const Duration(seconds: 10)),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────

  Widget _buildProgressBar({
    required double progress,
    required Duration position,
    required Duration duration,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: VsCodeColors.accent,
              inactiveTrackColor: VsCodeColors.border,
              thumbColor: VsCodeColors.foreground,
              overlayColor: VsCodeColors.accent.withValues(alpha: 0.2),
            ),
            child: Slider(value: progress, onChanged: onChanged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position),
                    style:
                        TextStyle(color: VsCodeColors.foregroundDim, fontSize: 11)),
                Text(_fmt(duration),
                    style:
                        TextStyle(color: VsCodeColors.foregroundDim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAVControls({
    required bool isPlaying,
    required VoidCallback onPlayPause,
    required VoidCallback onSeekBack,
    required VoidCallback onSeekForward,
  }) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlBtn(
            icon: Icons.skip_previous_rounded,
            size: 28,
            enabled: _hasPrev,
            onTap: _playPrev,
            tooltip: l10n.previous),
        const SizedBox(width: 4),
        _controlBtn(
            icon: Icons.replay_10_rounded,
            size: 28,
            onTap: onSeekBack,
            tooltip: l10n.rewind10s),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VsCodeColors.accent,
              boxShadow: [
                BoxShadow(
                  color: VsCodeColors.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _controlBtn(
            icon: Icons.forward_10_rounded,
            size: 28,
            onTap: onSeekForward,
            tooltip: l10n.forward10s),
        const SizedBox(width: 4),
        _controlBtn(
            icon: Icons.skip_next_rounded,
            size: 28,
            enabled: _hasNext,
            onTap: _playNext,
            tooltip: l10n.next),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required double size,
    VoidCallback? onTap,
    bool enabled = true,
    String? tooltip,
  }) {
    final btn = InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon,
            size: size,
            color: enabled ? VsCodeColors.foreground : VsCodeColors.foregroundDim.withValues(alpha: 0.4)),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  Widget _overlayBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  // ── Playlist panel ──────────────────────────────────────────────

  Widget _buildPlaylistPanel() {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: VsCodeColors.sidebar,
        border: Border(left: BorderSide(color: VsCodeColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: VsCodeColors.tabBar,
              border:
                  Border(bottom: BorderSide(color: VsCodeColors.border, width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.queue_music_rounded,
                    size: 14, color: VsCodeColors.foregroundDim),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.playlist,
                      style: TextStyle(
                          color: VsCodeColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => setState(() => _showPlaylist = false),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: VsCodeColors.foregroundDim),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _siblings.length,
              itemBuilder: (context, index) {
                final path = _siblings[index];
                return _buildPlaylistItem(
                    path: path, isActive: path == _currentFilePath);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
      {required String path, required bool isActive}) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => _switchFile(path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? VsCodeColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? VsCodeColors.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                  width: 40, height: 40, child: _buildThumb(path)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(path),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      height: 1.3,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: VsCodeColors.accent),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.nowPlaying,
                          style: TextStyle(
                              color: VsCodeColors.accent, fontSize: 9)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(String path) {
    if (FileTypeUtils.isImage(path) && !path.startsWith('@ftp/')) {
      return Image.file(File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _iconThumb(Icons.broken_image_rounded, VsCodeColors.foregroundDim));
    }
    if (FileTypeUtils.isImage(path)) {
      return _iconThumb(Icons.image_rounded, Colors.lightBlue.shade300);
    }
    if (FileTypeUtils.isVideo(path)) {
      return _iconThumb(Icons.videocam_rounded, Colors.purple.shade300);
    }
    if (FileTypeUtils.isAudio(path)) {
      return _iconThumb(Icons.music_note_rounded, VsCodeColors.accent);
    }
    return _iconThumb(Icons.insert_drive_file_rounded, VsCodeColors.foregroundDim);
  }

  Widget _iconThumb(IconData icon, Color color) {
    return Container(
      color: VsCodeColors.hover,
      child: Center(child: Icon(icon, size: 20, color: color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Fullscreen Video Page
// ═══════════════════════════════════════════════════════════════════

class _VideoFullscreenPage extends StatefulWidget {
  const _VideoFullscreenPage({
    required this.controller,
    required this.formatDuration,
  });

  final VideoPlayerController controller;
  final String Function(Duration) formatDuration;

  @override
  State<_VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<_VideoFullscreenPage> {
  bool _showControls = true;
  bool _isLandscape = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  Future<void> _toggleLandscape() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      setState(() => _isLandscape = false);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      setState(() => _isLandscape = true);
    }
    _resetHideTimer();
  }

  Future<void> _exitFullscreen() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _seek(Duration delta) {
    final ctrl = widget.controller;
    Duration target = ctrl.value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > ctrl.value.duration) target = ctrl.value.duration;
    ctrl.seekTo(target);
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctrl = widget.controller;
    final position = ctrl.value.position;
    final duration = ctrl.value.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: ctrl.value.aspectRatio,
                  child: VideoPlayer(ctrl),
                ),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // Top gradient + exit / rotate
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.fullscreen_exit_rounded,
                                        color: Colors.white,
                                        size: 26),
                                    tooltip: l10n.exitFullscreen,
                                    onPressed: _exitFullscreen,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      _isLandscape
                                          ? Icons.screen_lock_portrait_rounded
                                          : Icons.screen_lock_landscape_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    tooltip: _isLandscape ? l10n.rotatePortrait : l10n.rotateLandscape,
                                    onPressed: _toggleLandscape,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom gradient + controls
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress
                                  Row(
                                    children: [
                                      Text(widget.formatDuration(position),
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 11)),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 2,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 6),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                    overlayRadius: 12),
                                            activeTrackColor: VsCodeColors.accent,
                                            inactiveTrackColor: Colors.white30,
                                            thumbColor: Colors.white,
                                            overlayColor: VsCodeColors.accent
                                                .withValues(alpha: 0.3),
                                          ),
                                          child: Slider(
                                            value: progress,
                                            onChanged: (val) {
                                              ctrl.seekTo(Duration(
                                                  milliseconds: (val *
                                                          duration.inMilliseconds)
                                                      .toInt()));
                                              _resetHideTimer();
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(widget.formatDuration(duration),
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                  // Playback buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.replay_10_rounded,
                                            color: Colors.white, size: 28),
                                        tooltip: l10n.rewind10s,
                                        onPressed: () =>
                                            _seek(const Duration(seconds: -10)),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            ctrl.value.isPlaying
                                                ? ctrl.pause()
                                                : ctrl.play();
                                          });
                                          _resetHideTimer();
                                        },
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: VsCodeColors.accent,
                                            boxShadow: [
                                              BoxShadow(
                                                color: VsCodeColors.accent
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 14,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            ctrl.value.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.forward_10_rounded,
                                            color: Colors.white, size: 28),
                                        tooltip: l10n.forward10s,
                                        onPressed: () =>
                                            _seek(const Duration(seconds: 10)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
