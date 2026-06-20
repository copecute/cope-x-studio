import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run welcome flow has been completed.
class OnboardingProvider extends ChangeNotifier {
  static const String storageKey = 'onboarding_completed';

  bool _completed = false;
  bool _initialized = false;
  int _initialPage = 0;

  bool get completed => _completed;
  bool get isInitialized => _initialized;

  /// When storage access is revoked, reopen welcome at the permissions step.
  int get initialPage => _initialPage;

  bool get permissionsOnly => _initialPage > 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(storageKey) ?? false;
    _initialized = true;
    notifyListeners();
  }

  /// Show welcome again (permissions page) after all-files access was revoked.
  Future<void> reopenForPermissions() async {
    if (!_completed && permissionsOnly) return;
    _completed = false;
    _initialPage = 1;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, false);
  }

  Future<void> complete() async {
    if (_completed) return;
    _completed = true;
    _initialPage = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, true);
  }
}
