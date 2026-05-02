class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.relatedTable,
    this.relatedId,
  });

  final String id;
  final String title;
  final String body;
  final String? relatedTable;
  final String? relatedId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    String? relatedTable,
    String? relatedId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedTable: relatedTable ?? this.relatedTable,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      relatedTable: json['related_table'] as String?,
      relatedId: json['related_id'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'related_table': relatedTable,
      'related_id': relatedId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}

DateTime _parseDate(Object? value) {
  return DateTime.parse(
    (value as String?) ?? DateTime.now().toUtc().toIso8601String(),
  );
}
