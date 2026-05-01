import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/services/finance_calculator.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/cards/nexo_quick_action_card.dart';
import '../../../../shared/components/lists/nexo_movement_list_item.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../models/expense_model.dart';
import '../../models/sale_model.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({
    super.key,
    required this.onNewSale,
    required this.onNewExpense,
  });

  final VoidCallback onNewSale;
  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    final salesService = services.sales;
    final expensesService = services.expenses;

    return AnimatedBuilder(
      animation: Listenable.merge([salesService, expensesService]),
      builder: (context, _) {
        final now = DateTime.now();
        final monthlySales = salesService.sales.where(
          (sale) =>
              sale.status == SaleStatus.received &&
              DateLabelUtils.isInCurrentMonth(sale.movementDate.toLocal(), now),
        );
        final monthlyExpenses = expensesService.expenses.where(
          (expense) => DateLabelUtils.isInCurrentMonth(
              expense.expenseDate.toLocal(), now),
        );

        final totalIn = monthlySales.fold<double>(
          0,
          (total, sale) => total + sale.netAmount,
        );
        final totalOut = monthlyExpenses.fold<double>(
          0,
          (total, expense) => total + expense.amount,
        );
        final commitments = monthlySales.fold<double>(
          0,
          (total, sale) => total + sale.danielValue,
        );
        final realProfit = FinanceCalculator.realCash(
          receivedEntries: monthlySales.map((sale) => sale.netAmount),
          expenses: monthlyExpenses.map((expense) => expense.amount),
          commitments: monthlySales.map((sale) => sale.danielValue),
        );

        final movements = <_FinanceMovement>[
          ...salesService.sales.map(
            (sale) => _FinanceMovement(
              title: sale.clientName,
              subtitle: 'Venda ${sale.platform}',
              amount: sale.ownerAmount,
              date: sale.movementDate.toLocal(),
              isExpense: false,
            ),
          ),
          ...expensesService.expenses.map(
            (expense) => _FinanceMovement(
              title: expense.title,
              subtitle: '${expense.category} | ${expense.scope.label}',
              amount: expense.amount,
              date: expense.expenseDate.toLocal(),
              isExpense: true,
            ),
          ),
        ]..sort((left, right) => right.date.compareTo(left.date));

        return NexoPageScaffold(
          title: 'Financeiro',
          subtitle: 'Entradas e gastos conectados com a persistencia real.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Entrou no mes',
                      value: MoneyUtils.format(totalIn),
                      footnote: 'Liquido recebido',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Saiu no mes',
                      value: MoneyUtils.format(totalOut),
                      footnote: 'Gastos totais',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Compromissos',
                      value: MoneyUtils.format(commitments),
                      footnote: 'Dividas nao automaticas',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Lucro real',
                      value: MoneyUtils.format(realProfit),
                      footnote: 'Entradas - gastos - compromissos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.xl),
              const NexoSectionHeader(title: 'Registrar agora'),
              const SizedBox(height: NexoSpacing.md),
              NexoQuickActionCard(
                icon: NexoIcons.newSale,
                title: 'Nova venda',
                caption: 'Abrir formulario rapido de venda.',
                onTap: onNewSale,
              ),
              const SizedBox(height: NexoSpacing.sm),
              NexoQuickActionCard(
                icon: NexoIcons.newExpense,
                title: 'Novo gasto',
                caption: 'Abrir formulario rapido de gasto.',
                onTap: onNewExpense,
              ),
              const SizedBox(height: NexoSpacing.xl),
              const NexoSectionHeader(title: 'Movimentos recentes'),
              const SizedBox(height: NexoSpacing.md),
              if (movements.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem registros ainda',
                  message:
                      'Assim que voce salvar vendas e gastos, a trilha financeira aparece aqui.',
                )
              else
                Column(
                  children: movements
                      .take(6)
                      .map(
                        (movement) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: NexoSpacing.sm),
                          child: NexoMovementListItem(
                            title: movement.title,
                            subtitle:
                                '${movement.subtitle} | ${DateLabelUtils.dayLabel(movement.date)}',
                            amount: MoneyUtils.format(movement.amount)
                                .replaceFirst('R\$ ', ''),
                            isExpense: movement.isExpense,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FinanceMovement {
  const _FinanceMovement({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
  });

  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final bool isExpense;
}
