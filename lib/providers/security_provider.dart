import 'package:cope_x_studio/services/security_service.dart';
import 'package:flutter/foundation.dart';

class SecurityProvider extends ChangeNotifier {
  SecurityProvider({SecurityService? securityService})
      : _security = securityService ?? SecurityService();

  final SecurityService _security;

  bool _initialized = false;
  bool _isLocked = false;
  bool _hasPassword = false;
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;

  bool get initialized => _initialized;
  bool get isLocked => _isLocked;
  bool get hasPassword => _hasPassword;
  bool get isLockEnabled => _lockEnabled;
  bool get isBiometricEnabled => _biometricEnabled;
  bool get canUseBiometric => _canUseBiometric;

  SecurityService get securityService => _security;

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
  }

  void lock() {
    if (!_lockEnabled || !_hasPassword) return;
    _isLocked = true;
    notifyListeners();
  }

  Future<bool> unlockWithPassword(String password) async {
    if (await _security.verifyPassword(password)) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> unlockWithBiometric() async {
    if (!_biometricEnabled || !_canUseBiometric) return false;
    final ok = await _security.authenticateBiometric();
    if (ok) {
      _isLocked = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> setPassword(String password) async {
    await _security.setPassword(password);
    await _refreshState();
    _isLocked = false;
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

  void onAppResumed() {
    lock();
  }
}
