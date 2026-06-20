import 'package:cope_x_studio/models/browser_entry.dart';

class TreeBrowserNode {
  const TreeBrowserNode({
    required this.entry,
    required this.depth,
    required this.isExpanded,
    required this.hasChildren,
    this.isLoading = false,
    this.isCurrent = false,
  });

  final BrowserEntry entry;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isLoading;
  final bool isCurrent;
}
