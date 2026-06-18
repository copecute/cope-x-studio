import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WebServerSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final security = context.watch<SecurityProvider>();
    final running = provider.isWebServerRunning;
    final urls = provider.webServerUrls;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                    'Web Server (X-plore)',
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
              'Toàn quyền truy cập bộ nhớ thiết bị. Thiết bị khác trong cùng Wi‑Fi mở địa chỉ bên dưới để quản lý file.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.4),
            ),
          ),
          if (security.hasPassword)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 16, color: VsCodeColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trình duyệt sẽ hỏi mật khẩu app (tên đăng nhập tùy ý).',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                'Chưa có mật khẩu — ai trong mạng đều truy cập được. Đặt mật khẩu trong Cài đặt.',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade300),
              ),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(running ? 'Đang chạy — port ${WebServerService.port}' : 'Tắt'),
            subtitle: running ? const Text('Toàn quyền bộ nhớ', style: TextStyle(fontSize: 12)) : null,
            value: running,
            onChanged: (on) async {
              if (on) {
                await provider.startWebServer();
              } else {
                await provider.stopWebServer();
              }
            },
          ),
          if (running && urls.isNotEmpty) ...[
            const Divider(height: 1, color: VsCodeColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Truy cập từ thiết bị khác:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
            ...urls.map((url) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.link, size: 20, color: VsCodeColors.accent),
                  title: SelectableText(url, style: const TextStyle(fontSize: 15)),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Sao chép',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã copy: $url'), duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                )),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
