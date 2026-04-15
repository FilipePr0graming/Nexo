enum ClientType {
  pf,
  pj,
}

enum ClientBillingType {
  monthly,
  oneOff,
}

enum ClientStatus {
  lead,
  active,
  inProgress,
  paused,
  completed,
}

class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.clientType,
    required this.status,
    required this.billingType,
    required this.hasDanielParticipation,
    required this.createdAt,
    required this.updatedAt,
    this.legalName,
    this.document,
    this.phone,
    this.notes,
    this.origin,
    this.zipCode,
    this.street,
    this.streetNumber,
    this.addressComplement,
    this.neighborhood,
    this.city,
    this.stateCode,
    this.country = 'BR',
  });

  final String id;
  final String name;
  final ClientType clientType;
  final String? legalName;
  final String? document;
  final String? phone;
  final String? notes;
  final String? origin;
  final String? zipCode;
  final String? street;
  final String? streetNumber;
  final String? addressComplement;
  final String? neighborhood;
  final String? city;
  final String? stateCode;
  final String country;
  final ClientStatus status;
  final ClientBillingType billingType;
  final bool hasDanielParticipation;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompany => clientType == ClientType.pj;

  String get documentLabel {
    return switch (clientType) {
      ClientType.pf => 'CPF',
      ClientType.pj => 'CNPJ',
    };
  }

  String? get cityStateLabel {
    final parts = [city, stateCode]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' - ');
  }

  String? get addressLine {
    final firstLine = [
      street,
      streetNumber,
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(', ');

    final secondLine = [
      neighborhood,
      cityStateLabel,
      zipCode,
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' | ');

    final parts = [firstLine, secondLine]
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' | ');
  }

  ClientModel copyWith({
    String? id,
    String? name,
    ClientType? clientType,
    String? legalName,
    String? document,
    String? phone,
    String? notes,
    String? origin,
    String? zipCode,
    String? street,
    String? streetNumber,
    String? addressComplement,
    String? neighborhood,
    String? city,
    String? stateCode,
    String? country,
    ClientStatus? status,
    ClientBillingType? billingType,
    bool? hasDanielParticipation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientType: clientType ?? this.clientType,
      legalName: legalName ?? this.legalName,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      origin: origin ?? this.origin,
      zipCode: zipCode ?? this.zipCode,
      street: street ?? this.street,
      streetNumber: streetNumber ?? this.streetNumber,
      addressComplement: addressComplement ?? this.addressComplement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      stateCode: stateCode ?? this.stateCode,
      country: country ?? this.country,
      status: status ?? this.status,
      billingType: billingType ?? this.billingType,
      hasDanielParticipation:
          hasDanielParticipation ?? this.hasDanielParticipation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      clientType: _clientTypeFromStorage(json['client_type'] as String?),
      legalName: json['legal_name'] as String?,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      origin: json['origin'] as String?,
      zipCode: json['zip_code'] as String?,
      street: json['street'] as String?,
      streetNumber: json['street_number'] as String?,
      addressComplement: json['address_complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      stateCode: json['state_code'] as String?,
      country: (json['country'] as String?) ?? 'BR',
      status: _statusFromStorage(json['status'] as String?),
      billingType: _billingTypeFromStorage(json['billing_type'] as String?),
      hasDanielParticipation:
          (json['has_daniel_participation'] as bool?) ?? false,
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
      'name': name,
      'client_type': _clientTypeToStorage(clientType),
      'legal_name': legalName,
      'document': document,
      'phone': phone,
      'notes': notes,
      'origin': origin,
      'zip_code': zipCode,
      'street': street,
      'street_number': streetNumber,
      'address_complement': addressComplement,
      'neighborhood': neighborhood,
      'city': city,
      'state_code': stateCode,
      'country': country,
      'status': _statusToStorage(status),
      'billing_type': _billingTypeToStorage(billingType),
      'has_daniel_participation': hasDanielParticipation,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static ClientType _clientTypeFromStorage(String? value) {
    return switch (value) {
      'pj' => ClientType.pj,
      _ => ClientType.pf,
    };
  }

  static String _clientTypeToStorage(ClientType value) {
    return switch (value) {
      ClientType.pf => 'pf',
      ClientType.pj => 'pj',
    };
  }

  static ClientStatus _statusFromStorage(String? value) {
    return switch (value) {
      'lead' => ClientStatus.lead,
      'in_progress' => ClientStatus.inProgress,
      'paused' => ClientStatus.paused,
      'completed' => ClientStatus.completed,
      _ => ClientStatus.active,
    };
  }

  static String _statusToStorage(ClientStatus value) {
    return switch (value) {
      ClientStatus.lead => 'lead',
      ClientStatus.active => 'active',
      ClientStatus.inProgress => 'in_progress',
      ClientStatus.paused => 'paused',
      ClientStatus.completed => 'completed',
    };
  }

  static ClientBillingType _billingTypeFromStorage(String? value) {
    return switch (value) {
      'monthly' => ClientBillingType.monthly,
      _ => ClientBillingType.oneOff,
    };
  }

  static String _billingTypeToStorage(ClientBillingType value) {
    return switch (value) {
      ClientBillingType.monthly => 'monthly',
      ClientBillingType.oneOff => 'one_off',
    };
  }
}

extension ClientTypeLabel on ClientType {
  String get label {
    return switch (this) {
      ClientType.pf => 'PF',
      ClientType.pj => 'PJ',
    };
  }
}

extension ClientBillingTypeLabel on ClientBillingType {
  String get label {
    return switch (this) {
      ClientBillingType.monthly => 'Mensal',
      ClientBillingType.oneOff => 'Avulso',
    };
  }
}

extension ClientStatusLabel on ClientStatus {
  String get label {
    return switch (this) {
      ClientStatus.lead => 'Lead',
      ClientStatus.active => 'Ativo',
      ClientStatus.inProgress => 'Execucao',
      ClientStatus.paused => 'Pausado',
      ClientStatus.completed => 'Concluido',
    };
  }
}
