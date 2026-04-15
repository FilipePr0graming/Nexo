import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/lookup_exceptions.dart';

class CnpjLookupRemoteDataSource {
  CnpjLookupRemoteDataSource({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchByCnpj(String cnpjDigitsOnly) async {
    final uri = Uri.parse(
      'https://brasilapi.com.br/api/cnpj/v1/$cnpjDigitsOnly',
    );

    http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const LookupRequestException(
        'Nao foi possivel consultar o CNPJ agora. Verifique sua conexao.',
      );
    }

    if (response.statusCode == 404) {
      throw const LookupNotFoundException('CNPJ nao encontrado.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LookupRequestException(
        'Nao foi possivel consultar o CNPJ agora. Tente novamente em instantes.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const LookupRequestException('Resposta invalida ao consultar CNPJ.');
    }

    return Map<String, dynamic>.from(decoded);
  }
}
