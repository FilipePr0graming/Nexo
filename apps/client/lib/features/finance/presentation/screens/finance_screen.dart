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
import '../../../../shared/components/inputs/nexo_text_field.dart';
import '../../../../shared/components/lists/nexo_movement_list_item.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../models/expense_model.dart';
import '../../models/expense_details.dart';

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
      animation:
          Listenable.merge([salesService, expensesService, services.goals]),
      builder: (context, _) {
        final summary = LifeFinanceService.summarize(
          sales: salesService.sales,
          expenses: expensesService.expenses,
          goals: services.goals.goals,
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
          subtitle:
              'Veja entradas, gastos, contas e o que ainda esta reservado.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Dinheiro livre',
                      value: MoneyUtils.format(summary.freeMoney),
                      footnote: 'Dinheiro que voce pode movimentar agora.',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Reservado',
                      value: MoneyUtils.format(summary.lockedMoney),
                      footnote: 'Contas, parceiros, parcelas e metas.',
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
                      label: 'Resultado do mes',
                      value: MoneyUtils.format(summary.realProfit),
                      footnote:
                          'O que realmente sobrou depois de gastos e compromissos.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.xl),
              _AccountsPanel(expenses: expensesService.expenses),
              const SizedBox(height: NexoSpacing.xl),
              _PlannedPurchasesPanel(expenses: expensesService.expenses),
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

class _AccountsPanel extends StatelessWidget {
  const _AccountsPanel({required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final items = _defaultAccounts(context, expenses);
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contas e vencimentos',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NexoSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
              child: _FinanceItemTile(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedPurchasesPanel extends StatelessWidget {
  const _PlannedPurchasesPanel({required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final items = _defaultPurchases(context, expenses);
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compras planejadas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NexoSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
              child: _FinanceItemTile(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceItemTile extends StatelessWidget {
  const _FinanceItemTile({required this.item});

  final _FinanceItem item;

  @override
  Widget build(BuildContext context) {
    final details = item.details;
    return NexoCard(
      padding: const EdgeInsets.all(NexoSpacing.md),
      onTap: () => _openFinanceItemSheet(context, item),
      backgroundColor: NexoColors.surfaceElevated,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: NexoSpacing.xxs),
                Text(
                  [
                    details.status.label,
                    'vence dia ${details.dueDate.toLocal().day}',
                    details.wallet ?? item.wallet,
                  ].where((value) => value.isNotEmpty).join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NexoColors.inkMedium,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NexoSpacing.md),
          Text(
            MoneyUtils.format(details.pendingAmount > 0
                ? details.pendingAmount
                : details.originalAmount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: details.status == ExpensePaymentStatus.paid
                      ? NexoColors.success
                      : NexoColors.accent,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openFinanceItemSheet(
  BuildContext context,
  _FinanceItem item,
) async {
  final titleController = TextEditingController(text: item.title);
  final isCoraCard = item.title.toLowerCase().contains('cora');
  final amountController = TextEditingController(
    text: (isCoraCard
            ? item.details.cardOriginalAmount ?? item.details.originalAmount
            : item.details.originalAmount)
        .toStringAsFixed(2)
        .replaceAll('.', ','),
  );
  final paidController = TextEditingController(
    text: (isCoraCard
            ? item.details.cardPaidWithInterest ?? item.details.paidAmount
            : item.details.paidAmount)
        .toStringAsFixed(2)
        .replaceAll('.', ','),
  );
  final walletController = TextEditingController(
    text: item.details.wallet ?? item.wallet,
  );
  final noteController =
      TextEditingController(text: item.details.humanNote ?? item.note);
  var status = item.details.status;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: NexoColors.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final interest = item.details.copyWith(
              originalAmount: MoneyUtils.parseInput(amountController.text),
              paidAmount: MoneyUtils.parseInput(paidController.text),
              cardOriginalAmount: MoneyUtils.parseInput(amountController.text),
              cardPaidWithInterest: MoneyUtils.parseInput(paidController.text),
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                NexoSpacing.lg,
                NexoSpacing.md,
                NexoSpacing.lg,
                MediaQuery.viewInsetsOf(sheetContext).bottom + NexoSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Detalhe financeiro',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: NexoSpacing.lg),
                    NexoTextField(label: 'Titulo', controller: titleController),
                    const SizedBox(height: NexoSpacing.md),
                    NexoTextField(
                      label: 'Valor original',
                      controller: amountController,
                      prefixText: 'R\$ ',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: NexoSpacing.md),
                    NexoTextField(
                      label: 'Valor pago',
                      controller: paidController,
                      prefixText: 'R\$ ',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: NexoSpacing.md),
                    NexoTextField(
                        label: 'Banco/carteira', controller: walletController),
                    const SizedBox(height: NexoSpacing.md),
                    Wrap(
                      spacing: NexoSpacing.sm,
                      children: ExpensePaymentStatus.values
                          .map(
                            (value) => ChoiceChip(
                              label: Text(value.label),
                              selected: status == value,
                              onSelected: (_) => setState(() => status = value),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (isCoraCard) ...[
                      const SizedBox(height: NexoSpacing.md),
                      Text(
                        'Voce pagou ${MoneyUtils.format(interest.interestAmount)} de juros (${interest.interestPercent.toStringAsFixed(2)}%).',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: NexoSpacing.md),
                    NexoTextField(
                      label: 'Observacao',
                      controller: noteController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: NexoSpacing.lg),
                    Wrap(
                      spacing: NexoSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final service = NexoScope.of(context).expenses;
                            final original =
                                MoneyUtils.parseInput(amountController.text);
                            final paid =
                                MoneyUtils.parseInput(paidController.text);
                            final expenseAmount = isCoraCard ? paid : original;
                            final details = item.details.copyWith(
                              status: status,
                              originalAmount: original,
                              paidAmount: paid,
                              wallet: walletController.text,
                              cardOriginalAmount: isCoraCard ? original : null,
                              cardPaidWithInterest: isCoraCard ? paid : null,
                            );
                            if (item.expense == null) {
                              await service.createExpense(
                                title: titleController.text,
                                category: item.category,
                                amount: expenseAmount,
                                scope: item.scope,
                                accountName: walletController.text,
                                expenseDate: details.dueDate.toUtc(),
                                recurrence:
                                    details.recurrenceKind.legacyStorage,
                                notes: noteController.text,
                                status: status,
                                paidAmount: paid,
                                dueDate: details.dueDate,
                                recurrenceKind: details.recurrenceKind,
                                fixedDueDay: details.fixedDueDay,
                                wallet: walletController.text,
                                priority: item.priority,
                                plannedPaymentMethod: item.plannedPaymentMethod,
                                cardOriginalAmount:
                                    isCoraCard ? original : null,
                                cardPaidWithInterest: isCoraCard ? paid : null,
                              );
                            } else {
                              await service.updateExpenseDetails(
                                item.expense!,
                                details,
                                note: noteController.text,
                              );
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Salvar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            if (item.expense != null) {
                              await NexoScope.of(context)
                                  .expenses
                                  .markAsPaid(item.expense!);
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Marcar pago'),
                        ),
                        if (item.expense != null)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await NexoScope.of(context)
                                  .expenses
                                  .deleteExpense(item.expense!.id);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Excluir'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    titleController.dispose();
    amountController.dispose();
    paidController.dispose();
    walletController.dispose();
    noteController.dispose();
  }
}

List<_FinanceItem> _defaultAccounts(
  BuildContext context,
  List<ExpenseModel> expenses,
) {
  final now = DateTime.now();
  final defaults = [
    _FinanceSeed(
        'Cemig', 538.31, 'Conta casa', ExpenseScope.personal, 10, '3 contas',
        wallet: 'Indefinido'),
    _FinanceSeed('Copasa', 495.41, 'Conta casa', ExpenseScope.personal, 12,
        '2 contas; manter parcelas editaveis',
        wallet: 'Indefinido', status: ExpensePaymentStatus.partial),
    _FinanceSeed('Daniel', 1377, 'Parceiro', ExpenseScope.business, 15,
        'R\$ 897,00 + R\$ 480,00',
        wallet: 'Indefinido'),
    _FinanceSeed('Padaria', 300, 'Casa', ExpenseScope.personal, 8, 'Dia a dia',
        wallet: 'Dinheiro'),
    _FinanceSeed('Aluguel', 4000, 'Aluguel', ExpenseScope.personal, 24,
        'Pagar R\$ 2.000 por mes inicialmente',
        wallet: 'BTG', recurrence: ExpenseRecurrenceKind.monthly),
    _FinanceSeed('Duda', 100, 'Familia', ExpenseScope.personal, 5, 'Pago',
        wallet: 'Indefinido', status: ExpensePaymentStatus.paid, paid: 100),
    _FinanceSeed('Mae', 1000, 'Familia', ExpenseScope.personal, 18, 'Pendente',
        wallet: 'Indefinido'),
    _FinanceSeed('Fatura abril Cora', 531.17, 'Cartao de credito',
        ExpenseScope.business, 4, 'Fatura paga. Limite liberado.',
        wallet: 'Cora Cartao',
        status: ExpensePaymentStatus.paid,
        paid: 531.17,
        cardOriginalAmount: 499.52,
        cardPaidWithInterest: 531.17),
    _FinanceSeed('Serasa Giovanna', 2304.58, 'Limpar nome',
        ExpenseScope.personal, 22, 'Pessoa: Giovanna',
        wallet: 'Indefinido'),
    _FinanceSeed('Serasa Felipe', 2244.97, 'Limpar nome', ExpenseScope.personal,
        22, 'Pessoa: Felipe',
        wallet: 'Indefinido'),
    _FinanceSeed('Heranca', 30000, 'A receber previsto', ExpenseScope.business,
        30, 'Pode variar de R\$ 20 mil a R\$ 30 mil',
        wallet: 'Indefinido', status: ExpensePaymentStatus.forecast),
  ];
  return defaults.map((seed) => seed.toItem(now, expenses)).toList();
}

List<_FinanceItem> _defaultPurchases(
  BuildContext context,
  List<ExpenseModel> expenses,
) {
  final now = DateTime.now();
  final defaults = [
    _FinanceSeed('Sofa', 3399, 'Compra planejada', ExpenseScope.personal, 28,
        'Forma prevista: Pix',
        wallet: 'BTG',
        status: ExpensePaymentStatus.planned,
        priority: 'media',
        plannedPaymentMethod: 'Pix'),
    _FinanceSeed('Guarda-roupa', 1200, 'Compra planejada',
        ExpenseScope.personal, 28, 'Prioridade alta',
        wallet: 'BTG',
        status: ExpensePaymentStatus.planned,
        priority: 'alta',
        plannedPaymentMethod: 'Pix'),
    _FinanceSeed('Cama King/Queen', 6588.91, 'Compra planejada',
        ExpenseScope.personal, 28, 'Forma prevista: Pix',
        wallet: 'BTG',
        status: ExpensePaymentStatus.planned,
        plannedPaymentMethod: 'Pix'),
    _FinanceSeed('Jeep/Carrinho Davi', 700, 'Compra planejada',
        ExpenseScope.personal, 28, 'Prioridade alta',
        wallet: 'BTG',
        status: ExpensePaymentStatus.planned,
        priority: 'alta',
        plannedPaymentMethod: 'Pix'),
  ];
  return defaults.map((seed) => seed.toItem(now, expenses)).toList();
}

class _FinanceSeed {
  const _FinanceSeed(
    this.title,
    this.amount,
    this.category,
    this.scope,
    this.dueDay,
    this.note, {
    required this.wallet,
    this.status = ExpensePaymentStatus.pending,
    this.recurrence = ExpenseRecurrenceKind.once,
    this.paid = 0,
    this.priority,
    this.plannedPaymentMethod,
    this.cardOriginalAmount,
    this.cardPaidWithInterest,
  });

  final String title;
  final double amount;
  final String category;
  final ExpenseScope scope;
  final int dueDay;
  final String note;
  final String wallet;
  final ExpensePaymentStatus status;
  final ExpenseRecurrenceKind recurrence;
  final double paid;
  final String? priority;
  final String? plannedPaymentMethod;
  final double? cardOriginalAmount;
  final double? cardPaidWithInterest;

  _FinanceItem toItem(DateTime now, List<ExpenseModel> expenses) {
    final existing = expenses.cast<ExpenseModel?>().firstWhere(
          (expense) =>
              expense?.title.trim().toLowerCase() == title.toLowerCase(),
          orElse: () => null,
        );
    if (existing != null) {
      return _FinanceItem(
        title: existing.title,
        category: existing.category,
        scope: existing.scope,
        wallet: existing.accountName,
        note: ExpenseDetails.plainNote(existing.notes) ?? note,
        details: ExpenseDetails.fromExpense(existing),
        expense: existing,
      );
    }

    var due = DateTime(now.year, now.month, dueDay, 9);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, dueDay, 9);
    }
    return _FinanceItem(
      title: title,
      category: category,
      scope: scope,
      wallet: wallet,
      note: note,
      priority: priority,
      plannedPaymentMethod: plannedPaymentMethod,
      details: ExpenseDetails(
        status: status,
        originalAmount: amount,
        paidAmount: paid,
        dueDate: due,
        recurrenceKind: recurrence,
        fixedDueDay:
            recurrence == ExpenseRecurrenceKind.monthly ? dueDay : null,
        wallet: wallet,
        humanNote: note,
        priority: priority,
        plannedPaymentMethod: plannedPaymentMethod,
        cardOriginalAmount: cardOriginalAmount,
        cardPaidWithInterest: cardPaidWithInterest,
      ),
    );
  }
}

class _FinanceItem {
  const _FinanceItem({
    required this.title,
    required this.category,
    required this.scope,
    required this.wallet,
    required this.note,
    required this.details,
    this.expense,
    this.priority,
    this.plannedPaymentMethod,
  });

  final String title;
  final String category;
  final ExpenseScope scope;
  final String wallet;
  final String note;
  final ExpenseDetails details;
  final ExpenseModel? expense;
  final String? priority;
  final String? plannedPaymentMethod;
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
