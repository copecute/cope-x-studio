import 'dart:typed_data';

import 'package:cope_x_studio/services/thumbnail_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Thumbnail 40x40 cho ảnh / video / APK trong danh sách file.
class FileThumbnail extends StatefulWidget {
  const FileThumbnail({
    super.key,
    required this.path,
    required this.isDirectory,
    this.size = 40,
  });

  final String path;
  final bool isDirectory;
  final double size;

  @override
  State<FileThumbnail> createState() => _FileThumbnailState();
}

class _FileThumbnailState extends State<FileThumbnail> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FileThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.isDirectory || !FileTypeUtils.hasThumbnail(widget.path)) return;

    setState(() => _loading = true);
    final bytes = await ThumbnailService.instance.load(widget.path);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(widget.path);

    if (widget.isDirectory) {
      return _iconBox(Icons.folder, const Color(0xFFDCA458));
    }

    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(name),
        ),
      );
    }

    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _fallbackIcon(name);
  }

  Widget _fallbackIcon(String name) {
    return _iconBox(_fileIcon(name), _iconColor(name));
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: VsCodeColors.tabBar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: widget.size * 0.55, color: color),
    );
  }

  IconData _fileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.dart' => Icons.flutter_dash,
      '.docx' => Icons.description_outlined,
      '.xlsx' => Icons.table_chart_outlined,
      '.pptx' => Icons.slideshow_outlined,
      '.txt' => Icons.text_snippet_outlined,
      '.zip' || '.jar' || '.apks' => Icons.folder_zip_outlined,
      '.apk' || '.xapk' => Icons.android,
      '.mp3' || '.wav' || '.flac' || '.aac' => Icons.audiotrack,
      '.mp4' || '.mkv' || '.avi' => Icons.videocam_outlined,
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Color _iconColor(String name) {
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.dart' => const Color(0xFF42A5F5),
      '.docx' => const Color(0xFF2B579A),
      '.xlsx' => const Color(0xFF217346),
      '.pptx' => const Color(0xFFD24726),
      '.apk' || '.xapk' => const Color(0xFF3DDC84),
      '.zip' => const Color(0xFFE8B84A),
      _ => VsCodeColors.foregroundDim,
    };
  }
}
