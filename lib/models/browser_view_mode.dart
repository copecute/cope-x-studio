enum BrowserViewMode {
  list,
  grid,
  tree;

  String get storageValue => name;

  static BrowserViewMode fromStorage(String? value, {bool legacyGrid = false}) {
    if (value == null || value.isEmpty) {
      return legacyGrid ? BrowserViewMode.grid : BrowserViewMode.list;
    }
    return BrowserViewMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => legacyGrid ? BrowserViewMode.grid : BrowserViewMode.list,
    );
  }
}
