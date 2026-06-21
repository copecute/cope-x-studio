import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:cope_x_studio/widgets/browser/tab_content_view.dart';
import 'package:cope_x_studio/widgets/shell/editor_tab_bar.dart';
import 'package:cope_x_studio/widgets/shell/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VsCodeColors.sidebar,
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.exit)),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final fullscreen = context.watch<WorkspaceProvider>().fullscreenEnabled;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final provider = context.read<WorkspaceProvider>();
        final handled = provider.handleBackNavigation();
        if (handled) return;

        if (provider.requireExitConfirmation) {
          final confirmed = await _confirmExit(context);
          if (!confirmed) return;
        }
        await provider.saveSessionState();
        SystemNavigator.pop();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            context.read<WorkspaceProvider>().saveActiveTab();
          },
          const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
            context.read<WorkspaceProvider>().newTab();
          },
          const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
            final provider = context.read<WorkspaceProvider>();
            final tab = provider.activeTab;
            if (tab != null) provider.closeTab(tab.id);
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: VsCodeColors.editor,
            body: fullscreen
                ? Column(
                    children: [
                      const Expanded(child: TabContentView()),
                      const EditorTabBar(),
                      StatusBar(),
                    ],
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        const Expanded(child: TabContentView()),
                        const EditorTabBar(),
                        StatusBar(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
