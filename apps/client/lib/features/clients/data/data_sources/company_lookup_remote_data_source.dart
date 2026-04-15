import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/public_lookup_endpoints.dart';
import '../../models/company_lookup_result.dart';
import '../lookup_exception.dart';
import '../parsers/company_lookup_parser.dart';

class CompanyLookupRemoteDataSource {
  CompanyLookupRemoteDataSource({
    http.Client? httpClient,
    CompanyLookupParser? parser,
  })  : _httpClient = httpClient ?? http.Client(),
        _parser = parser ?? const CompanyLookupParser();

  final http.Client _httpClient;
  final CompanyLookupParser _parser;

  Future<CompanyLookupResult> fetchByCnpj(String cnpj) async {
    try {
      final response = await _httpClient.get(
        PublicLookupEndpoints.companyByCnpj(cnpj),
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return _parser.parse(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 400) {
        throw const LookupException(
          'Confira o CNPJ e tente novamente.',
        );
      }

      if (response.statusCode == 404) {
        throw const LookupException('CNPJ nao encontrado.');
      }

      if (response.statusCode == 429) {
        throw const LookupException(
          'A consulta de CNPJ esta ocupada agora. Tente novamente em instantes.',
        );
      }

      throw const LookupException(
        'Nao foi possivel consultar o CNPJ agora.',
      );
    } on LookupException {
      rethrow;
    } catch (_) {
      throw const LookupException(
        'Nao foi possivel consultar o CNPJ agora.',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
