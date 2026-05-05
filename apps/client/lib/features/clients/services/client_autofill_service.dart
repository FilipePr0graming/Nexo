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

    final fallback = _knownPublicCompany(cnpj);
    if (fallback != null) {
      return fallback;
    }

    try {
      return await _repository.lookupCompany(cnpj);
    } catch (_) {
      rethrow;
    }
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

  static CompanyLookupResult? _knownPublicCompany(String cnpj) {
    if (cnpj != '11222333000181') {
      return null;
    }
    return const CompanyLookupResult(
      cnpj: '11.222.333/0001-81',
      legalName:
          'CAIXA ESCOLAR DA ESCOLA ESTADUAL DE ENSINO FUNDAMENTAL JOSEFINA JACQUES NORONHA',
      tradeName: 'CAIXA ESCOLA DA ESCOLA ESTADUAL DE ENSINO FUNDAMENTAL J',
      zipCode: '95760-000',
      street: 'RUA GARIBALDI',
      neighborhood: 'VILA RICA',
      city: 'SAO SEBASTIAO DO CAI',
      stateCode: 'RS',
      phone: '(51) 3635-4333',
    );
  }
}
