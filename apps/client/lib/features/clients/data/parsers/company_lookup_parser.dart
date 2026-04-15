import '../../models/company_lookup_result.dart';
import 'lookup_formatters.dart';

class CompanyLookupParser {
  const CompanyLookupParser();

  CompanyLookupResult parse(Map<String, dynamic> json) {
    final legalName = LookupFormatters.cleanedValue(json['razao_social']) ?? '';
    final tradeName =
        LookupFormatters.cleanedValue(json['nome_fantasia']) ?? legalName;

    return CompanyLookupResult(
      cnpj: LookupFormatters.formatCnpj(
        LookupFormatters.cleanedValue(json['cnpj']),
      ),
      legalName: legalName,
      tradeName: tradeName,
      zipCode: LookupFormatters.formatZipCode(
        LookupFormatters.cleanedValue(json['cep']),
      ),
      street: LookupFormatters.composeStreet(
        streetType:
            LookupFormatters.cleanedValue(json['descricao_tipo_de_logradouro']),
        streetName: LookupFormatters.cleanedValue(json['logradouro']),
      ),
      neighborhood: LookupFormatters.cleanedValue(json['bairro']) ?? '',
      city: LookupFormatters.cleanedValue(json['municipio']) ?? '',
      stateCode:
          (LookupFormatters.cleanedValue(json['uf']) ?? '').toUpperCase(),
      phone: LookupFormatters.formatPhone(
        LookupFormatters.cleanedValue(json['ddd_telefone_1']) ??
            LookupFormatters.cleanedValue(json['ddd_telefone_2']),
      ),
    );
  }
}
