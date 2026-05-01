enum SaleStatus {
  pending,
  received,
  late,
  canceled,
  refunded,
}

class SaleModel {
  const SaleModel({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.grossAmount,
    required this.platform,
    required this.paymentMethod,
    required this.installments,
    required this.saleDate,
    required this.expectedDate,
    required this.status,
    required this.platformFee,
    required this.paymentFee,
    required this.netAmount,
    required this.hasDanielParticipation,
    required this.danielPercent,
    required this.danielValue,
    required this.ownerAmount,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.projectGroup,
    this.serviceStage,
    this.receivedDate,
    this.notes,
    this.origin,
  });

  final String id;
  final String? clientId;
  final String clientName;
  final String serviceName;
  final String? projectGroup;
  final String? serviceStage;
  final double grossAmount;
  final String platform;
  final String paymentMethod;
  final int installments;
  final DateTime saleDate;
  final DateTime expectedDate;
  final DateTime? receivedDate;
  final SaleStatus status;
  final String? notes;
  final double platformFee;
  final double paymentFee;
  final double netAmount;
  final String? origin;
  final bool hasDanielParticipation;
  final double danielPercent;
  final double danielValue;
  final double ownerAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get movementDate => receivedDate ?? saleDate;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String?,
      clientName: (json['client_name'] as String?) ?? '',
      serviceName: (json['service_name'] as String?) ?? '',
      projectGroup: json['project_group'] as String?,
      serviceStage:
          json['service_stage'] as String? ?? json['current_stage'] as String?,
      grossAmount: (json['gross_amount'] as num?)?.toDouble() ?? 0,
      platform: (json['platform'] as String?) ?? '',
      paymentMethod: (json['payment_method'] as String?) ?? '',
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      saleDate: DateTime.parse(
        (json['sale_date'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      expectedDate: DateTime.parse(
        (json['expected_date'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      receivedDate: json['received_date'] == null
          ? null
          : DateTime.parse(json['received_date'] as String),
      status: _statusFromStorage(json['status'] as String?),
      notes: json['notes'] as String?,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      paymentFee: (json['payment_fee'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
      origin: json['origin'] as String?,
      hasDanielParticipation:
          (json['has_daniel_participation'] as bool?) ?? false,
      danielPercent: (json['daniel_percent'] as num?)?.toDouble() ?? 0,
      danielValue: (json['daniel_value'] as num?)?.toDouble() ?? 0,
      ownerAmount: (json['owner_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'service_name': serviceName,
      'project_group': projectGroup,
      'service_stage': serviceStage,
      'gross_amount': grossAmount,
      'platform': platform,
      'payment_method': paymentMethod,
      'installments': installments,
      'sale_date': saleDate.toUtc().toIso8601String(),
      'expected_date': expectedDate.toUtc().toIso8601String(),
      'received_date': receivedDate?.toUtc().toIso8601String(),
      'status': _statusToStorage(status),
      'notes': notes,
      'platform_fee': platformFee,
      'payment_fee': paymentFee,
      'net_amount': netAmount,
      'origin': origin,
      'has_daniel_participation': hasDanielParticipation,
      'daniel_percent': danielPercent,
      'daniel_value': danielValue,
      'owner_amount': ownerAmount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static SaleStatus _statusFromStorage(String? value) {
    return switch (value) {
      'received' => SaleStatus.received,
      'late' => SaleStatus.late,
      'canceled' => SaleStatus.canceled,
      'refunded' => SaleStatus.refunded,
      _ => SaleStatus.pending,
    };
  }

  static String _statusToStorage(SaleStatus value) {
    return switch (value) {
      SaleStatus.pending => 'pending',
      SaleStatus.received => 'received',
      SaleStatus.late => 'late',
      SaleStatus.canceled => 'canceled',
      SaleStatus.refunded => 'refunded',
    };
  }
}

extension SaleStatusLabel on SaleStatus {
  String get label {
    return switch (this) {
      SaleStatus.pending => 'Pendente',
      SaleStatus.received => 'Recebido',
      SaleStatus.late => 'Atrasado',
      SaleStatus.canceled => 'Cancelado',
      SaleStatus.refunded => 'Reembolsado',
    };
  }
}
