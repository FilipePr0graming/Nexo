import '../exceptions/lookup_exceptions.dart';
import '../models/address_lookup_result.dart';

class ViaCepParser {
  const ViaCepParser();

  AddressLookupResult parse(Map<String, dynamic> json) {
    final hasError = json['erro'] == true;
    if (hasError) {
      throw const LookupNotFoundException('CEP nao encontrado.');
    }

    final cep = _asString(json['cep']);
    final street = _asString(json['logradouro']);
    final neighborhood = _asString(json['bairro']);
    final city = _asString(json['localidade']);
    final stateCode = _asString(json['uf']);

    return AddressLookupResult(
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
}
