import 'package:cope_x_studio/providers/security_provider.dart';
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
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: Text('Đang tải...', style: TextStyle(color: Colors.white70))),
      );
    }

    if (security.isLocked) {
      return const LockScreen();
    }

    return child;
  }
}
