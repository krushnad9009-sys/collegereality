/// Super Admin-curated "Top Picks" for the Home screen: an ordered list of
/// colleges and an ordered list of guides, stored as ONE document
/// (`homepage_featured/current`). A single doc (instead of per-entity
/// isFeatured/featuredPriority fields) keeps Home to one read, makes a
/// reorder one atomic write, and never collides with the server-managed
/// public_profiles mirror or the separate college `isFeatured` pool that
/// feeds Trending / Recommended. List position = priority (1, 2, 3...).
class HomeFeaturedConfig {
  /// Cap per list -- mirrored in firestore.rules.
  static const int maxItems = 10;

  final List<String> collegeIds;
  final List<String> guideIds;
  final DateTime? updatedAt;
  final String? updatedBy;

  const HomeFeaturedConfig({
    this.collegeIds = const [],
    this.guideIds = const [],
    this.updatedAt,
    this.updatedBy,
  });

  static const empty = HomeFeaturedConfig();

  bool get isEmpty => collegeIds.isEmpty && guideIds.isEmpty;

  factory HomeFeaturedConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    List<String> ids(Object? raw) => raw is List
        ? raw.whereType<String>().where((s) => s.isNotEmpty).toSet().toList()
        : const [];
    final rawUpdated = json['updatedAt'];
    DateTime? updatedAt;
    if (rawUpdated is String) {
      updatedAt = DateTime.tryParse(rawUpdated);
    } else if (rawUpdated != null) {
      try {
        updatedAt = (rawUpdated as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    return HomeFeaturedConfig(
      collegeIds: ids(json['collegeIds']).take(maxItems).toList(),
      guideIds: ids(json['guideIds']).take(maxItems).toList(),
      updatedAt: updatedAt,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}

/// Appends [id] if it isn't already listed and there's room.
List<String> addFeaturedId(
  List<String> ids,
  String id, {
  int max = HomeFeaturedConfig.maxItems,
}) {
  if (id.isEmpty || ids.contains(id) || ids.length >= max) return ids;
  return [...ids, id];
}

/// Moves the item at [oldIndex] so it ends up at position [newIndex]
/// (final index, as ReorderableListView.onReorderItem reports it).
List<String> moveFeaturedId(List<String> ids, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= ids.length) return ids;
  final target = newIndex.clamp(0, ids.length - 1);
  final next = [...ids];
  final item = next.removeAt(oldIndex);
  next.insert(target, item);
  return next;
}

/// [byId] values in the curated order of [ids]; ids that didn't resolve
/// (deleted college, guide no longer available) are skipped.
List<T> inFeaturedOrder<T>(List<String> ids, Map<String, T> byId) => [
      for (final id in ids)
        if (byId[id] != null) byId[id] as T,
    ];
