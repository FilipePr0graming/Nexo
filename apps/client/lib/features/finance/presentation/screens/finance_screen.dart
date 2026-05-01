import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/models/life_finance_summary.dart';
import '../../../../core/services/life_finance_service.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/cards/nexo_quick_action_card.dart';
import '../../../../shared/components/lists/nexo_movement_list_item.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../models/expense_model.dart';

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
        final summary = LifeFinanceService.summarize(
          sales: salesService.sales,
          expenses: expensesService.expenses,
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
          subtitle: 'Dinheiro livre, contas, casa, empresa e Daniel.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Dinheiro livre',
                      value: MoneyUtils.format(summary.freeMoney),
                      footnote: 'Pode usar com cuidado',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Dinheiro travado',
                      value: MoneyUtils.format(summary.lockedMoney),
                      footnote: 'Daniel + parcelas futuras',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'A pagar',
                      value: MoneyUtils.format(summary.toPay7Days),
                      footnote: 'Proximos 7 dias',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Lucro real',
                      value: MoneyUtils.format(summary.realProfit),
                      footnote: 'Entradas - gastos - Daniel',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.xl),
              _MoneySeparation(summary: summary),
              const SizedBox(height: NexoSpacing.xl),
              _PartnerPanel(partner: summary.partner),
              const SizedBox(height: NexoSpacing.xl),
              _GoalPanel(goal: summary.goal),
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

class _MoneySeparation extends StatelessWidget {
  const _MoneySeparation({
    required this.summary,
  });

  final LifeFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Casa vs empresa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          _AmountRow(
            label: 'Gastos da empresa',
            value: MoneyUtils.format(summary.businessExpenses),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _AmountRow(
            label: 'Gastos pessoais',
            value: MoneyUtils.format(summary.personalExpenses),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _AmountRow(
            label: 'Empresa bancando a casa',
            value: MoneyUtils.format(summary.housePaidByCompany),
            strong: summary.housePaidByCompany > 0,
          ),
        ],
      ),
    );
  }
}

class _PartnerPanel extends StatelessWidget {
  const _PartnerPanel({
    required this.partner,
  });

  final PartnerSummary partner;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daniel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          _AmountRow(
            label: 'Total a pagar',
            value: MoneyUtils.format(partner.totalToPay),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _AmountRow(
            label: 'Pago',
            value: MoneyUtils.format(partner.paid),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _AmountRow(
            label: 'Falta pagar',
            value: MoneyUtils.format(partner.remaining),
            strong: partner.remaining > 0,
          ),
          if (partner.projects.isNotEmpty) ...[
            const SizedBox(height: NexoSpacing.lg),
            const NexoSectionHeader(title: 'Por projeto'),
            const SizedBox(height: NexoSpacing.sm),
            ...partner.projects.take(4).map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.xs),
                    child: _AmountRow(
                      label: '${project.clientName} | ${project.projectName}',
                      value: MoneyUtils.format(project.amount),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({
    required this.goal,
  });

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();
    final forecast = switch (goal.monthsToReach) {
      0 => 'Meta batida',
      null => 'Sem previsao ainda',
      final months => '$months mes(es)',
    };

    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.xs),
          Text(
            goal.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NexoColors.inkMedium,
                ),
          ),
          const SizedBox(height: NexoSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: NexoColors.surfaceMuted,
              color: NexoColors.accent,
            ),
          ),
          const SizedBox(height: NexoSpacing.md),
          _AmountRow(
            label: '$percent% guardado',
            value:
                '${MoneyUtils.format(goal.saved)} / ${MoneyUtils.format(goal.target)}',
          ),
          const SizedBox(height: NexoSpacing.sm),
          _AmountRow(
            label: 'Previsao',
            value: forecast,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NexoColors.inkMedium,
                ),
          ),
        ),
        const SizedBox(width: NexoSpacing.md),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: strong ? NexoColors.accent : NexoColors.ink,
              ),
        ),
      ],
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
