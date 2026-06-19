import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/qr_image_utils.dart';

typedef WebServerStopCallback = Future<void> Function();

/// Thông báo ongoing khi Web Server đang chạy (QR + nút dừng).
class WebServerNotificationService {
  WebServerNotificationService._();
  static final WebServerNotificationService instance = WebServerNotificationService._();

  static const _channelId = 'web_server';
  static const _channelName = 'Web Server';
  static const _notificationId = 2910;
  static const _stopActionId = 'stop_web_server';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  WebServerStopCallback? _onStop;

  Future<void> init({required WebServerStopCallback onStop}) async {
    if (_initialized) {
      _onStop = onStop;
      return;
    }
    _onStop = onStop;

    const androidInit = AndroidInitializationSettings('logo_notification');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundResponse,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Thông báo khi Web Server đang chạy',
          importance: Importance.low,
        ),
      );
    }

    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundResponse(NotificationResponse response) {
    if (response.actionId == _stopActionId) {
      instance._onStop?.call();
    }
  }

  void _handleResponse(NotificationResponse response) {
    if (response.actionId == _stopActionId) {
      _onStop?.call();
    }
  }

  Future<void> requestPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await Permission.notification.request();
  }

  AndroidNotificationDetails _buildAndroidDetails(String url) {
    final qrBytes = QrImageUtils.generateNotificationPng(url);
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Thông báo khi Web Server đang chạy',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: 'logo_notification',
      additionalFlags: Int32List.fromList([2, 32]),
      styleInformation: BigPictureStyleInformation(
        ByteArrayAndroidBitmap(qrBytes),
        contentTitle: 'Web Server đang chạy',
        summaryText: url,
        hideExpandedLargeIcon: true,
      ),
      // actions: const [
      //   AndroidNotificationAction(
      //     _stopActionId,
      //     'Dừng server',
      //     showsUserInterface: false,
      //     cancelNotification: false,
      //   ),
      // ],
    );
  }

  Future<void> showRunning({required String url}) async {
    if (!_initialized) return;
    await requestPermissionIfNeeded();

    final androidDetails = _buildAndroidDetails(url);

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.startForegroundService(
        _notificationId,
        'Web Server đang chạy',
        url,
        notificationDetails: androidDetails,
        foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeDataSync},
      );
      return;
    }

    await _plugin.show(
      _notificationId,
      'Web Server đang chạy',
      url,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancel() async {
    if (!_initialized) return;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.stopForegroundService();
    }
    await _plugin.cancel(_notificationId);
  }
}
