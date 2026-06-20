import 'package:cope_x_studio/widgets/shell/folder_picker_sheet.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WebServerSheet extends StatefulWidget {
  const WebServerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VsCodeColors.sidebar,
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
    final l10n = context.l10n;
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
                  Icon(Icons.wifi_tethering, color: VsCodeColors.accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.webServer,
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
                l10n.shareViaWifi,
                style: TextStyle(fontSize: 14, color: VsCodeColors.foregroundDim, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l10n.sharedFolder),
              subtitle: Text(
                sharedRoot ?? l10n.entireStorage,
                style: TextStyle(fontSize: 12, color: VsCodeColors.foregroundDim),
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
                  PopupMenuItem(value: 'pick', child: Text(l10n.pickFolder)),
                  if (sharedRoot != null)
                    PopupMenuItem(value: 'clear', child: Text(l10n.entireStorage)),
                ],
              ),
            ),
            if (canUseAppPassword)
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.useAppLockPassword),
                subtitle: Text(l10n.httpBasicAuthHint, style: TextStyle(fontSize: 12)),
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
                title: Text(l10n.webServerPassword),
                subtitle: Text(
                  security.hasWebServerPassword
                      ? l10n.webServerPasswordSet
                      : l10n.webServerPasswordUnset,
                  style: TextStyle(
                    fontSize: 12,
                    color: security.hasWebServerPassword
                        ? VsCodeColors.foregroundDim
                        : Colors.orange.shade700,
                  ),
                ),
                trailing: const Icon(Icons.lock_outline, size: 20),
                onTap: running ? null : () => _showWebPasswordSheet(security),
              ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(running ? l10n.serverRunning(WebServerService.port) : l10n.startServer),
              subtitle: running
                  ? Text(
                      sharedRoot != null ? l10n.onlyFolder(sharedRoot) : l10n.entireStorage,
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
              Divider(height: 1, color: VsCodeColors.border),
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
                leading: Icon(Icons.link, size: 20, color: VsCodeColors.accent),
                title: SelectableText(url, style: const TextStyle(fontSize: 15)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: l10n.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.addressCopied), duration: Duration(seconds: 2)),
                    );
                  },
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
    final l10n = context.l10n;
    final password = _ctrl.text;
    if (password.isEmpty) {
      setState(() => _error = l10n.passwordEmptyError);
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            widget.hasPassword ? l10n.changeWebServerPassword : l10n.setWebServerPassword,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
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
            child: Text(widget.hasPassword ? l10n.save : l10n.setPassword),
          ),
          if (widget.hasPassword) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cleared'),
              child: Text(l10n.removeWebServerPassword, style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}
