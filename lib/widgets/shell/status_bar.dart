import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/shell/log_console_sheet.dart';
import 'package:cope_x_studio/widgets/shell/web_server_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final tab = provider.activeTab;
    final l10n = context.l10n;
    final message = provider.statusMessage ?? (tab?.currentPath ?? l10n.ready);
    final webServerRunning = context.select<WorkspaceProvider, bool>((p) => p.isWebServerRunning);

    return Material(
      color: VsCodeColors.statusBar,
      child: InkWell(
        onTap: () => LogConsoleSheet.show(context),
        child: Container(
          height: AppSizes.statusBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: AppSizes.fontCaption),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.unfold_more, size: 14, color: Colors.white54),
              if (webServerRunning) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => WebServerSheet.show(context),
                  child: const Icon(Icons.wifi_tethering, size: 14, color: Colors.white),
                ),
              ],
              if (tab?.isEditing == true && tab?.editor != null) ...[
                const SizedBox(width: 14),
                Text(
                  tab!.editor!.language,
                  style: const TextStyle(color: Colors.white, fontSize: AppSizes.fontCaption),
                ),
                const SizedBox(width: 14),
                Text(
                  tab.editor!.isModified ? l10n.notSaved : l10n.saved,
                  style: const TextStyle(color: Colors.white, fontSize: AppSizes.fontCaption),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
