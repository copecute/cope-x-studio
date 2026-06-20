import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditorTabBar extends StatelessWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final tabs = provider.tabs;

    return Container(
      height: AppSizes.tabBarHeight,
      decoration: BoxDecoration(
        color: VsCodeColors.tabBar,
        border: Border(top: BorderSide(color: VsCodeColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return _TabItem(
                  tab: tab,
                  isActive: tab.id == provider.activeTabId,
                  onTap: () => provider.activateTab(tab.id),
                  onClose: () => provider.closeTab(tab.id),
                );
              },
            ),
          ),
          _NewTabButton(onTap: provider.newTab),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  IconData get _icon {
    if (tab.isEditing && tab.editor != null) {
      return switch (tab.editor!.type) {
        EditorTabType.text => Icons.code,
        EditorTabType.pdf => Icons.picture_as_pdf,
        EditorTabType.media => Icons.play_circle_fill,
        EditorTabType.empty => Icons.tab_outlined,
      };
    }
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? VsCodeColors.tabActive : VsCodeColors.tabInactive,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200, minWidth: 110),
          height: AppSizes.tabBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: VsCodeColors.border),
              top: BorderSide(
                color: isActive ? VsCodeColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(_icon, size: AppSizes.iconSmall, color: VsCodeColors.foregroundDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tab.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSizes.fontSmall,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
                  ),
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTabButton extends StatelessWidget {
  const _NewTabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: IconButton(
        tooltip: 'Tab duyệt file mới',
        onPressed: onTap,
        icon: const Icon(Icons.add, size: AppSizes.iconMedium),
      ),
    );
  }
}
