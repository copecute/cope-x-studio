import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/services/entry_properties_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';

class EntryPropertiesDialog {
  static Future<void> show(
    BuildContext context, {
    required AppTab tab,
    required BrowserEntry entry,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _EntryPropertiesDialog(tab: tab, entry: entry),
    );
  }
}

class _EntryPropertiesDialog extends StatefulWidget {
  const _EntryPropertiesDialog({required this.tab, required this.entry});

  final AppTab tab;
  final BrowserEntry entry;

  @override
  State<_EntryPropertiesDialog> createState() => _EntryPropertiesDialogState();
}

class _EntryPropertiesDialogState extends State<_EntryPropertiesDialog> {
  final _service = EntryPropertiesService();
  late Future<List<PropertyField>> _fieldsFuture;

  @override
  void initState() {
    super.initState();
    _fieldsFuture = _service.buildFields(widget.tab, widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: VsCodeColors.tabBar,
      title: Text(l10n.propertyDetails),
      content: FutureBuilder<List<PropertyField>>(
        future: _fieldsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return SizedBox(
              width: 280,
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: VsCodeColors.accent),
                    ),
                    SizedBox(height: 14),
                    Text(l10n.loadingProperties, style: TextStyle(color: VsCodeColors.foregroundDim)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              width: 280,
              child: Text(
                l10n.cannotReadProperties('${snapshot.error}'),
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            );
          }

          final fields = snapshot.data ?? const [];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields) _propertyRow(field.label, field.value),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
      ],
    );
  }

  Widget _propertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: VsCodeColors.foregroundDim)),
          const SizedBox(height: 2),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
