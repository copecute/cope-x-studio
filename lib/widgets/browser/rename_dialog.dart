import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class RenameDialog {
  static Future<String?> show(
    BuildContext context, {
    required String initialName,
    String? title,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initialName);
    controller.selection = TextSelection(baseOffset: 0, extentOffset: initialName.length);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VsCodeColors.sidebar,
        title: Text(title ?? l10n.rename, style: const TextStyle(fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || result == initialName) return null;
    return result;
  }

  static Future<String?> showForPath(BuildContext context, String fullPath) {
    return show(context, initialName: p.basename(fullPath));
  }
}
