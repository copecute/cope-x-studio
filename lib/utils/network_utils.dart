/// Chọn địa chỉ LAN ưu tiên cho Web Server.
class NetworkUtils {
  NetworkUtils._();

  static String? pickPreferredAddress(List<String> addresses) {
    if (addresses.isEmpty) return null;

    String? fallback192;
    String? fallback10;
    String? fallback;

    for (final addr in addresses) {
      if (addr.startsWith('127.')) continue;
      if (addr.startsWith('192.168.')) return addr;
      if (addr.startsWith('192.') && fallback192 == null) fallback192 = addr;
      if (addr.startsWith('10.') && fallback10 == null) fallback10 = addr;
      fallback ??= addr;
    }

    return fallback192 ?? fallback10 ?? fallback ?? addresses.first;
  }

  static String? buildPreferredUrl(List<String> addresses, int port) {
    final addr = pickPreferredAddress(addresses);
    if (addr == null) return null;
    return 'http://$addr:$port';
  }
}
