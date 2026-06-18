import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class RenameDialog {
  static Future<String?> show(
    BuildContext context, {
    required String initialName,
    String title = 'Đổi tên',
  }) async {
    final controller = TextEditingController(text: initialName);
    controller.selection = TextSelection(baseOffset: 0, extentOffset: initialName.length);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF383838),
        title: Text(title, style: const TextStyle(fontSize: 18)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
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
