enum AiSourceType {
  profile,
  review,
  answer,
  communityPost,
}

class AiSourceCitation {
  final AiSourceType type;
  final String id;
  final String label;
  final String excerpt;
  final String actionRoute;

  const AiSourceCitation({
    required this.type,
    required this.id,
    required this.label,
    required this.excerpt,
    this.actionRoute = '',
  });

  factory AiSourceCitation.fromJson(Map<String, dynamic> json) {
    return AiSourceCitation(
      type: AiSourceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AiSourceType.profile,
      ),
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      actionRoute: json['actionRoute'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'label': label,
        'excerpt': excerpt,
        'actionRoute': actionRoute,
      };
}
