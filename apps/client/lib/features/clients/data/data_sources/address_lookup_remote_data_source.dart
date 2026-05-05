import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/public_lookup_endpoints.dart';
import '../../models/address_lookup_result.dart';
import '../lookup_exception.dart';
import '../parsers/address_lookup_parser.dart';

class AddressLookupRemoteDataSource {
  AddressLookupRemoteDataSource({
    http.Client? httpClient,
    AddressLookupParser? parser,
  })  : _httpClient = httpClient ?? http.Client(),
        _parser = parser ?? const AddressLookupParser();

  final http.Client _httpClient;
  final AddressLookupParser _parser;

  Future<AddressLookupResult> fetchByZipCode(String zipCode) async {
    try {
      final response = await _httpClient.get(
        PublicLookupEndpoints.addressByZipCode(zipCode),
        headers: const {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return _parser.parse(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 400) {
        throw const LookupException(
          'Informe um CEP valido com 8 digitos.',
        );
      }

      throw const LookupException(
        'Nao foi possivel consultar o CEP agora.',
      );
    } on LookupException {
      rethrow;
    } catch (_) {
      throw const LookupException(
        'Nao foi possivel consultar o CEP agora.',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
