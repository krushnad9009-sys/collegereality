class SavedComparisonModel {
  final String id;
  final String title;
  final List<String> collegeIds;
  final DateTime savedAt;

  const SavedComparisonModel({
    required this.id,
    required this.title,
    required this.collegeIds,
    required this.savedAt,
  });

  factory SavedComparisonModel.fromJson(Map<String, dynamic> json) {
    return SavedComparisonModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Saved comparison',
      collegeIds: (json['collegeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'collegeIds': collegeIds,
        'savedAt': savedAt.toIso8601String(),
      };
}
