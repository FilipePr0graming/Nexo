import 'dart:convert';

import '../../../core/utils/money_utils.dart';
import 'expense_model.dart';

enum ExpensePaymentStatus {
  paid,
  pending,
  partial,
  late,
  planned,
  forecast,
}

extension ExpensePaymentStatusLabel on ExpensePaymentStatus {
  String get label {
    return switch (this) {
      ExpensePaymentStatus.paid => 'Pago',
      ExpensePaymentStatus.pending => 'Pendente',
      ExpensePaymentStatus.partial => 'Parcial',
      ExpensePaymentStatus.late => 'Atrasado',
      ExpensePaymentStatus.planned => 'Planejado',
      ExpensePaymentStatus.forecast => 'Previsto',
    };
  }

  String get storage {
    return switch (this) {
      ExpensePaymentStatus.paid => 'paid',
      ExpensePaymentStatus.pending => 'pending',
      ExpensePaymentStatus.partial => 'partial',
      ExpensePaymentStatus.late => 'late',
      ExpensePaymentStatus.planned => 'planned',
      ExpensePaymentStatus.forecast => 'forecast',
    };
  }
}

enum ExpenseRecurrenceKind {
  once,
  monthly,
  annual,
  installment,
}

extension ExpenseRecurrenceKindLabel on ExpenseRecurrenceKind {
  String get label {
    return switch (this) {
      ExpenseRecurrenceKind.once => 'Unica',
      ExpenseRecurrenceKind.monthly => 'Mensal',
      ExpenseRecurrenceKind.annual => 'Anual',
      ExpenseRecurrenceKind.installment => 'Parcelada',
    };
  }

  String? get legacyStorage {
    return switch (this) {
      ExpenseRecurrenceKind.monthly => 'monthly',
      ExpenseRecurrenceKind.annual => 'annual',
      _ => null,
    };
  }
}

class ExpenseDetails {
  const ExpenseDetails({
    required this.status,
    required this.originalAmount,
    required this.paidAmount,
    required this.dueDate,
    required this.recurrenceKind,
    this.paymentDate,
    this.fixedDueDay,
    this.installmentTotal,
    this.installmentCurrent,
    this.wallet,
    this.person,
    this.priority,
    this.plannedPaymentMethod,
    this.cardOriginalAmount,
    this.cardPaidWithInterest,
    this.cardDueDate,
    this.cardPaymentDate,
    this.changeHistory = const [],
    this.humanNote,
  });

  final ExpensePaymentStatus status;
  final double originalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final ExpenseRecurrenceKind recurrenceKind;
  final DateTime? paymentDate;
  final int? fixedDueDay;
  final int? installmentTotal;
  final int? installmentCurrent;
  final String? wallet;
  final String? person;
  final String? priority;
  final String? plannedPaymentMethod;
  final double? cardOriginalAmount;
  final double? cardPaidWithInterest;
  final DateTime? cardDueDate;
  final DateTime? cardPaymentDate;
  final List<String> changeHistory;
  final String? humanNote;

  double get pendingAmount {
    return MoneyUtils.roundMoney(
        (originalAmount - paidAmount).clamp(0, double.infinity).toDouble());
  }

  double get cashImpact {
    return switch (status) {
      ExpensePaymentStatus.paid => originalAmount,
      ExpensePaymentStatus.partial => paidAmount,
      ExpensePaymentStatus.late => paidAmount,
      ExpensePaymentStatus.pending => 0,
      ExpensePaymentStatus.planned => 0,
      ExpensePaymentStatus.forecast => 0,
    };
  }

  bool get isOpen {
    return switch (status) {
      ExpensePaymentStatus.pending ||
      ExpensePaymentStatus.partial ||
      ExpensePaymentStatus.late ||
      ExpensePaymentStatus.planned =>
        true,
      ExpensePaymentStatus.paid || ExpensePaymentStatus.forecast => false,
    };
  }

  bool get isPlannedPurchase => status == ExpensePaymentStatus.planned;

  double get interestAmount {
    final original = cardOriginalAmount ?? originalAmount;
    final paid = cardPaidWithInterest ?? paidAmount;
    return MoneyUtils.roundMoney(
        (paid - original).clamp(0, double.infinity).toDouble());
  }

  double get interestPercent {
    final original = cardOriginalAmount ?? originalAmount;
    if (original <= 0) {
      return 0;
    }
    return MoneyUtils.roundMoney((interestAmount / original) * 100);
  }

  ExpenseDetails copyWith({
    ExpensePaymentStatus? status,
    double? originalAmount,
    double? paidAmount,
    DateTime? dueDate,
    ExpenseRecurrenceKind? recurrenceKind,
    DateTime? paymentDate,
    int? fixedDueDay,
    int? installmentTotal,
    int? installmentCurrent,
    String? wallet,
    String? person,
    String? priority,
    String? plannedPaymentMethod,
    double? cardOriginalAmount,
    double? cardPaidWithInterest,
    DateTime? cardDueDate,
    DateTime? cardPaymentDate,
    List<String>? changeHistory,
    String? humanNote,
  }) {
    return ExpenseDetails(
      status: status ?? this.status,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      recurrenceKind: recurrenceKind ?? this.recurrenceKind,
      paymentDate: paymentDate ?? this.paymentDate,
      fixedDueDay: fixedDueDay ?? this.fixedDueDay,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      installmentCurrent: installmentCurrent ?? this.installmentCurrent,
      wallet: wallet ?? this.wallet,
      person: person ?? this.person,
      priority: priority ?? this.priority,
      plannedPaymentMethod: plannedPaymentMethod ?? this.plannedPaymentMethod,
      cardOriginalAmount: cardOriginalAmount ?? this.cardOriginalAmount,
      cardPaidWithInterest: cardPaidWithInterest ?? this.cardPaidWithInterest,
      cardDueDate: cardDueDate ?? this.cardDueDate,
      cardPaymentDate: cardPaymentDate ?? this.cardPaymentDate,
      changeHistory: changeHistory ?? this.changeHistory,
      humanNote: humanNote ?? this.humanNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.storage,
      'original_amount': originalAmount,
      'paid_amount': paidAmount,
      'due_date': dueDate.toUtc().toIso8601String(),
      'payment_date': paymentDate?.toUtc().toIso8601String(),
      'recurrence_kind': recurrenceKind.name,
      'fixed_due_day': fixedDueDay,
      'installment_total': installmentTotal,
      'installment_current': installmentCurrent,
      'wallet': wallet,
      'person': person,
      'priority': priority,
      'planned_payment_method': plannedPaymentMethod,
      'card_original_amount': cardOriginalAmount,
      'card_paid_with_interest': cardPaidWithInterest,
      'card_due_date': cardDueDate?.toUtc().toIso8601String(),
      'card_payment_date': cardPaymentDate?.toUtc().toIso8601String(),
      'change_history': changeHistory,
      'human_note': humanNote,
    };
  }

  factory ExpenseDetails.fromMap(
    Map<String, dynamic> map, {
    required ExpenseModel fallback,
  }) {
    final status = _statusFromStorage(map['status'] as String?);
    return ExpenseDetails(
      status: status,
      originalAmount:
          (map['original_amount'] as num?)?.toDouble() ?? fallback.amount,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ??
          (status == ExpensePaymentStatus.paid ? fallback.amount : 0),
      dueDate: _parseDate(map['due_date']) ?? fallback.expenseDate,
      paymentDate: _parseDate(map['payment_date']),
      recurrenceKind: _recurrenceFromStorage(
        map['recurrence_kind'] as String?,
        fallback.recurrence,
      ),
      fixedDueDay: (map['fixed_due_day'] as num?)?.toInt(),
      installmentTotal: (map['installment_total'] as num?)?.toInt(),
      installmentCurrent: (map['installment_current'] as num?)?.toInt(),
      wallet: map['wallet'] as String?,
      person: map['person'] as String?,
      priority: map['priority'] as String?,
      plannedPaymentMethod: map['planned_payment_method'] as String?,
      cardOriginalAmount: (map['card_original_amount'] as num?)?.toDouble(),
      cardPaidWithInterest:
          (map['card_paid_with_interest'] as num?)?.toDouble(),
      cardDueDate: _parseDate(map['card_due_date']),
      cardPaymentDate: _parseDate(map['card_payment_date']),
      changeHistory: (map['change_history'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      humanNote: map['human_note'] as String?,
    );
  }

  factory ExpenseDetails.fromExpense(ExpenseModel expense) {
    final decoded = _decode(expense.notes);
    if (decoded != null) {
      return ExpenseDetails.fromMap(decoded, fallback: expense);
    }

    final expenseDay = DateTime(
      expense.expenseDate.toLocal().year,
      expense.expenseDate.toLocal().month,
      expense.expenseDate.toLocal().day,
    );
    final createdDay = DateTime(
      expense.createdAt.toLocal().year,
      expense.createdAt.toLocal().month,
      expense.createdAt.toLocal().day,
    );
    final isFuture = expenseDay.isAfter(createdDay);
    return ExpenseDetails(
      status:
          isFuture ? ExpensePaymentStatus.pending : ExpensePaymentStatus.paid,
      originalAmount: expense.amount,
      paidAmount: isFuture ? 0 : expense.amount,
      dueDate: expense.expenseDate,
      paymentDate: isFuture ? null : expense.expenseDate,
      recurrenceKind: _recurrenceFromStorage(null, expense.recurrence),
      wallet: walletFromAccount(expense.accountName),
      humanNote: expense.notes,
    );
  }

  static String encode({
    required ExpenseDetails details,
    String? note,
  }) {
    final payload = details.toMap()
      ..['human_note'] = note?.trim().isEmpty == true ? null : note?.trim();
    return 'NEXO_META:${jsonEncode(payload)}';
  }

  static String? plainNote(String? notes) {
    final decoded = _decode(notes);
    if (decoded == null) {
      return notes;
    }
    return decoded['human_note'] as String?;
  }

  static String walletFromAccount(String accountName) {
    final lower = accountName.toLowerCase();
    if (lower.contains('btg')) {
      return 'BTG';
    }
    if (lower.contains('cora') && lower.contains('cart')) {
      return 'Cora Cartao';
    }
    if (lower.contains('cora') || lower.contains('pix empresa')) {
      return 'Cora Pix';
    }
    if (lower.contains('dinheiro')) {
      return 'Dinheiro';
    }
    if (lower.contains('pessoal') || lower.contains('empresa')) {
      return 'Outro';
    }
    return 'Indefinido';
  }

  static Map<String, dynamic>? _decode(String? notes) {
    final value = notes?.trim() ?? '';
    if (!value.startsWith('NEXO_META:')) {
      return null;
    }
    try {
      return jsonDecode(value.substring('NEXO_META:'.length))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static ExpensePaymentStatus _statusFromStorage(String? value) {
    return switch (value) {
      'paid' => ExpensePaymentStatus.paid,
      'partial' => ExpensePaymentStatus.partial,
      'late' => ExpensePaymentStatus.late,
      'planned' => ExpensePaymentStatus.planned,
      'forecast' => ExpensePaymentStatus.forecast,
      _ => ExpensePaymentStatus.pending,
    };
  }

  static ExpenseRecurrenceKind _recurrenceFromStorage(
    String? value,
    String? legacy,
  ) {
    return switch (value ?? legacy) {
      'monthly' => ExpenseRecurrenceKind.monthly,
      'annual' => ExpenseRecurrenceKind.annual,
      'installment' => ExpenseRecurrenceKind.installment,
      _ => ExpenseRecurrenceKind.once,
    };
  }

  static DateTime? _parseDate(Object? value) {
    final raw = value as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
