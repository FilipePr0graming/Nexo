import '../models/company_lookup_result.dart';

class BrasilApiCnpjParser {
  const BrasilApiCnpjParser();

  CompanyLookupResult parse(Map<String, dynamic> json) {
    final legalName = _asString(json['razao_social']);
    final tradeName = _asString(json['nome_fantasia']);

    final cep = _asString(json['cep']);
    final street = _asString(json['logradouro']);
    final neighborhood = _asString(json['bairro']);
    final city = _asString(json['municipio']);
    final stateCode = _asString(json['uf']);

    final phone = _firstNonEmpty([
      _asString(json['ddd_telefone_1']),
      _asString(json['ddd_telefone_2']),
      _asString(json['telefone']),
      _asString(json['telefone_1']),
      _asString(json['telefone_2']),
    ]);

    return CompanyLookupResult(
      legalName: legalName,
      tradeName: tradeName,
      phone: phone,
      zipCode: cep,
      street: street,
      neighborhood: neighborhood,
      city: city,
      stateCode: stateCode,
    );
  }

  static String? _asString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}
