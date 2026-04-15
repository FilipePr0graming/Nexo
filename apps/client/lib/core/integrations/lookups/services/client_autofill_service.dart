import '../data_sources/cep_lookup_remote_data_source.dart';
import '../data_sources/cnpj_lookup_remote_data_source.dart';
import '../exceptions/lookup_exceptions.dart';
import '../models/address_lookup_result.dart';
import '../models/company_lookup_result.dart';
import '../parsers/brasil_api_cnpj_parser.dart';
import '../parsers/via_cep_parser.dart';

class ClientAutofillService {
  ClientAutofillService({
    required CnpjLookupRemoteDataSource cnpjDataSource,
    required CepLookupRemoteDataSource cepDataSource,
    BrasilApiCnpjParser? cnpjParser,
    ViaCepParser? cepParser,
  })  : _cnpjDataSource = cnpjDataSource,
        _cepDataSource = cepDataSource,
        _cnpjParser = cnpjParser ?? const BrasilApiCnpjParser(),
        _cepParser = cepParser ?? const ViaCepParser();

  final CnpjLookupRemoteDataSource _cnpjDataSource;
  final CepLookupRemoteDataSource _cepDataSource;
  final BrasilApiCnpjParser _cnpjParser;
  final ViaCepParser _cepParser;

  Future<CompanyLookupResult> lookupCompanyByCnpj(String cnpj) async {
    final digits = _digitsOnly(cnpj);
    if (digits.length != 14) {
      throw const LookupValidationException('Informe um CNPJ valido.');
    }

    final json = await _cnpjDataSource.fetchByCnpj(digits);
    return _cnpjParser.parse(json);
  }

  Future<AddressLookupResult> lookupAddressByCep(String cep) async {
    final digits = _digitsOnly(cep);
    if (digits.length != 8) {
      throw const LookupValidationException('Informe um CEP valido.');
    }

    final json = await _cepDataSource.fetchByCep(digits);
    return _cepParser.parse(json);
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
