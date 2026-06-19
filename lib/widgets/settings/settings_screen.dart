import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _showPasswordSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VsCodeColors.sidebar,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AppLockPasswordSheet(),
    );
    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result == 'changed' ? 'Đã đổi mật khẩu' : 'Đã đặt mật khẩu'),
      ),
    );
    await context.read<WorkspaceProvider>().restartWebServerIfRunning();
  }

  Future<void> _onLockToggle(bool enabled) async {
    final security = context.read<SecurityProvider>();

    if (enabled) {
      if (!security.hasPassword) {
        await _showPasswordSheet();
        return;
      }
      try {
        await security.setLockEnabled(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }

    try {
      await security.setLockEnabled(false);
      if (!mounted) return;
      await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _appLockSubtitle(SecurityProvider security) {
    if (security.isLockEnabled) {
      return 'Yêu cầu mật khẩu sau 1 phút rời app. Chạm để đổi mật khẩu.';
    }
    if (security.hasPassword) {
      return 'Khóa đang tắt. Chạm để đổi mật khẩu.';
    }
    return 'Chạm để đặt mật khẩu, sau đó bật switch để kích hoạt.';
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    return Scaffold(
      backgroundColor: VsCodeColors.editor,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: VsCodeColors.tabBar,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Khóa ứng dụng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _AppLockTile(
            enabled: security.isLockEnabled,
            subtitle: _appLockSubtitle(security),
            onTap: _showPasswordSheet,
            onToggle: _onLockToggle,
          ),
          const Divider(height: 40, color: VsCodeColors.border),
          const Text(
            'Sinh trắc học',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (!security.canUseBiometric)
            const Text(
              'Thiết bị không hỗ trợ vân tay / Face ID.',
              style: TextStyle(color: VsCodeColors.foregroundDim),
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mở khóa bằng sinh trắc học'),
              subtitle: Text(
                security.hasPassword
                    ? 'Dùng vân tay hoặc Face ID thay mật khẩu'
                    : 'Cần đặt mật khẩu trước',
              ),
              value: security.isBiometricEnabled,
              onChanged: security.hasPassword
                  ? (v) async {
                      try {
                        await security.setBiometricEnabled(v);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    }
                  : null,
            ),
          const Divider(height: 40, color: VsCodeColors.border),
          const Text(
            'Hiển thị',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hiển thị tệp tin ẩn'),
            subtitle: const Text('Hiện tệp tin bắt đầu bằng dấu chấm hoặc tệp hệ thống'),
            value: workspace.showHidden,
            onChanged: (v) {
              workspace.setShowHidden(v);
            },
          ),
        ],
      ),
    );
  }
}

class _AppLockTile extends StatelessWidget {
  const _AppLockTile({
    required this.enabled,
    required this.subtitle,
    required this.onTap,
    required this.onToggle,
  });

  final bool enabled;
  final String subtitle;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khóa ứng dụng', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: VsCodeColors.foregroundDim, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: VsCodeColors.border.withValues(alpha: 0.6),
        ),
        Switch(value: enabled, onChanged: onToggle),
      ],
    );
  }
}

class _AppLockPasswordSheet extends StatefulWidget {
  const _AppLockPasswordSheet();

  @override
  State<_AppLockPasswordSheet> createState() => _AppLockPasswordSheetState();
}

class _AppLockPasswordSheetState extends State<_AppLockPasswordSheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _saving = false;
  late final bool _wasChanging;

  @override
  void initState() {
    super.initState();
    _wasChanging = context.read<SecurityProvider>().hasPassword;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final password = _ctrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Mật khẩu không được để trống');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final security = context.read<SecurityProvider>();
    try {
      if (_wasChanging) {
        await security.updatePassword(password);
      } else {
        await security.setPassword(password);
      }
      if (!mounted) return;
      Navigator.pop(context, _wasChanging ? 'changed' : 'set');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _wasChanging ? 'Đổi mật khẩu' : 'Đặt mật khẩu',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mật khẩu dùng để khóa app khi mở lại (sau 1 phút rời app).',
            style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_wasChanging ? 'Lưu mật khẩu' : 'Đặt mật khẩu'),
          ),
        ],
      ),
    );
  }
}
