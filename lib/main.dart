import 'package:cope_x_studio/app.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E1E1E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final workspace = WorkspaceProvider();
  final security = SecurityProvider();
  workspace.attachSecurity(security);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: workspace),
        ChangeNotifierProvider.value(value: security),
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
    if (state == AppLifecycleState.resumed) {
      widget.workspace.recheckPermissions();
      widget.security.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CopeXStudioApp();
  }
}
