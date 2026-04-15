import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/expense_model.dart';

class ExpensesRemoteDataSource {
  ExpensesRemoteDataSource(this._client);

  final SupabaseClient? _client;

  bool get isEnabled => _client != null;

  Future<List<ExpenseModel>> fetchAll() async {
    if (_client == null) {
      return const [];
    }

    final response = await _client
        .from('expenses')
        .select()
        .order('expense_date', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(ExpenseModel.fromJson)
        .toList(growable: false);
  }

  Future<ExpenseModel> upsert(ExpenseModel expense) async {
    if (_client == null) {
      return expense;
    }

    final response = await _client
        .from('expenses')
        .upsert(expense.toJson(), onConflict: 'id')
        .select()
        .single();

    return ExpenseModel.fromJson(response);
  }
}
