import '../../models/sale_model.dart';
import '../data_sources/sales_local_data_source.dart';
import '../data_sources/sales_remote_data_source.dart';

class SalesRepository {
  SalesRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final SalesLocalDataSource localDataSource;
  final SalesRemoteDataSource remoteDataSource;

  bool get isRemoteEnabled => remoteDataSource.isEnabled;

  Future<List<SaleModel>> loadLocal() {
    return localDataSource.fetchAll();
  }

  Future<List<SaleModel>> refreshFromRemote() async {
    final sales = await remoteDataSource.fetchAll();
    if (sales.isNotEmpty || isRemoteEnabled) {
      await localDataSource.saveAll(sales);
    }
    return sales;
  }

  Future<void> cacheAll(List<SaleModel> sales) {
    return localDataSource.saveAll(sales);
  }

  Future<SaleModel> upsert(SaleModel sale) {
    return remoteDataSource.upsert(sale);
  }

  Future<void> deleteById(String id) {
    return remoteDataSource.deleteById(id);
  }
}
