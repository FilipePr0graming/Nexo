class PartnerModel {
  const PartnerModel({
    required this.id,
    required this.name,
    required this.defaultPercent,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String name;
  final double defaultPercent;
  final bool active;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      defaultPercent: (json['default_percent'] as num?)?.toDouble() ?? 0,
      active: (json['active'] as bool?) ?? true,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_percent': defaultPercent,
      'active': active,
      'notes': notes,
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
