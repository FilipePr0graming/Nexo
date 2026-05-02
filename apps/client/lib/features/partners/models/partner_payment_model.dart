enum PartnerPaymentStatus {
  open,
  paid,
  canceled,
}

class PartnerPaymentModel {
  const PartnerPaymentModel({
    required this.id,
    required this.partnerId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.paymentId,
    this.paidAt,
  });

  final String id;
  final String partnerId;
  final String? paymentId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final PartnerPaymentStatus status;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerPaymentModel copyWith({
    String? id,
    String? partnerId,
    String? paymentId,
    String? description,
    double? amount,
    DateTime? dueDate,
    DateTime? paidAt,
    PartnerPaymentStatus? status,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnerPaymentModel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      paymentId: paymentId ?? this.paymentId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PartnerPaymentModel.fromJson(Map<String, dynamic> json) {
    return PartnerPaymentModel(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      paymentId: json['payment_id'] as String?,
      description: (json['description'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: _parseDate(json['due_date']),
      paidAt: _parseOptionalDate(json['paid_at']),
      status: _statusFromStorage(json['status'] as String?),
      source: (json['source'] as String?) ?? 'manual',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'payment_id': paymentId,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toUtc().toIso8601String(),
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'status': _statusToStorage(status),
      'source': source,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static PartnerPaymentStatus _statusFromStorage(String? value) {
    return switch (value) {
      'paid' => PartnerPaymentStatus.paid,
      'canceled' => PartnerPaymentStatus.canceled,
      _ => PartnerPaymentStatus.open,
    };
  }

  static String _statusToStorage(PartnerPaymentStatus value) {
    return switch (value) {
      PartnerPaymentStatus.open => 'open',
      PartnerPaymentStatus.paid => 'paid',
      PartnerPaymentStatus.canceled => 'canceled',
    };
  }
}

extension PartnerPaymentStatusLabel on PartnerPaymentStatus {
  String get label {
    return switch (this) {
      PartnerPaymentStatus.open => 'Aberto',
      PartnerPaymentStatus.paid => 'Pago',
      PartnerPaymentStatus.canceled => 'Cancelado',
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
