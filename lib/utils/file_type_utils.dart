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

  static const _zipExts = {'.zip', '.jar', '.apks', '.xapk'};

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

  static bool isZip(String path) =>
      _zipExts.contains(p.extension(path).toLowerCase());

  static bool hasThumbnail(String path) =>
      isImage(path) || isVideo(path) || isApk(path);

  static bool isEditableInApp(String path) =>
      _editableExts.contains(p.extension(path).toLowerCase());
}
