import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogConsoleSheet extends StatelessWidget {
  const LogConsoleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => const LogConsoleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final logs = provider.logHistory;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.terminal, color: VsCodeColors.accent, size: 22),
                  const SizedBox(width: 8),
                  const Text('Console Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: provider.clearLogs,
                    child: const Text('Xóa log'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: VsCodeColors.border),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('Chưa có log', style: TextStyle(color: VsCodeColors.foregroundDim)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SelectableText(
                            logs[index],
                            style: const TextStyle(
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
      },
    );
  }
}
