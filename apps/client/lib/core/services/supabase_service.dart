import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient? _client;

  bool get isEnabled => _client != null;
  SupabaseClient? get client => _client;
  User? get currentUser => _client?.auth.currentUser;

  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) {
    final client = _client;
    if (client == null) {
      return Future<AuthResponse?>.value(null);
    }

    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) {
    final client = _client;
    if (client == null) {
      return Future<AuthResponse?>.value(null);
    }

    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  SupabaseQueryBuilder from(String table) {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase nao foi inicializado.');
    }

    return client.from(table);
  }

  Future<List<Map<String, dynamic>>> fetchAll(
    String table, {
    String orderBy = 'updated_at',
    bool ascending = false,
  }) async {
    final client = _client;
    if (client == null) {
      return const [];
    }

    final response =
        await client.from(table).select().order(orderBy, ascending: ascending);

    return response.cast<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>?> upsert(
    String table,
    Map<String, dynamic> payload, {
    String onConflict = 'id',
  }) async {
    final client = _client;
    if (client == null) {
      return payload;
    }

    return client
        .from(table)
        .upsert(payload, onConflict: onConflict)
        .select()
        .single();
  }

  Future<void> deleteById(String table, String id) async {
    final client = _client;
    if (client == null) {
      return;
    }

    await client.from(table).delete().eq('id', id);
  }
}
