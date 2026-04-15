import '../../../../core/storage/local_json_store.dart';
import '../../models/sale_model.dart';

class SalesLocalDataSource {
  SalesLocalDataSource(this._store);

  static const String _storageKey = 'nexo.cache.sales';

  final LocalJsonStore _store;

  Future<List<SaleModel>> fetchAll() async {
    final records = await _store.readList(_storageKey);
    return records.map(SaleModel.fromJson).toList(growable: false);
  }

  Future<void> saveAll(List<SaleModel> sales) async {
    await _store.writeList(
      _storageKey,
      sales.map((sale) => sale.toJson()).toList(growable: false),
    );
  }
}
