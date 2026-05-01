import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/core/services/finance_calculator.dart';

void main() {
  test('Pix nao cobra taxa e liquida instantaneamente', () {
    final summary = FinanceCalculator.summarize(
      grossAmount: 1000,
      platformFee: 0,
      paymentMethod: 'Pix',
      hasDanielParticipation: false,
    );

    expect(summary.paymentFee, 0);
    expect(summary.netAmount, 1000);
    expect(summary.ownerAmount, 1000);
  });

  test('Cartao aplica taxa de 7 por cento', () {
    final summary = FinanceCalculator.summarize(
      grossAmount: 1000,
      platformFee: 0,
      paymentMethod: 'Cartao',
      hasDanielParticipation: false,
    );

    expect(summary.paymentFee, 70);
    expect(summary.netAmount, 930);
  });

  test('Daniel segue contrato base manual de 1650 em duas parcelas', () {
    expect(FinanceCalculator.validatesDanielBaseContract, isTrue);
    expect(FinanceCalculator.splitDanielDebt(1650), [800, 850]);
  });

  test('Caixa real considera entradas menos despesas e compromissos', () {
    final cash = FinanceCalculator.realCash(
      receivedEntries: [5500],
      expenses: [1000],
      commitments: [1650],
    );

    expect(cash, 2850);
  });
}
