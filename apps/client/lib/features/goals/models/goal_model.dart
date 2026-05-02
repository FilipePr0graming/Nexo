enum GoalStatus {
  active,
  done,
  paused,
}

class GoalModel {
  const GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? dueDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (currentAmount / targetAmount).clamp(0, 1).toDouble();
  }

  double get remaining {
    return (targetAmount - currentAmount).clamp(0, double.infinity).toDouble();
  }

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? dueDate,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      dueDate: _parseOptionalDate(json['due_date']),
      status: _statusFromStorage(json['status'] as String?),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'status': _statusToStorage(status),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static GoalStatus _statusFromStorage(String? value) {
    return switch (value) {
      'done' => GoalStatus.done,
      'paused' => GoalStatus.paused,
      _ => GoalStatus.active,
    };
  }

  static String _statusToStorage(GoalStatus value) {
    return switch (value) {
      GoalStatus.active => 'active',
      GoalStatus.done => 'done',
      GoalStatus.paused => 'paused',
    };
  }
}

extension GoalStatusLabel on GoalStatus {
  String get label {
    return switch (this) {
      GoalStatus.active => 'Ativa',
      GoalStatus.done => 'Concluida',
      GoalStatus.paused => 'Pausada',
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
