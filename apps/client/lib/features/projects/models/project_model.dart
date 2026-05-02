enum ProjectStatus {
  active,
  paused,
  completed,
  canceled,
}

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.stage,
    required this.status,
    required this.budgetAmount,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.dueDate,
    this.notes,
  });

  final String id;
  final String? clientId;
  final String name;
  final String stage;
  final ProjectStatus status;
  final double budgetAmount;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel copyWith({
    String? id,
    String? clientId,
    String? name,
    String? stage,
    ProjectStatus? status,
    double? budgetAmount,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      status: status ?? this.status,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String?,
      name: (json['name'] as String?) ?? '',
      stage: (json['stage'] as String?) ?? 'briefing',
      status: _statusFromStorage(json['status'] as String?),
      budgetAmount: (json['budget_amount'] as num?)?.toDouble() ?? 0,
      dueDate: _parseOptionalDate(json['due_date']),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'name': name,
      'stage': stage,
      'status': _statusToStorage(status),
      'budget_amount': budgetAmount,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static ProjectStatus _statusFromStorage(String? value) {
    return switch (value) {
      'paused' => ProjectStatus.paused,
      'completed' => ProjectStatus.completed,
      'canceled' => ProjectStatus.canceled,
      _ => ProjectStatus.active,
    };
  }

  static String _statusToStorage(ProjectStatus value) {
    return switch (value) {
      ProjectStatus.active => 'active',
      ProjectStatus.paused => 'paused',
      ProjectStatus.completed => 'completed',
      ProjectStatus.canceled => 'canceled',
    };
  }
}

extension ProjectStatusLabel on ProjectStatus {
  String get label {
    return switch (this) {
      ProjectStatus.active => 'Ativo',
      ProjectStatus.paused => 'Pausado',
      ProjectStatus.completed => 'Concluido',
      ProjectStatus.canceled => 'Cancelado',
    };
  }
}

DateTime _parseDate(Object? value) {
  return DateTime.parse(
    (value as String?) ?? DateTime.now().toUtc().toIso8601String(),
  );
}

DateTime? _parseOptionalDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}
