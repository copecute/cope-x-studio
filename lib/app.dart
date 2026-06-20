import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/security/lock_gate.dart';
import 'package:cope_x_studio/widgets/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CopeXStudioApp extends StatelessWidget {
  const CopeXStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final uiScale = context.watch<WorkspaceProvider>().uiScale;

    return MaterialApp(
      title: 'Cope X Studio',
      debugShowCheckedModeBanner: false,
      theme: buildVsCodeTheme(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(uiScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LockGate(child: AppShell()),
    );
  }
}
