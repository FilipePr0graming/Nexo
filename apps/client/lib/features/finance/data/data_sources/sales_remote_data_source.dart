import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/sale_model.dart';

class SalesRemoteDataSource {
  SalesRemoteDataSource(this._client);

  final SupabaseClient? _client;

  bool get isEnabled => _client != null;

  Future<List<SaleModel>> fetchAll() async {
    if (_client == null) {
      return const [];
    }

    final response = await _client
        .from('payments')
        .select()
        .order('sale_date', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(SaleModel.fromJson)
        .toList(growable: false);
  }

  Future<SaleModel> upsert(SaleModel sale) async {
    if (_client == null) {
      return sale;
    }

    final response = await _client
        .from('payments')
        .upsert(sale.toJson(), onConflict: 'id')
        .select()
        .single();

    return SaleModel.fromJson(response);
  }
}
