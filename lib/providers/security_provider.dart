import 'package:cope_x_studio/services/security_service.dart';
import 'package:flutter/material.dart';

class SecurityProvider extends ChangeNotifier {
  SecurityProvider({SecurityService? securityService})
      : _security = securityService ?? SecurityService();

  final SecurityService _security;

  static const _lockGracePeriod = Duration(minutes: 1);

  bool _initialized = false;
  bool _isLocked = false;
  bool _hasPassword = false;
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;
  bool _isAuthenticatingBiometric = false;
  bool _hasWebServerPassword = false;
  bool _webServerUseAppPassword = true;
  String? _webServerSharedRoot;
  DateTime? _pausedAt;

  bool get initialized => _initialized;
  bool get isLocked => _isLocked;
  bool get hasPassword => _hasPassword;
  bool get isLockEnabled => _lockEnabled;
  bool get isBiometricEnabled => _biometricEnabled;
  bool get canUseBiometric => _canUseBiometric;
  bool get hasWebServerPassword => _hasWebServerPassword;
  bool get webServerUseAppPassword => _webServerUseAppPassword;
  String? get webServerSharedRoot => _webServerSharedRoot;

  SecurityService get securityService => _security;

  bool get webServerUsesAppPasswordAuth =>
      _webServerUseAppPassword && _lockEnabled && _hasPassword;

  bool get webServerAuthRequired =>
      webServerUsesAppPasswordAuth || _hasWebServerPassword;

  Future<void> init() async {
    await _security.init();
    await _refreshState();
    if (_lockEnabled && _hasPassword) {
      _isLocked = true;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _refreshState() async {
    _hasPassword = await _security.hasPassword;
    _lockEnabled = await _security.isLockEnabled;
    _biometricEnabled = await _security.isBiometricEnabled;
    _canUseBiometric = await _security.canUseBiometric();
    _hasWebServerPassword = await _security.hasWebServerPassword;
    _webServerUseAppPassword = await _security.webServerUseAppPassword;
    _webServerSharedRoot = await _security.webServerSharedRoot;
  }

  void lock() {
    if (!_lockEnabled || !_hasPassword) return;
    _isLocked = true;
    notifyListeners();
  }

  Future<bool> unlockWithPassword(String password) async {
    if (await _security.verifyPassword(password)) {
      _isLocked = false;
      _pausedAt = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> unlockWithBiometric() async {
    if (!_biometricEnabled || !_canUseBiometric) return false;
    _isAuthenticatingBiometric = true;
    try {
      final ok = await _security.authenticateBiometric();
      if (ok) {
        _isLocked = false;
        _pausedAt = null;
        notifyListeners();
      }
      return ok;
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isAuthenticatingBiometric = false;
      });
    }
  }

  Future<void> setPassword(String password) async {
    await _security.setPassword(password);
    await _refreshState();
    _isLocked = false;
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    await _security.updatePassword(newPassword);
    await _refreshState();
    notifyListeners();
  }

  Future<void> setLockEnabled(bool enabled) async {
    await _security.setLockEnabled(enabled);
    await _refreshState();
    if (!enabled) _isLocked = false;
    notifyListeners();
  }

  Future<void> changePassword(String current, String newPassword) async {
    await _security.changePassword(current, newPassword);
    await _refreshState();
    notifyListeners();
  }

  Future<void> removePassword(String current) async {
    await _security.removePassword(current);
    await _refreshState();
    _isLocked = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _security.setBiometricEnabled(enabled);
    await _refreshState();
    notifyListeners();
  }

  Future<bool> verifyPassword(String password) => _security.verifyPassword(password);

  Future<bool> verifyWebServerPassword(String password) =>
      _security.verifyWebServerPassword(password);

  Future<void> setWebServerPassword(String password) async {
    await _security.setWebServerPassword(password);
    await _refreshState();
    notifyListeners();
  }

  Future<void> updateWebServerPassword(String password) async {
    await _security.updateWebServerPassword(password);
    await _refreshState();
    notifyListeners();
  }

  Future<void> clearWebServerPassword() async {
    await _security.clearWebServerPassword();
    await _refreshState();
    notifyListeners();
  }

  Future<void> setWebServerUseAppPassword(bool useApp) async {
    await _security.setWebServerUseAppPassword(useApp);
    await _refreshState();
    notifyListeners();
  }

  Future<void> setWebServerSharedRoot(String? path) async {
    await _security.setWebServerSharedRoot(path);
    await _refreshState();
    notifyListeners();
  }

  Future<Future<bool> Function(String password)?> buildWebServerVerifier() async {
    if (_webServerUseAppPassword && _lockEnabled && _hasPassword) {
      return verifyPassword;
    }
    if (_hasWebServerPassword) {
      return verifyWebServerPassword;
    }
    return null;
  }

  void onAppPaused() {
    _pausedAt = DateTime.now();
  }

  void onAppResumed() {
    if (_isAuthenticatingBiometric) return;
    if (_pausedAt == null) return;
    final elapsed = DateTime.now().difference(_pausedAt!);
    _pausedAt = null;
    if (elapsed >= _lockGracePeriod) {
      lock();
    }
  }
}
