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
    final workspace = context.watch<WorkspaceProvider>();

    return MaterialApp(
      title: 'Cope X Studio',
      debugShowCheckedModeBanner: false,
      themeMode: workspace.themeMode,
      theme: buildVsCodeTheme(Brightness.light),
      darkTheme: buildVsCodeTheme(Brightness.dark),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        VsCodeColors.bind(VsCodePalette.forBrightness(brightness));
        workspace.applySystemChromeForTheme(brightness);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(workspace.uiScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LockGate(child: AppShell()),
    );
  }
}
