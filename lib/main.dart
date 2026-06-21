import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cope_x_studio/app.dart';
import 'package:cope_x_studio/providers/locale_provider.dart';
import 'package:cope_x_studio/providers/onboarding_provider.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/web_server/web_server_notification_service.dart';
import 'package:cope_x_studio/services/media/media_player_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen áp dụng sau khi WorkspaceProvider load cài đặt.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E1E1E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialise audio_service — must happen before runApp.
  // Returns a MediaPlayerHandler instance that lives as a foreground service.
  final audioHandler = await AudioService.init<MediaPlayerHandler>(
    builder: () => MediaPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.cope_x_studio.media',
      androidNotificationChannelName: 'Cope X Studio',
      androidNotificationIcon: 'drawable/logo_notification',
      androidShowNotificationBadge: false,
      // Stop foreground service (dismiss notification) when paused
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF007ACC),
    ),
  );

  final workspace = WorkspaceProvider(mediaPlayerHandler: audioHandler);
  final security = SecurityProvider();
  final localeProvider = LocaleProvider();
  final onboardingProvider = OnboardingProvider();
  workspace.attachSecurity(security);
  workspace.attachLocale(localeProvider);
  workspace.attachOnboarding(onboardingProvider);

  await Future.wait([
    localeProvider.init(),
    onboardingProvider.init(),
  ]);

  await WebServerNotificationService.instance.init(
    onStop: workspace.stopWebServer,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: workspace),
        ChangeNotifierProvider.value(value: security),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: onboardingProvider),
        // Expose handler as a singleton — MediaViewerView reads it via context.read
        Provider<MediaPlayerHandler>.value(value: audioHandler),
      ],
      child: _BootstrapApp(workspace: workspace, security: security),
    ),
  );
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp({required this.workspace, required this.security});

  final WorkspaceProvider workspace;
  final SecurityProvider security;

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.workspace.initPermissions();
    widget.security.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      widget.security.onAppPaused();
      unawaited(widget.workspace.saveSessionState());
    } else if (state == AppLifecycleState.resumed) {
      widget.workspace.recheckPermissions();
      widget.workspace.syncWebServerState();
      widget.security.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CopeXStudioApp();
  }
}
