import '../../models/address_lookup_result.dart';
import '../lookup_exception.dart';
import 'lookup_formatters.dart';

class AddressLookupParser {
  const AddressLookupParser();

  AddressLookupResult parse(Map<String, dynamic> json) {
    if (json['erro'] == true || json['erro'] == 'true') {
      throw const LookupException('CEP nao encontrado.');
    }

    return AddressLookupResult(
      zipCode: LookupFormatters.formatZipCode(
        LookupFormatters.cleanedValue(json['cep']),
      ),
      street: LookupFormatters.cleanedValue(json['logradouro']) ?? '',
      neighborhood: LookupFormatters.cleanedValue(json['bairro']) ?? '',
      city: LookupFormatters.cleanedValue(json['localidade']) ?? '',
      stateCode:
          (LookupFormatters.cleanedValue(json['uf']) ?? '').toUpperCase(),
    );
  }
}
