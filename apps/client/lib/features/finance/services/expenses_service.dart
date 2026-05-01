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
    await createMissingRecurringExpenses();
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

  Future<int> createMissingRecurringExpenses({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final weekLimit = today.add(const Duration(days: 7));
    final recurringGroups = <String, List<ExpenseModel>>{};

    for (final expense in _expenses) {
      if (expense.recurrence == null) {
        continue;
      }

      recurringGroups
          .putIfAbsent(_recurringKey(expense), () => <ExpenseModel>[])
          .add(expense);
    }

    var created = 0;
    for (final group in recurringGroups.values) {
      group
          .sort((left, right) => right.expenseDate.compareTo(left.expenseDate));
      final baseExpense = group.first;
      final nextDate = _nextExpenseDate(baseExpense);

      if (nextDate.isAfter(weekLimit) || _hasExpenseForDay(group, nextDate)) {
        continue;
      }

      await createExpense(
        title: baseExpense.title,
        category: baseExpense.category,
        subcategory: baseExpense.subcategory,
        amount: baseExpense.amount,
        scope: baseExpense.scope,
        accountName: baseExpense.accountName,
        expenseDate: nextDate.toUtc(),
        recurrence: baseExpense.recurrence,
        notes: 'Conta gerada automaticamente pela recorrencia.',
      );
      created += 1;
    }

    return created;
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

  static String _recurringKey(ExpenseModel expense) {
    return [
      expense.title.trim().toLowerCase(),
      expense.category.trim().toLowerCase(),
      expense.scope.name,
      expense.accountName.trim().toLowerCase(),
      expense.recurrence,
      expense.amount.toStringAsFixed(2),
    ].join('|');
  }

  static DateTime _nextExpenseDate(ExpenseModel expense) {
    final months = expense.recurrence == 'annual' ? 12 : 1;
    return _addMonths(expense.expenseDate.toLocal(), months);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final targetDay = date.day > maxDay ? maxDay : date.day;

    return DateTime(
      targetYear,
      normalizedMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static bool _hasExpenseForDay(List<ExpenseModel> expenses, DateTime date) {
    return expenses.any((expense) {
      final expenseDate = expense.expenseDate.toLocal();
      return expenseDate.year == date.year &&
          expenseDate.month == date.month &&
          expenseDate.day == date.day;
    });
  }
}
