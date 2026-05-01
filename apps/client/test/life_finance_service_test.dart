import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/core/services/life_finance_service.dart';
import 'package:nexo_client/features/finance/models/expense_model.dart';
import 'package:nexo_client/features/finance/models/sale_model.dart';

void main() {
  test('calcula dinheiro livre, travado e compromissos do dia', () {
    final now = DateTime(2026, 5, 1, 12);
    final summary = LifeFinanceService.summarize(
      now: now,
      sales: [
        _sale(
          id: 'sale-1',
          gross: 5500,
          net: 5500,
          owner: 3850,
          daniel: 1650,
          installments: 1,
          status: SaleStatus.received,
          expectedDate: now,
        ),
      ],
      expenses: [
        _expense(
          id: 'expense-1',
          amount: 1000,
          scope: ExpenseScope.business,
          date: now,
        ),
      ],
    );

    expect(summary.confirmedEntries, 5500);
    expect(summary.committedMoney, 1650);
    expect(summary.lockedMoney, 1650);
    expect(summary.freeMoney, 2850);
    expect(summary.realProfit, 2850);
    expect(summary.partner.remaining, 1650);
  });

  test('mostra proximos 7 dias, cliente atrasado e casa paga pela empresa', () {
    final now = DateTime(2026, 5, 1, 12);
    final summary = LifeFinanceService.summarize(
      now: now,
      sales: [
        _sale(
          id: 'sale-open',
          gross: 1200,
          net: 1200,
          owner: 1200,
          daniel: 0,
          status: SaleStatus.pending,
          expectedDate: now.add(const Duration(days: 3)),
        ),
        _sale(
          id: 'sale-late',
          gross: 800,
          net: 800,
          owner: 800,
          daniel: 0,
          status: SaleStatus.pending,
          expectedDate: now.subtract(const Duration(days: 1)),
        ),
      ],
      expenses: [
        _expense(
          id: 'house',
          amount: 300,
          scope: ExpenseScope.personal,
          accountName: 'Conta empresa',
          date: now.add(const Duration(days: 2)),
        ),
      ],
    );

    expect(summary.toReceive7Days, 1200);
    expect(summary.toPay7Days, 300);
    expect(summary.housePaidByCompany, 300);
    expect(summary.alerts.any((alert) => alert.title == 'Cliente atrasado'),
        isTrue);
    expect(
        summary.alerts.any((alert) => alert.title == 'Conta vencendo'), isTrue);
  });

  test('abatimento pago ao Daniel reduz dinheiro comprometido', () {
    final now = DateTime(2026, 5, 1, 12);
    final summary = LifeFinanceService.summarize(
      now: now,
      sales: [
        _sale(
          id: 'sale-daniel',
          gross: 5500,
          net: 5500,
          owner: 3850,
          daniel: 1650,
          status: SaleStatus.received,
          expectedDate: now,
        ),
      ],
      expenses: [
        _expense(
          id: 'daniel-paid',
          amount: 800,
          scope: ExpenseScope.business,
          date: now,
          title: 'Pagamento Daniel',
          category: 'Socio',
        ),
      ],
    );

    expect(summary.partner.totalToPay, 1650);
    expect(summary.partner.paid, 800);
    expect(summary.partner.remaining, 850);
    expect(summary.committedMoney, 850);
    expect(summary.freeMoney, 3850);
  });

  test('gera modo hoje, previsao e sugestao de divisao', () {
    final now = DateTime(2026, 5, 1, 12);
    final summary = LifeFinanceService.summarize(
      now: now,
      sales: [
        _sale(
          id: 'received',
          gross: 2000,
          net: 2000,
          owner: 2000,
          daniel: 0,
          status: SaleStatus.received,
          expectedDate: now,
        ),
        _sale(
          id: 'pending',
          gross: 1500,
          net: 1500,
          owner: 1500,
          daniel: 0,
          status: SaleStatus.pending,
          expectedDate: now.add(const Duration(days: 2)),
        ),
      ],
      expenses: [
        _expense(
          id: 'bill',
          amount: 1000,
          scope: ExpenseScope.business,
          date: now.add(const Duration(days: 3)),
        ),
      ],
    );

    expect(summary.todayActions.any((item) => item.title == 'Cobrar clientes'),
        isTrue);
    expect(summary.forecasts.map((item) => item.days), [7, 15, 30]);
    expect(summary.forecasts.first.projectedMoney, 1500);
    expect(summary.incomeSuggestions.first.title, 'Pagar primeiro');
    expect(summary.incomeSuggestions.first.amount, 1000);
  });

  test('identifica cliente que atrasa e alerta impacto', () {
    final now = DateTime(2026, 5, 1, 12);
    final summary = LifeFinanceService.summarize(
      now: now,
      sales: [
        _sale(
          id: 'late-1',
          gross: 900,
          net: 900,
          owner: 900,
          daniel: 0,
          status: SaleStatus.pending,
          expectedDate: now.subtract(const Duration(days: 5)),
        ),
        _sale(
          id: 'late-2',
          gross: 700,
          net: 700,
          owner: 700,
          daniel: 0,
          status: SaleStatus.late,
          expectedDate: now.subtract(const Duration(days: 2)),
        ),
      ],
      expenses: const [],
    );

    expect(summary.clientInsights.first.clientName, 'Cliente');
    expect(summary.clientInsights.first.lateCount, 2);
    expect(summary.clientInsights.first.keep, isFalse);
    expect(
      summary.alerts.any((alert) => alert.title == 'Cliente para revisar'),
      isTrue,
    );
  });
}

SaleModel _sale({
  required String id,
  required double gross,
  required double net,
  required double owner,
  required double daniel,
  required SaleStatus status,
  required DateTime expectedDate,
  int installments = 1,
}) {
  final now = DateTime(2026, 5, 1, 12);
  return SaleModel(
    id: id,
    clientName: 'Cliente',
    serviceName: 'Projeto',
    grossAmount: gross,
    platform: 'Pix direto',
    paymentMethod: 'Pix',
    installments: installments,
    saleDate: now,
    expectedDate: expectedDate,
    receivedDate: status == SaleStatus.received ? now : null,
    status: status,
    platformFee: 0,
    paymentFee: 0,
    netAmount: net,
    hasDanielParticipation: daniel > 0,
    danielPercent: daniel > 0 ? 30 : 0,
    danielValue: daniel,
    ownerAmount: owner,
    createdAt: now,
    updatedAt: now,
  );
}

ExpenseModel _expense({
  required String id,
  required double amount,
  required ExpenseScope scope,
  required DateTime date,
  String accountName = 'Conta empresa',
  String title = 'Conta',
  String category = 'Geral',
}) {
  final now = DateTime(2026, 5, 1, 12);
  return ExpenseModel(
    id: id,
    title: title,
    category: category,
    amount: amount,
    scope: scope,
    accountName: accountName,
    expenseDate: date,
    createdAt: now,
    updatedAt: now,
  );
}
