import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/client_model.dart';

class ClientsRemoteDataSource {
  ClientsRemoteDataSource(this._client);

  final SupabaseClient? _client;

  bool get isEnabled => _client != null;

  Future<List<ClientModel>> fetchAll() async {
    if (_client == null) {
      return const [];
    }

    final response = await _client
        .from('clients')
        .select()
        .order('updated_at', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(ClientModel.fromJson)
        .toList(growable: false);
  }

  Future<ClientModel> upsert(ClientModel client) async {
    if (_client == null) {
      return client;
    }

    final response = await _client
        .from('clients')
        .upsert(client.toJson(), onConflict: 'id')
        .select()
        .single();

    return ClientModel.fromJson(response);
  }
}
