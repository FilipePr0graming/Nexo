import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_alert_card.dart';
import '../../../../shared/components/cards/nexo_balance_hero_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/cards/nexo_quick_action_card.dart';
import '../../../../shared/components/lists/nexo_movement_list_item.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../../finance/models/expense_model.dart';
import '../../../finance/models/sale_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNewSale,
    required this.onNewExpense,
    required this.onOpenClients,
  });

  final VoidCallback onNewSale;
  final VoidCallback onNewExpense;
  final VoidCallback onOpenClients;

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    final salesService = services.sales;
    final expensesService = services.expenses;

    return AnimatedBuilder(
      animation: Listenable.merge([salesService, expensesService]),
      builder: (context, _) {
        final sales = salesService.sales;
        final expenses = expensesService.expenses;
        final now = DateTime.now();

        final receivedSales = sales
            .where((sale) => sale.status == SaleStatus.received)
            .toList(growable: false);
        final pendingSales = sales
            .where((sale) => sale.status == SaleStatus.pending || sale.status == SaleStatus.late)
            .toList(growable: false);
        final businessExpenses = expenses
            .where((expense) => expense.scope == ExpenseScope.business)
            .toList(growable: false);
        final personalExpenses = expenses
            .where((expense) => expense.scope == ExpenseScope.personal)
            .toList(growable: false);

        final businessBalance = receivedSales.fold<double>(
              0,
              (total, sale) => total + sale.ownerAmount,
            ) -
            businessExpenses.fold<double>(0, (total, expense) => total + expense.amount);
        final personalBalance =
            -personalExpenses.fold<double>(0, (total, expense) => total + expense.amount);
        final totalBalance = businessBalance + personalBalance;

        final receivedToday = receivedSales
            .where((sale) => DateLabelUtils.isSameDay(sale.movementDate.toLocal(), now))
            .fold<double>(0, (total, sale) => total + sale.ownerAmount);
        final pendingAmount =
            pendingSales.fold<double>(0, (total, sale) => total + sale.ownerAmount);
        final monthlyExpenses = expenses
            .where((expense) => DateLabelUtils.isInCurrentMonth(expense.expenseDate.toLocal(), now))
            .fold<double>(0, (total, expense) => total + expense.amount);
        final danielThisMonth = sales
            .where((sale) => DateLabelUtils.isInCurrentMonth(sale.movementDate.toLocal(), now))
            .fold<double>(0, (total, sale) => total + sale.danielValue);

        final alerts = _buildAlerts(sales, expenses);
        final movements = _buildRecentMovements(sales, expenses);

        return NexoPageScaffold(
          title: 'Hoje',
          subtitle: 'Visao imediata do que entrou, saiu e ficou pendente.',
          trailing: NexoIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Atualizar',
            onPressed: () {
              salesService.refresh();
              expensesService.refresh();
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexoBalanceHeroCard(
                title: 'Saldo geral',
                balance: MoneyUtils.format(totalBalance),
                primaryLabel: 'Empresa',
                primaryValue: MoneyUtils.format(businessBalance),
                secondaryLabel: 'Pessoal',
                secondaryValue: MoneyUtils.format(personalBalance),
              ),
              const SizedBox(height: NexoSpacing.xl),
              _MetricsGrid(
                children: [
                  NexoMetricCard(
                    label: 'Recebido hoje',
                    value: MoneyUtils.format(receivedToday),
                    footnote: 'Liquido confirmado',
                  ),
                  NexoMetricCard(
                    label: 'A receber',
                    value: MoneyUtils.format(pendingAmount),
                    footnote: 'Pendencias registradas',
                  ),
                  NexoMetricCard(
                    label: 'Gastos do mes',
                    value: MoneyUtils.format(monthlyExpenses),
                    footnote: 'Empresa + pessoal',
                  ),
                  NexoMetricCard(
                    label: 'Daniel',
                    value: MoneyUtils.format(danielThisMonth),
                    footnote: 'Comissao no periodo',
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.x2l),
              const NexoSectionHeader(title: 'Acoes rapidas'),
              const SizedBox(height: NexoSpacing.md),
              _QuickActionsGrid(
                children: [
                  NexoQuickActionCard(
                    icon: Icons.add_card_rounded,
                    title: 'Nova venda',
                    caption: 'Registrar entrada com comissao.',
                    onTap: onNewSale,
                  ),
                  NexoQuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Novo gasto',
                    caption: 'Lancar gasto em poucos toques.',
                    onTap: onNewExpense,
                  ),
                  NexoQuickActionCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Clientes',
                    caption: 'Abrir lista e cadastrar novo cliente.',
                    onTap: onOpenClients,
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.x2l),
              const NexoSectionHeader(title: 'Alertas'),
              const SizedBox(height: NexoSpacing.md),
              if (alerts.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem alertas agora',
                  message:
                      'Os indicadores principais estao organizados. Novos alertas aparecem assim que houver pendencias ou padroes claros.',
                )
              else
                Column(
                  children: alerts
                      .map(
                        (alert) => Padding(
                          padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                          child: NexoAlertCard(
                            title: alert.title,
                            message: alert.message,
                            tone: alert.tone,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: NexoSpacing.x2l),
              const NexoSectionHeader(title: 'Movimentos recentes'),
              const SizedBox(height: NexoSpacing.md),
              if (movements.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Nenhum movimento salvo ainda',
                  message:
                      'Registre uma venda ou gasto para o painel comecar a refletir sua operacao real.',
                )
              else
                Column(
                  children: movements
                      .map(
                        (movement) => Padding(
                          padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                          child: NexoMovementListItem(
                            title: movement.title,
                            subtitle: movement.subtitle,
                            amount: MoneyUtils.format(movement.amount)
                                .replaceFirst('R\$ ', ''),
                            isExpense: movement.isExpense,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              if (salesService.errorMessage != null || expensesService.errorMessage != null) ...[
                const SizedBox(height: NexoSpacing.lg),
                Text(
                  salesService.errorMessage ?? expensesService.errorMessage ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<_DashboardAlert> _buildAlerts(
    List<SaleModel> sales,
    List<ExpenseModel> expenses,
  ) {
    final alerts = <_DashboardAlert>[];

    final lateSales = sales.where((sale) => sale.status == SaleStatus.late).toList();
    final pendingSales =
        sales.where((sale) => sale.status == SaleStatus.pending).toList();
    final mixedExpenses = expenses.where((expense) {
      final account = expense.accountName.toLowerCase();
      return (expense.scope == ExpenseScope.business && account.contains('pessoal')) ||
          (expense.scope == ExpenseScope.personal && account.contains('empresa'));
    }).toList();

    if (lateSales.isNotEmpty || pendingSales.isNotEmpty) {
      final totalPending = [...lateSales, ...pendingSales]
          .fold<double>(0, (total, sale) => total + sale.ownerAmount);
      alerts.add(
        _DashboardAlert(
          title:
              '${lateSales.length + pendingSales.length} recebimentos pedem atencao',
          message:
              '${MoneyUtils.format(totalPending)} seguem como pendentes ou atrasados.',
          tone: NexoAlertTone.error,
        ),
      );
    }

    if (mixedExpenses.isNotEmpty) {
      alerts.add(
        _DashboardAlert(
          title: 'Mistura entre pessoal e empresa',
          message:
              '${mixedExpenses.length} gastos parecem estar na conta errada.',
          tone: NexoAlertTone.warning,
        ),
      );
    }

    if (sales.isNotEmpty) {
      final revenueByPlatform = <String, double>{};
      for (final sale in sales) {
        revenueByPlatform.update(
          sale.platform,
          (current) => current + sale.ownerAmount,
          ifAbsent: () => sale.ownerAmount,
        );
      }

      final topEntry = revenueByPlatform.entries.fold<MapEntry<String, double>?>(
        null,
        (best, current) {
          if (best == null || current.value > best.value) {
            return current;
          }
          return best;
        },
      );

      if (topEntry != null) {
        alerts.add(
          _DashboardAlert(
            title: '${topEntry.key} segue como canal mais forte',
            message:
                '${MoneyUtils.format(topEntry.value)} liquidos vieram dessa origem.',
            tone: NexoAlertTone.success,
          ),
        );
      }
    }

    return alerts.take(3).toList(growable: false);
  }

  List<_DashboardMovement> _buildRecentMovements(
    List<SaleModel> sales,
    List<ExpenseModel> expenses,
  ) {
    final movements = <_DashboardMovement>[
      ...sales.map(
        (sale) => _DashboardMovement(
          title: sale.clientName,
          subtitle:
              'Venda ${sale.platform} | ${DateLabelUtils.movementLabel(sale.movementDate.toLocal())}',
          amount: sale.ownerAmount,
          date: sale.movementDate.toLocal(),
          isExpense: false,
        ),
      ),
      ...expenses.map(
        (expense) => _DashboardMovement(
          title: expense.title,
          subtitle:
              'Gasto ${expense.scope.label.toLowerCase()} | ${DateLabelUtils.movementLabel(expense.expenseDate.toLocal())}',
          amount: expense.amount,
          date: expense.expenseDate.toLocal(),
          isExpense: true,
        ),
      ),
    ];

    movements.sort((left, right) => right.date.compareTo(left.date));
    return movements.take(6).toList(growable: false);
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 960 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          itemCount: children.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: NexoSpacing.md,
            mainAxisSpacing: NexoSpacing.md,
            childAspectRatio: constraints.maxWidth < 420 ? 1.08 : 1.25,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          itemCount: children.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: NexoSpacing.md,
            mainAxisSpacing: NexoSpacing.md,
            childAspectRatio: constraints.maxWidth < 420 ? 2.0 : 2.4,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _DashboardAlert {
  const _DashboardAlert({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final NexoAlertTone tone;
}

class _DashboardMovement {
  const _DashboardMovement({
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
