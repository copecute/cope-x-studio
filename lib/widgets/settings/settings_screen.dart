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
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool error = false}) {
    setState(() {
      _message = msg;
      _isError = error;
    });
  }

  Future<void> _setNewPassword(SecurityProvider security) async {
    final p1 = _newCtrl.text;
    final p2 = _confirmCtrl.text;
    if (p1 != p2) {
      _showMsg('Mật khẩu xác nhận không khớp', error: true);
      return;
    }
    try {
      if (security.hasPassword) {
        await security.changePassword(_currentCtrl.text, p1);
      } else {
        await security.setPassword(p1);
      }
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      _showMsg('Đã lưu mật khẩu');
      if (!mounted) return;
      await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    } catch (e) {
      _showMsg('$e', error: true);
    }
  }

  Future<void> _removePassword(SecurityProvider security) async {
    try {
      await security.removePassword(_currentCtrl.text);
      _currentCtrl.clear();
      _showMsg('Đã tắt khóa ứng dụng');
      if (!mounted) return;
      await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    } catch (e) {
      _showMsg('$e', error: true);
    }
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
          Text(
            security.hasPassword
                ? 'Ứng dụng và Web Server (port 2910) được bảo vệ bằng mật khẩu này.'
                : 'Đặt mật khẩu để khóa app khi mở lại và yêu cầu đăng nhập khi truy cập Web Server.',
            style: const TextStyle(color: VsCodeColors.foregroundDim, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (security.hasPassword)
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),
          if (security.hasPassword) const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: security.hasPassword ? 'Mật khẩu mới' : 'Mật khẩu',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () => _setNewPassword(security),
                child: Text(security.hasPassword ? 'Đổi mật khẩu' : 'Đặt mật khẩu'),
              ),
              if (security.hasPassword) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _removePassword(security),
                  child: const Text('Tắt khóa', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(color: _isError ? Colors.redAccent : Colors.greenAccent),
            ),
          ],
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
          const Divider(height: 40, color: VsCodeColors.border),
          const Text(
            'Web Server',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Web Server có toàn quyền truy cập bộ nhớ thiết bị (theo quyền app). '
            'Khi đã đặt mật khẩu, trình duyệt sẽ hỏi đăng nhập (HTTP Basic Auth) — dùng mật khẩu app, tên đăng nhập tùy ý.',
            style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.4),
          ),
        ],
      ),
    );
  }
}
