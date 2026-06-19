class AppPathUtils {
  AppPathUtils._();

  static const systemListPath = '@apps/system';
  static const userListPath = '@apps/user';
  static const pkgPrefix = '@apps/pkg/';

  static bool isAppsRoot(String path) => path == '@apps';

  static bool isAppsList(String path) => path == systemListPath || path == userListPath;

  static bool isAppPackage(String path) {
    if (path.startsWith(pkgPrefix)) return true;
    return !path.startsWith('/') &&
        !path.startsWith('@') &&
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$').hasMatch(path);
  }

  static String? packageFromPath(String path) {
    if (path.startsWith(pkgPrefix)) {
      return path.substring(pkgPrefix.length);
    }
    if (!path.startsWith('/') &&
        !path.startsWith('@') &&
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$').hasMatch(path)) {
      return path;
    }
    return null;
  }

  static String packagePath(String packageName) => '$pkgPrefix$packageName';

  static bool isSystemList(String path) => path == systemListPath;
}
