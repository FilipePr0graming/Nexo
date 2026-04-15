enum ExpenseScope {
  business,
  personal,
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.scope,
    required this.accountName,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.subcategory,
    this.recurrence,
  });

  final String id;
  final String title;
  final String category;
  final String? subcategory;
  final double amount;
  final ExpenseScope scope;
  final String accountName;
  final DateTime expenseDate;
  final String? recurrence;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      subcategory: json['subcategory'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      scope: _scopeFromStorage(json['scope'] as String?),
      accountName: (json['account_name'] as String?) ?? '',
      expenseDate: DateTime.parse(
        (json['expense_date'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      recurrence: json['recurrence'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'scope': _scopeToStorage(scope),
      'account_name': accountName,
      'expense_date': expenseDate.toUtc().toIso8601String(),
      'recurrence': recurrence,
      'notes': notes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static ExpenseScope _scopeFromStorage(String? value) {
    return switch (value) {
      'personal' => ExpenseScope.personal,
      _ => ExpenseScope.business,
    };
  }

  static String _scopeToStorage(ExpenseScope value) {
    return switch (value) {
      ExpenseScope.business => 'business',
      ExpenseScope.personal => 'personal',
    };
  }
}

extension ExpenseScopeLabel on ExpenseScope {
  String get label {
    return switch (this) {
      ExpenseScope.business => 'Empresa',
      ExpenseScope.personal => 'Pessoal',
    };
  }
}
