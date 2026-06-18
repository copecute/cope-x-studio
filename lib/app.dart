import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/security/lock_gate.dart';
import 'package:cope_x_studio/widgets/shell/app_shell.dart';
import 'package:flutter/material.dart';

class CopeXStudioApp extends StatelessWidget {
  const CopeXStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cope X Studio',
      debugShowCheckedModeBanner: false,
      theme: buildVsCodeTheme(),
      home: const LockGate(child: AppShell()),
    );
  }
}
