import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/browser/tab_content_view.dart';
import 'package:cope_x_studio/widgets/shell/editor_tab_bar.dart';
import 'package:cope_x_studio/widgets/shell/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        final provider = context.read<WorkspaceProvider>();
        final handled = provider.handleBackNavigation();
        if (!handled) {
          SystemNavigator.pop();
        }
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
            body: SafeArea(
              child: Column(
                children: [
                  const Expanded(child: TabContentView()),
                  const EditorTabBar(),
                  const StatusBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
