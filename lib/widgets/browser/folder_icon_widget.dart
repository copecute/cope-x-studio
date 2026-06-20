import 'package:cope_x_studio/utils/folder_icon_style.dart';
import 'package:flutter/material.dart';

/// Icon thư mục động theo tên — chỉ dùng Stack, Icon và Container.
class FolderIconWidget extends StatelessWidget {
  const FolderIconWidget({
    super.key,
    required this.folderName,
    this.size = 48,
    this.open = false,
  });

  final String folderName;
  final double size;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final config = folderIconConfigForName(folderName);
    final theme = Theme.of(context);
    final badgeColor = config.badgeColor;
    final overlayBg = config.badgeBgColor ?? theme.colorScheme.surface;
    final overlayFg = badgeColor ?? theme.colorScheme.onSurface;
    final borderColor = badgeColor ?? (theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            open ? Icons.folder_open_rounded : Icons.folder_rounded,
            size: size,
            color: folderIconBaseColor,
          ),
          if (config.overlayIcon != null && badgeColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: overlayBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: (size * 0.045).clamp(1.0, 2.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  config.overlayIcon,
                  size: size * 0.24,
                  color: overlayFg,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
