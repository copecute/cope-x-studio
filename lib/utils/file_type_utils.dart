import 'package:path/path.dart' as p;

class FileTypeUtils {
  static const _imageExts = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif',
  };

  static const _videoExts = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.3gp', '.m4v',
  };

  static const _audioExts = {
    '.mp3', '.wav', '.ogg', '.flac', '.m4a', '.aac', '.wma', '.opus',
  };

  static const _editableExts = {
    '.txt', '.dart', '.js', '.ts', '.jsx', '.tsx', '.json', '.py', '.java',
    '.go', '.php', '.sql', '.md', '.yaml', '.yml', '.xml', '.html', '.htm',
    '.css', '.sh', '.rs', '.c', '.h', '.cpp', '.hpp', '.cs', '.swift', '.kt',
  };

  // ZIP-like: can be browsed inline via the archive package
  static const _zipExts = {'.zip', '.jar', '.apks', '.xapk'};

  // Archves extracted via shell (tar) — cannot be browsed inline
  static const _tarExts = {'.tar', '.gz', '.tgz', '.bz2', '.xz', '.lz', '.lzma', '.zst'};

  // Formats we detect but cannot extract natively (show friendly error)
  static const _rarExts = {'.rar', '.r00', '.r01'};
  static const _sevenZipExts = {'.7z'};

  static bool isImage(String path) =>
      _imageExts.contains(p.extension(path).toLowerCase());

  static bool isVideo(String path) =>
      _videoExts.contains(p.extension(path).toLowerCase());

  static bool isAudio(String path) =>
      _audioExts.contains(p.extension(path).toLowerCase());

  static bool isPreviewableMedia(String path) =>
      isImage(path) || isVideo(path) || isAudio(path);

  static bool isApk(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.apk' || ext == '.xapk';
  }

  /// True for ZIP-like archives that can be browsed/extracted in-app
  static bool isZip(String path) =>
      _zipExts.contains(p.extension(path).toLowerCase());

  /// True for TAR-family archives extracted via shell
  static bool isTar(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.tar.gz') || lower.endsWith('.tar.bz2') ||
        lower.endsWith('.tar.xz') || lower.endsWith('.tar.zst') ||
        lower.endsWith('.tar.lz')) {
      return true;
    }
    return _tarExts.contains(p.extension(lower));
  }

  /// True for RAR archives (extraction not supported natively)
  static bool isRar(String path) =>
      _rarExts.contains(p.extension(path).toLowerCase());

  /// True for 7-Zip archives (extraction not supported natively)
  static bool is7z(String path) =>
      _sevenZipExts.contains(p.extension(path).toLowerCase());

  /// True for any recognized archive format
  static bool isArchive(String path) =>
      isZip(path) || isTar(path) || isRar(path) || is7z(path);

  /// Human-readable format name
  static String archiveFormatName(String path) {
    if (isZip(path)) return 'ZIP';
    if (isTar(path)) return 'TAR';
    if (isRar(path)) return 'RAR';
    if (is7z(path)) return '7-Zip';
    return 'Archive';
  }

  /// True if the format supports password protection that we can handle
  static bool isPasswordable(String path) => isZip(path);

  static bool isPdf(String path) =>
      p.extension(path).toLowerCase() == '.pdf';

  static bool hasThumbnail(String path) =>
      isImage(path) || isVideo(path) || isApk(path) || isPdf(path);

  static bool isEditableInApp(String path) =>
      _editableExts.contains(p.extension(path).toLowerCase());
}

