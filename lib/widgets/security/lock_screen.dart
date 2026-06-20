import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final security = context.read<SecurityProvider>();
    if (security.isBiometricEnabled && security.canUseBiometric) {
      await security.unlockWithBiometric();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final security = context.read<SecurityProvider>();
    final ok = await security.unlockWithPassword(_controller.text);
    if (!ok && mounted) {
      setState(() {
        _error = context.l10n.wrongPasswordLock;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: VsCodeColors.editor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 72, color: VsCodeColors.accent),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterPasswordUnlock,
                    style: TextStyle(color: VsCodeColors.foregroundDim),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _controller,
                    obscureText: _obscure,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      errorText: _error,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.unlock),
                    ),
                  ),
                  if (security.isBiometricEnabled && security.canUseBiometric) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => security.unlockWithBiometric(),
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.biometrics),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
