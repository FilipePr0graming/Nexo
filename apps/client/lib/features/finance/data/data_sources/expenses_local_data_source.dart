import '../../../../core/storage/local_json_store.dart';
import '../../models/expense_model.dart';

class ExpensesLocalDataSource {
  ExpensesLocalDataSource(this._store);

  static const String _storageKey = 'nexo.cache.expenses';

  final LocalJsonStore _store;

  Future<List<ExpenseModel>> fetchAll() async {
    final records = await _store.readList(_storageKey);
    return records.map(ExpenseModel.fromJson).toList(growable: false);
  }

  Future<void> saveAll(List<ExpenseModel> expenses) async {
    await _store.writeList(
      _storageKey,
      expenses.map((expense) => expense.toJson()).toList(growable: false),
    );
  }
}
