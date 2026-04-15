import '../../../../core/storage/local_json_store.dart';
import '../../models/client_model.dart';

class ClientsLocalDataSource {
  ClientsLocalDataSource(this._store);

  static const String _storageKey = 'nexo.cache.clients';

  final LocalJsonStore _store;

  Future<List<ClientModel>> fetchAll() async {
    final records = await _store.readList(_storageKey);
    return records.map(ClientModel.fromJson).toList(growable: false);
  }

  Future<void> saveAll(List<ClientModel> clients) async {
    await _store.writeList(
      _storageKey,
      clients.map((client) => client.toJson()).toList(growable: false),
    );
  }
}
