import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/lookup_exceptions.dart';

class CepLookupRemoteDataSource {
  CepLookupRemoteDataSource({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchByCep(String cepDigitsOnly) async {
    final uri = Uri.parse('https://viacep.com.br/ws/$cepDigitsOnly/json/');

    http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const LookupRequestException(
        'Nao foi possivel consultar o CEP agora. Verifique sua conexao.',
      );
    }

    if (response.statusCode == 404) {
      throw const LookupNotFoundException('CEP nao encontrado.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LookupRequestException(
        'Nao foi possivel consultar o CEP agora. Tente novamente em instantes.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const LookupRequestException('Resposta invalida ao consultar CEP.');
    }

    return Map<String, dynamic>.from(decoded);
  }
}
