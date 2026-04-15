import '../../models/expense_model.dart';
import '../data_sources/expenses_local_data_source.dart';
import '../data_sources/expenses_remote_data_source.dart';

class ExpensesRepository {
  ExpensesRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final ExpensesLocalDataSource localDataSource;
  final ExpensesRemoteDataSource remoteDataSource;

  bool get isRemoteEnabled => remoteDataSource.isEnabled;

  Future<List<ExpenseModel>> loadLocal() {
    return localDataSource.fetchAll();
  }

  Future<List<ExpenseModel>> refreshFromRemote() async {
    final expenses = await remoteDataSource.fetchAll();
    if (expenses.isNotEmpty || isRemoteEnabled) {
      await localDataSource.saveAll(expenses);
    }
    return expenses;
  }

  Future<void> cacheAll(List<ExpenseModel> expenses) {
    return localDataSource.saveAll(expenses);
  }

  Future<ExpenseModel> upsert(ExpenseModel expense) {
    return remoteDataSource.upsert(expense);
  }
}
