import 'package:cope_x_studio/widgets/shell/folder_picker_sheet.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WebServerSheet extends StatefulWidget {
  const WebServerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF252526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => const WebServerSheet(),
    );
  }

  @override
  State<WebServerSheet> createState() => _WebServerSheetState();
}

class _WebServerSheetState extends State<WebServerSheet> {
  Future<void> _pickSharedFolder(SecurityProvider security) async {
    final result = await FolderPickerSheet.pick(
      context,
      initialPath: security.webServerSharedRoot,
    );
    if (result == null || !mounted) return;
    await security.setWebServerSharedRoot(result);
    if (!mounted) return;
    await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    setState(() {});
  }
  Future<void> _clearSharedFolder(SecurityProvider security) async {
    await security.setWebServerSharedRoot(null);
    if (!mounted) return;
    await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    setState(() {});
  }

  Future<void> _showWebPasswordSheet(SecurityProvider security) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VsCodeColors.sidebar,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _WebServerPasswordSheet(
        hasPassword: security.hasWebServerPassword,
      ),
    );
    if (!mounted || result == null) return;

    final workspace = context.read<WorkspaceProvider>();
    if (result == 'cleared') {
      await security.clearWebServerPassword();
    } else if (result.isNotEmpty) {
      if (security.hasWebServerPassword) {
        await security.updateWebServerPassword(result);
      } else {
        await security.setWebServerPassword(result);
      }
    }
    if (!mounted) return;
    await workspace.restartWebServerIfRunning();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final security = context.watch<SecurityProvider>();
    final running = provider.isWebServerRunning;
    final url = provider.webServerUrl;
    final sharedRoot = security.webServerSharedRoot;
    final useAppPassword = security.webServerUseAppPassword;
    final canUseAppPassword = security.isLockEnabled && security.hasPassword;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering, color: VsCodeColors.accent, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Web Server',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Chia sẻ file qua Wi‑Fi. Thiết bị khác mở địa chỉ hoặc quét QR để truy cập.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Thư mục chia sẻ'),
              subtitle: Text(
                sharedRoot ?? 'Toàn bộ bộ nhớ thiết bị',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.folder_outlined),
                onSelected: (v) async {
                  if (v == 'pick') {
                    await _pickSharedFolder(security);
                  } else if (v == 'clear') {
                    await _clearSharedFolder(security);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'pick', child: Text('Chọn thư mục')),
                  if (sharedRoot != null)
                    const PopupMenuItem(value: 'clear', child: Text('Toàn bộ bộ nhớ')),
                ],
              ),
            ),
            if (canUseAppPassword)
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Dùng mật khẩu khóa app'),
                subtitle: const Text('HTTP Basic Auth — tên đăng nhập tùy ý', style: TextStyle(fontSize: 12)),
                value: useAppPassword,
                onChanged: running
                    ? null
                    : (v) async {
                        await security.setWebServerUseAppPassword(v);
                        setState(() {});
                      },
              ),
            if (!useAppPassword || !canUseAppPassword)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Mật khẩu Web Server'),
                subtitle: Text(
                  security.hasWebServerPassword
                      ? 'Đã đặt — chạm để đổi'
                      : 'Chưa đặt — ai trong mạng đều truy cập được',
                  style: TextStyle(
                    fontSize: 12,
                    color: security.hasWebServerPassword
                        ? Colors.grey.shade500
                        : Colors.orange.shade300,
                  ),
                ),
                trailing: const Icon(Icons.lock_outline, size: 20),
                onTap: running ? null : () => _showWebPasswordSheet(security),
              ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(running ? 'Đang chạy — port ${WebServerService.port}' : 'Bật server'),
              subtitle: running
                  ? Text(
                      sharedRoot != null ? 'Chỉ: $sharedRoot' : 'Toàn bộ bộ nhớ',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              value: running,
              onChanged: (on) async {
                if (on) {
                  await provider.startWebServer();
                } else {
                  await provider.stopWebServer();
                }
              },
            ),
            if (running && url != null) ...[
              const Divider(height: 1, color: VsCodeColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: url,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.link, size: 20, color: VsCodeColors.accent),
                title: SelectableText(url, style: const TextStyle(fontSize: 15)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Sao chép',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép địa chỉ'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Thông báo ongoing hiển thị QR và nút dừng server.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _WebServerPasswordSheet extends StatefulWidget {
  const _WebServerPasswordSheet({required this.hasPassword});

  final bool hasPassword;

  @override
  State<_WebServerPasswordSheet> createState() => _WebServerPasswordSheetState();
}

class _WebServerPasswordSheetState extends State<_WebServerPasswordSheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final password = _ctrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Mật khẩu không được để trống');
      return;
    }
    Navigator.pop(context, password);
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
            widget.hasPassword ? 'Đổi mật khẩu Web Server' : 'Đặt mật khẩu Web Server',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
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
            onPressed: _save,
            child: Text(widget.hasPassword ? 'Lưu' : 'Đặt mật khẩu'),
          ),
          if (widget.hasPassword) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cleared'),
              child: const Text('Xóa mật khẩu', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}
