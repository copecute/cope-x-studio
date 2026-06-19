import 'dart:convert';

class FtpServerConfig {
  FtpServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port = 21,
    this.username = 'anonymous',
    this.password = '',
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory FtpServerConfig.fromMap(Map<String, dynamic> map) {
    return FtpServerConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int? ?? 21,
      username: map['username'] as String? ?? 'anonymous',
      password: map['password'] as String? ?? '',
    );
  }

  FtpServerConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
  }) {
    return FtpServerConfig(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FtpServerConfig.fromJson(String source) =>
      FtpServerConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
