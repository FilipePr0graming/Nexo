import 'package:flutter/foundation.dart';

import '../../../core/utils/id_generator.dart';
import '../data/repositories/expenses_repository.dart';
import '../models/expense_model.dart';

class ExpensesService extends ChangeNotifier {
  ExpensesService(this._repository);

  final ExpensesRepository _repository;

  List<ExpenseModel> _expenses = const [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _initialized = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    _expenses = await _repository.loadLocal();
    _isLoading = false;
    notifyListeners();

    await refresh();
  }

  Future<void> refresh() async {
    if (_isSyncing || !_repository.isRemoteEnabled) {
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.refreshFromRemote();
    } catch (_) {
      _errorMessage = 'Nao foi possivel atualizar gastos agora.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> createExpense({
    required String title,
    required String category,
    String? subcategory,
    required double amount,
    required ExpenseScope scope,
    required String accountName,
    required DateTime expenseDate,
    String? recurrence,
    String? notes,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final expense = ExpenseModel(
      id: IdGenerator.next('expense'),
      title: title.trim(),
      category: category,
      subcategory: _emptyToNull(subcategory),
      amount: amount,
      scope: scope,
      accountName: accountName,
      expenseDate: expenseDate,
      recurrence: _emptyToNull(recurrence),
      notes: _emptyToNull(notes),
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    _expenses = [expense, ..._expenses]..sort(_sortByDate);
    await _repository.cacheAll(_expenses);
    notifyListeners();

    try {
      final saved = await _repository.upsert(expense);
      _replace(saved);
      await _repository.cacheAll(_expenses);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Gasto salvo localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  int _sortByDate(ExpenseModel left, ExpenseModel right) {
    return right.expenseDate.compareTo(left.expenseDate);
  }

  void _replace(ExpenseModel updated) {
    _expenses = _expenses
        .map((expense) => expense.id == updated.id ? updated : expense)
        .toList(growable: false)
      ..sort(_sortByDate);
  }

  static String? _emptyToNull(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
