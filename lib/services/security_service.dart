import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    bool inMemory = false,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _useMemory = inMemory;

  static const _keyPasswordHash = 'app_password_hash';
  static const _keySalt = 'app_password_salt';
  static const _keyLockEnabled = 'app_lock_enabled';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyWebServerPasswordHash = 'web_server_password_hash';
  static const _keyWebServerPasswordSalt = 'web_server_password_salt';
  static const _keyWebServerUseAppPassword = 'web_server_use_app_password';
  static const _keyWebServerSharedRoot = 'web_server_shared_root';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final Map<String, String> _memory = {};
  bool _useMemory;

  Future<void> init() async {
    await _read(_keyLockEnabled);
  }

  Future<bool> get hasPassword async => (await _read(_keyPasswordHash)) != null;

  Future<bool> get isLockEnabled async => (await _read(_keyLockEnabled)) == 'true';

  Future<bool> get isBiometricEnabled async =>
      (await _read(_keyBiometricEnabled)) == 'true';

  Future<bool> get hasWebServerPassword async =>
      (await _read(_keyWebServerPasswordHash)) != null;

  Future<bool> get webServerUseAppPassword async {
    final saved = await _read(_keyWebServerUseAppPassword);
    if (saved != null) return saved == 'true';
    return await isLockEnabled && await hasPassword;
  }

  Future<String?> get webServerSharedRoot async => await _read(_keyWebServerSharedRoot);

  Future<bool> verifyWebServerPassword(String password) async {
    final hash = await _read(_keyWebServerPasswordHash);
    if (hash == null) return false;
    final salt = await _read(_keyWebServerPasswordSalt);
    if (salt == null) return false;
    return _hashPassword(password, salt) == hash;
  }

  Future<void> setWebServerPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }
    final salt = _randomSalt();
    await _write(_keyWebServerPasswordSalt, salt);
    await _write(_keyWebServerPasswordHash, _hashPassword(password, salt));
    await _write(_keyWebServerUseAppPassword, 'false');
  }

  Future<void> updateWebServerPassword(String newPassword) async {
    if (newPassword.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }
    if (!await hasWebServerPassword) {
      throw StateError('Chưa có mật khẩu Web Server');
    }
    final salt = _randomSalt();
    await _write(_keyWebServerPasswordSalt, salt);
    await _write(_keyWebServerPasswordHash, _hashPassword(newPassword, salt));
  }

  Future<void> clearWebServerPassword() async {
    await _delete(_keyWebServerPasswordHash);
    await _delete(_keyWebServerPasswordSalt);
  }

  Future<void> setWebServerUseAppPassword(bool useApp) async {
    await _write(_keyWebServerUseAppPassword, useApp ? 'true' : 'false');
    if (useApp) {
      await clearWebServerPassword();
    }
  }

  Future<void> setWebServerSharedRoot(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _delete(_keyWebServerSharedRoot);
    } else {
      await _write(_keyWebServerSharedRoot, path.trim());
    }
  }

  Future<bool> canUseBiometric() async {
    if (kIsWeb || _useMemory) return false;
    try {
      final supported = await _localAuth
          .isDeviceSupported()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!supported) return false;
      return await _localAuth
          .canCheckBiometrics
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    final hash = await _read(_keyPasswordHash);
    if (hash == null) return true;
    final salt = await _read(_keySalt);
    if (salt == null) return false;
    return _hashPassword(password, salt) == hash;
  }

  Future<void> setPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }
    final salt = _randomSalt();
    await _write(_keySalt, salt);
    await _write(_keyPasswordHash, _hashPassword(password, salt));
    await _write(_keyLockEnabled, 'true');
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.isEmpty) {
      throw ArgumentError('Mật khẩu không được để trống');
    }
    if (!await hasPassword) {
      throw StateError('Chưa có mật khẩu');
    }
    final salt = _randomSalt();
    await _write(_keySalt, salt);
    await _write(_keyPasswordHash, _hashPassword(newPassword, salt));
  }

  Future<void> setLockEnabled(bool enabled) async {
    if (enabled) {
      if (!await hasPassword) {
        throw StateError('Cần đặt mật khẩu trước');
      }
      await _write(_keyLockEnabled, 'true');
    } else {
      await _write(_keyLockEnabled, 'false');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (!await verifyPassword(currentPassword)) {
      throw StateError('Mật khẩu hiện tại không đúng');
    }
    await setPassword(newPassword);
  }

  Future<void> removePassword(String currentPassword) async {
    if (!await verifyPassword(currentPassword)) {
      throw StateError('Mật khẩu không đúng');
    }
    await _delete(_keyPasswordHash);
    await _delete(_keySalt);
    await _delete(_keyLockEnabled);
    await _delete(_keyBiometricEnabled);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && !await canUseBiometric()) {
      throw StateError('Thiết bị không hỗ trợ sinh trắc học');
    }
    if (enabled && !await hasPassword) {
      throw StateError('Cần đặt mật khẩu trước');
    }
    await _write(_keyBiometricEnabled, enabled ? 'true' : 'false');
  }

  Future<bool> authenticateBiometric({String reason = 'Mở khóa Cope X Studio'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  String _randomSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  Future<String?> _read(String key) async {
    if (_useMemory) return _memory[key];
    try {
      return await _storage.read(key: key);
    } catch (_) {
      _useMemory = true;
      return _memory[key];
    }
  }

  Future<void> _write(String key, String value) async {
    if (_useMemory) {
      _memory[key] = value;
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _useMemory = true;
      _memory[key] = value;
    }
  }

  Future<void> _delete(String key) async {
    if (_useMemory) {
      _memory.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _useMemory = true;
      _memory.remove(key);
    }
  }
}
