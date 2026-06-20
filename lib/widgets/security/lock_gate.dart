import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/security/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockGate extends StatelessWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    if (!security.initialized) {
      return Scaffold(
        backgroundColor: VsCodeColors.editor,
        body: Center(
          child: Text('Đang tải...', style: TextStyle(color: VsCodeColors.foregroundDim)),
        ),
      );
    }

    if (security.isLocked) {
      return const LockScreen();
    }

    return child;
  }
}
