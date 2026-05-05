import 'package:flutter/foundation.dart';

import '../../../core/utils/id_generator.dart';
import '../../../core/utils/money_utils.dart';
import '../models/expense_details.dart';
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
    ExpensePaymentStatus status = ExpensePaymentStatus.paid,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? paymentDate,
    ExpenseRecurrenceKind? recurrenceKind,
    int? fixedDueDay,
    int? installmentTotal,
    int? installmentCurrent,
    String? wallet,
    String? person,
    String? priority,
    String? plannedPaymentMethod,
    double? cardOriginalAmount,
    double? cardPaidWithInterest,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final details = ExpenseDetails(
      status: status,
      originalAmount: amount,
      paidAmount:
          paidAmount ?? (status == ExpensePaymentStatus.paid ? amount : 0),
      dueDate: dueDate ?? expenseDate,
      paymentDate: paymentDate ??
          (status == ExpensePaymentStatus.paid ? expenseDate : null),
      recurrenceKind: recurrenceKind ??
          switch (recurrence) {
            'monthly' => ExpenseRecurrenceKind.monthly,
            'annual' => ExpenseRecurrenceKind.annual,
            _ => ExpenseRecurrenceKind.once,
          },
      fixedDueDay: fixedDueDay,
      installmentTotal: installmentTotal,
      installmentCurrent: installmentCurrent,
      wallet: wallet ?? ExpenseDetails.walletFromAccount(accountName),
      person: person,
      priority: priority,
      plannedPaymentMethod: plannedPaymentMethod,
      cardOriginalAmount: cardOriginalAmount,
      cardPaidWithInterest: cardPaidWithInterest,
      changeHistory: [
        'Criado em ${timestamp.toLocal().toIso8601String()}',
      ],
      humanNote: notes,
    );
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
      notes: ExpenseDetails.encode(details: details, note: notes),
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

  Future<void> updateExpense(ExpenseModel expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now().toUtc());
    _replace(updated);
    await _repository.cacheAll(_expenses);
    notifyListeners();

    try {
      final saved = await _repository.upsert(updated);
      _replace(saved);
      await _repository.cacheAll(_expenses);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Gasto atualizado localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateExpenseDetails(
    ExpenseModel expense,
    ExpenseDetails details, {
    String? note,
  }) {
    final nextDetails = details.copyWith(
      changeHistory: [
        ...details.changeHistory,
        'Atualizado em ${DateTime.now().toLocal().toIso8601String()}',
      ],
    );
    return updateExpense(
      expense.copyWith(
        amount: MoneyUtils.roundMoney(nextDetails.originalAmount),
        expenseDate: nextDetails.dueDate.toUtc(),
        accountName: nextDetails.wallet ?? expense.accountName,
        recurrence: nextDetails.recurrenceKind.legacyStorage,
        notes: ExpenseDetails.encode(details: nextDetails, note: note),
      ),
    );
  }

  Future<void> markAsPaid(ExpenseModel expense, {double? paidAmount}) {
    final details = ExpenseDetails.fromExpense(expense);
    final amount = paidAmount ?? details.originalAmount;
    return updateExpenseDetails(
      expense,
      details.copyWith(
        status: ExpensePaymentStatus.paid,
        paidAmount: amount,
        paymentDate: DateTime.now().toUtc(),
      ),
      note: details.humanNote,
    );
  }

  Future<void> markPartial(ExpenseModel expense, double paidAmount) {
    final details = ExpenseDetails.fromExpense(expense);
    return updateExpenseDetails(
      expense,
      details.copyWith(
        status: ExpensePaymentStatus.partial,
        paidAmount: paidAmount,
        paymentDate: DateTime.now().toUtc(),
      ),
      note: details.humanNote,
    );
  }

  Future<void> deleteExpense(String id) async {
    final previous = _expenses;
    _expenses =
        _expenses.where((expense) => expense.id != id).toList(growable: false);
    await _repository.cacheAll(_expenses);
    notifyListeners();

    try {
      await _repository.deleteById(id);
      _errorMessage = null;
    } catch (_) {
      _expenses = previous;
      await _repository.cacheAll(_expenses);
      _errorMessage = 'Nao foi possivel excluir gasto agora.';
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
