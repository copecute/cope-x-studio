import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogConsoleSheet extends StatelessWidget {
  const LogConsoleSheet({super.key});

  static Future<void> show(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.45;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VsCodeColors.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SizedBox(
        height: sheetHeight,
        child: const LogConsoleSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<WorkspaceProvider>();
    final logs = provider.logHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Icon(Icons.terminal, color: VsCodeColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(l10n.consoleLog, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: provider.clearLogs,
                child: Text(l10n.clearLog),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: VsCodeColors.border),
        Expanded(
          child: logs.isEmpty
              ? Center(child: Text(l10n.noLogsYet, style: TextStyle(color: VsCodeColors.foregroundDim)))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SelectableText(
                        logs[index],
                        style: TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 13,
                          color: VsCodeColors.foreground,
                          height: 1.4,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
