import '../data/lookup_exception.dart';
import '../data/repositories/client_autofill_repository.dart';
import '../models/address_lookup_result.dart';
import '../models/company_lookup_result.dart';

class ClientAutofillService {
  ClientAutofillService(this._repository);

  final ClientAutofillRepository _repository;

  Future<CompanyLookupResult> lookupCompany(String rawDocument) async {
    final cnpj = _digitsOnly(rawDocument);
    if (cnpj.length != 14) {
      throw const LookupException(
        'Informe um CNPJ valido com 14 digitos.',
      );
    }

    return _repository.lookupCompany(cnpj);
  }

  Future<AddressLookupResult> lookupAddress(String rawZipCode) async {
    final zipCode = _digitsOnly(rawZipCode);
    if (zipCode.length != 8) {
      throw const LookupException(
        'Informe um CEP valido com 8 digitos.',
      );
    }

    return _repository.lookupAddress(zipCode);
  }

  void dispose() {
    _repository.dispose();
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
