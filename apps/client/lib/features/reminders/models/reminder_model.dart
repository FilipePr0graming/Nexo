enum ReminderStatus {
  open,
  done,
  canceled,
}

class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.recurrence,
    this.relatedTable,
    this.relatedId,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final ReminderStatus status;
  final String? recurrence;
  final String? relatedTable;
  final String? relatedId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    ReminderStatus? status,
    String? recurrence,
    String? relatedTable,
    String? relatedId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      relatedTable: relatedTable ?? this.relatedTable,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      dueDate: _parseDate(json['due_date']),
      status: _statusFromStorage(json['status'] as String?),
      recurrence: json['recurrence'] as String?,
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
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': _statusToStorage(status),
      'recurrence': recurrence,
      'related_table': relatedTable,
      'related_id': relatedId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static ReminderStatus _statusFromStorage(String? value) {
    return switch (value) {
      'done' => ReminderStatus.done,
      'canceled' => ReminderStatus.canceled,
      _ => ReminderStatus.open,
    };
  }

  static String _statusToStorage(ReminderStatus value) {
    return switch (value) {
      ReminderStatus.open => 'open',
      ReminderStatus.done => 'done',
      ReminderStatus.canceled => 'canceled',
    };
  }
}

extension ReminderStatusLabel on ReminderStatus {
  String get label {
    return switch (this) {
      ReminderStatus.open => 'Aberto',
      ReminderStatus.done => 'Concluido',
      ReminderStatus.canceled => 'Cancelado',
    };
  }
}

DateTime _parseDate(Object? value) {
  return DateTime.parse(
    (value as String?) ?? DateTime.now().toUtc().toIso8601String(),
  );
}
