import '../../models/client_model.dart';
import '../data_sources/clients_local_data_source.dart';
import '../data_sources/clients_remote_data_source.dart';

class ClientsRepository {
  ClientsRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final ClientsLocalDataSource localDataSource;
  final ClientsRemoteDataSource remoteDataSource;

  bool get isRemoteEnabled => remoteDataSource.isEnabled;

  Future<List<ClientModel>> loadLocal() {
    return localDataSource.fetchAll();
  }

  Future<List<ClientModel>> refreshFromRemote() async {
    final clients = await remoteDataSource.fetchAll();
    if (clients.isNotEmpty || isRemoteEnabled) {
      await localDataSource.saveAll(clients);
    }
    return clients;
  }

  Future<void> cacheAll(List<ClientModel> clients) {
    return localDataSource.saveAll(clients);
  }

  Future<ClientModel> upsert(ClientModel client) {
    return remoteDataSource.upsert(client);
  }

  Future<void> deleteById(String id) {
    return remoteDataSource.deleteById(id);
  }
}
