import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/models/life_finance_summary.dart';
import '../../../../core/services/finance_calculator.dart';
import '../../../../core/services/life_finance_service.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_alert_card.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/inputs/nexo_segmented_field.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';
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
      animation: Listenable.merge([
        services.clients,
        salesService,
        expensesService,
        services.goals,
      ]),
      builder: (context, _) {
        final sales = salesService.sales;
        final expenses = expensesService.expenses;
        final memory = _DashboardMemory.from(
          sales: sales,
          expenses: expenses,
        );
        final summary = LifeFinanceService.summarize(
          sales: sales,
          expenses: expenses,
          goals: services.goals.goals,
        );
        final movements = _buildRecentMovements(sales, expenses);

        return NexoPageScaffold(
          title: 'Hoje',
          subtitle: 'Abra aqui e decida o que fazer com o dinheiro.',
          trailing: NexoIconButton(
            icon: NexoIcons.refresh,
            tooltip: 'Atualizar',
            onPressed: () {
              salesService.refresh();
              expensesService.refresh();
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FocusModeCard(
                summary: summary,
                memory: memory,
                onReceiveMoney: () => _receiveMoneyNow(
                  context,
                  summary,
                  memory,
                ),
                onPayBill: () => _showQuickExpenseSheet(
                  context,
                  title: 'Pagar conta',
                  memory: memory,
                  defaultScope: ExpenseScope.business,
                ),
                onAddExpense: () => _showQuickExpenseSheet(
                  context,
                  title: 'Adicionar gasto',
                  memory: memory,
                  defaultScope: ExpenseScope.personal,
                ),
                onChargeClient: () => _showChargeClientSheet(context, summary),
              ),
              const SizedBox(height: NexoSpacing.lg),
              _DailyAnswerCard(summary: summary),
              const SizedBox(height: NexoSpacing.xl),
              _MemoryCard(memory: memory),
              const SizedBox(height: NexoSpacing.x2l),
              _ForecastGrid(forecasts: summary.forecasts),
              const SizedBox(height: NexoSpacing.x2l),
              _IncomeSuggestionCard(suggestions: summary.incomeSuggestions),
              const SizedBox(height: NexoSpacing.x2l),
              _ClientInsightsCard(insights: summary.clientInsights),
              const SizedBox(height: NexoSpacing.x2l),
              const NexoSectionHeader(title: 'Alertas importantes'),
              const SizedBox(height: NexoSpacing.md),
              Column(
                children: summary.alerts
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
              _CashBreakdown(summary: summary),
              const SizedBox(height: NexoSpacing.x2l),
              _TodayPlan(
                summary: summary,
                onMarkReceived: salesService.markAsReceived,
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
                          padding:
                              const EdgeInsets.only(bottom: NexoSpacing.sm),
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
              if (salesService.errorMessage != null ||
                  expensesService.errorMessage != null) ...[
                const SizedBox(height: NexoSpacing.lg),
                Text(
                  salesService.errorMessage ??
                      expensesService.errorMessage ??
                      '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
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

  Future<void> _receiveMoneyNow(
    BuildContext context,
    LifeFinanceSummary summary,
    _DashboardMemory memory,
  ) async {
    final services = NexoScope.of(context);
    if (summary.upcomingReceipts.isNotEmpty) {
      final sale = summary.upcomingReceipts.first;
      await services.sales.markAsReceived(sale.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recebido: ${sale.clientName} ${MoneyUtils.format(sale.ownerAmount)}.',
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await _showQuickIncomeSheet(context, memory);
    }
  }

  Future<void> _showQuickIncomeSheet(
    BuildContext context,
    _DashboardMemory memory,
  ) {
    final clientController =
        TextEditingController(text: memory.favoriteClientName);
    final amountController = TextEditingController(
      text: memory.commonIncomeAmount > 0
          ? MoneyUtils.format(memory.commonIncomeAmount)
              .replaceFirst('R\$ ', '')
          : '',
    );
    return _showQuickSheet(
      context,
      title: 'Recebi dinheiro',
      child: StatefulBuilder(
        builder: (context, setState) {
          final suggestions = [
            ...memory.clientNames.take(3),
            if (memory.clientNames.isEmpty) 'Cliente',
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SuggestionChips(
                values: suggestions,
                onSelected: (value) => clientController.text = value,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Cliente',
                hint: 'Quem pagou?',
                controller: clientController,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Valor recebido',
                hint: '0,00',
                controller: amountController,
                prefixText: 'R\$ ',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: NexoSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final amount = MoneyUtils.parseInput(amountController.text);
                  final clientName = clientController.text.trim();
                  if (amount <= 0 || clientName.isEmpty) {
                    return;
                  }

                  await NexoScope.of(context).sales.createSale(
                        clientName: clientName,
                        serviceName: 'Recebimento rapido',
                        grossAmount: amount,
                        platform: 'Pix direto',
                        paymentMethod: 'Pix',
                        installments: 1,
                        saleDate: DateTime.now().toUtc(),
                        expectedDate: DateTime.now().toUtc(),
                        receivedDate: DateTime.now().toUtc(),
                        status: SaleStatus.received,
                        platformFee: 0,
                        paymentFee: 0,
                        hasDanielParticipation: false,
                        danielPercent: FinanceCalculator.danielDefaultPercent,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dinheiro registrado.')),
                    );
                  }
                },
                child: const Text('Registrar agora'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      clientController.dispose();
      amountController.dispose();
    });
  }

  Future<void> _showQuickExpenseSheet(
    BuildContext context, {
    required String title,
    required _DashboardMemory memory,
    required ExpenseScope defaultScope,
  }) {
    final amountController = TextEditingController(
      text: memory.commonExpenseAmount > 0
          ? MoneyUtils.format(memory.commonExpenseAmount)
              .replaceFirst('R\$ ', '')
          : '',
    );
    final titleController = TextEditingController(
      text: memory.favoriteExpenseTitle,
    );
    var scope = defaultScope;

    return _showQuickSheet(
      context,
      title: title,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SuggestionChips(
                values: memory.expenseTitles.take(4).toList(growable: false),
                onSelected: (value) => titleController.text = value,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Conta ou gasto',
                hint: 'Ex.: Internet, mercado, IA',
                controller: titleController,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Valor',
                hint: '0,00',
                controller: amountController,
                prefixText: 'R\$ ',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoSegmentedField<ExpenseScope>(
                label: 'Tipo',
                value: scope,
                onChanged: (value) => setState(() => scope = value),
                segments: const [
                  ButtonSegment(
                    value: ExpenseScope.business,
                    label: Text('Empresa'),
                  ),
                  ButtonSegment(
                    value: ExpenseScope.personal,
                    label: Text('Casa'),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final amount = MoneyUtils.parseInput(amountController.text);
                  final expenseTitle = titleController.text.trim();
                  if (amount <= 0 || expenseTitle.isEmpty) {
                    return;
                  }

                  await NexoScope.of(context).expenses.createExpense(
                        title: expenseTitle,
                        category: scope == ExpenseScope.business
                            ? 'Rapido empresa'
                            : 'Rapido casa',
                        amount: amount,
                        scope: scope,
                        accountName: scope == ExpenseScope.business
                            ? 'Conta empresa'
                            : 'Conta pessoal',
                        expenseDate: DateTime.now().toUtc(),
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gasto registrado.')),
                    );
                  }
                },
                child: const Text('Registrar agora'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      amountController.dispose();
      titleController.dispose();
    });
  }

  Future<void> _showChargeClientSheet(
    BuildContext context,
    LifeFinanceSummary summary,
  ) {
    return _showQuickSheet(
      context,
      title: 'Cobrar cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.upcomingReceipts.isEmpty)
            const Text('Nada para cobrar agora.')
          else
            ...summary.upcomingReceipts.take(5).map(
                  (sale) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                    child: _ChargeRow(sale: sale),
                  ),
                ),
        ],
      ),
    );
  }

  Future<T?> _showQuickSheet<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: NexoColors.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: NexoSpacing.md,
            right: NexoSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + NexoSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: NexoSpacing.lg),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FocusModeCard extends StatelessWidget {
  const _FocusModeCard({
    required this.summary,
    required this.memory,
    required this.onReceiveMoney,
    required this.onPayBill,
    required this.onAddExpense,
    required this.onChargeClient,
  });

  final LifeFinanceSummary summary;
  final _DashboardMemory memory;
  final VoidCallback onReceiveMoney;
  final VoidCallback onPayBill;
  final VoidCallback onAddExpense;
  final VoidCallback onChargeClient;

  @override
  Widget build(BuildContext context) {
    final mainMessage = summary.forecasts.any(
      (forecast) => forecast.projectedMoney < 0,
    )
        ? 'Voce esta apertado nos proximos dias'
        : summary.freeMoney - summary.toPay7Days >= 300
            ? 'Voce pode gastar hoje'
            : 'Melhor nao comprar isso agora';

    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modo foco',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            mainMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: NexoColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: NexoSpacing.md),
          if (summary.todayActions.isEmpty)
            const Text('Registre o que entrar e sair hoje.')
          else
            ...summary.todayActions.take(3).map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                    child: _ActionRow(action: action),
                  ),
                ),
          const SizedBox(height: NexoSpacing.lg),
          _FocusButtonGrid(
            buttons: [
              _FocusButtonData(
                icon: NexoIcons.income,
                label: summary.upcomingReceipts.isEmpty
                    ? 'Recebi dinheiro'
                    : 'Recebi ${summary.upcomingReceipts.first.clientName}',
                onTap: onReceiveMoney,
              ),
              _FocusButtonData(
                icon: Icons.receipt_long_rounded,
                label: 'Pagar conta',
                onTap: onPayBill,
              ),
              _FocusButtonData(
                icon: NexoIcons.newExpense,
                label: memory.commonExpenseAmount > 0
                    ? 'Gasto comum'
                    : 'Adicionar gasto',
                onTap: onAddExpense,
              ),
              _FocusButtonData(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Cobrar cliente',
                onTap: onChargeClient,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusButtonGrid extends StatelessWidget {
  const _FocusButtonGrid({
    required this.buttons,
  });

  final List<_FocusButtonData> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - NexoSpacing.md) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: NexoSpacing.md,
          runSpacing: NexoSpacing.sm,
          children: buttons
              .map(
                (button) => SizedBox(
                  width: width,
                  child: FilledButton.icon(
                    onPressed: button.onTap,
                    icon: Icon(button.icon, size: 18),
                    label: Text(button.label),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _FocusButtonData {
  const _FocusButtonData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _DailyAnswerCard extends StatelessWidget {
  const _DailyAnswerCard({
    required this.summary,
  });

  final LifeFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final canSpend = summary.freeMoney - summary.toPay7Days;
    final phrase = canSpend >= 300
        ? 'Voce pode gastar ${MoneyUtils.format(canSpend)} com cuidado.'
        : 'Nao compre isso agora. Priorize contas e cobranças.';

    return NexoCard(
      backgroundColor: NexoColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resposta de hoje',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            phrase,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:
                      canSpend >= 300 ? NexoColors.success : NexoColors.error,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: NexoSpacing.lg),
          _PlanRow(
            label: 'O que cobrar',
            value: MoneyUtils.format(summary.toReceive7Days),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'O que pagar',
            value: MoneyUtils.format(summary.toPay7Days),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.memory,
  });

  final _DashboardMemory memory;

  @override
  Widget build(BuildContext context) {
    if (!memory.hasData) {
      return const NexoEmptyStateCard(
        title: 'O app ainda esta aprendendo',
        message: 'Depois de alguns registros, ele sugere clientes e valores.',
      );
    }

    return NexoCard(
      backgroundColor: NexoColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugestoes automaticas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          _PlanRow(
            label: 'Cliente frequente',
            value: memory.favoriteClientName.isEmpty
                ? 'Sem padrao'
                : memory.favoriteClientName,
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Recebimento comum',
            value: MoneyUtils.format(memory.commonIncomeAmount),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Gasto comum',
            value: memory.favoriteExpenseTitle.isEmpty
                ? MoneyUtils.format(memory.commonExpenseAmount)
                : memory.favoriteExpenseTitle,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
  });

  final TodayAction action;

  @override
  Widget build(BuildContext context) {
    final color = switch (action.priority) {
      ActionPriority.high => NexoColors.error,
      ActionPriority.medium => NexoColors.warning,
      ActionPriority.low => NexoColors.success,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: NexoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: NexoSpacing.xxs),
              Text(
                action.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NexoColors.inkMedium,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastGrid extends StatelessWidget {
  const _ForecastGrid({
    required this.forecasts,
  });

  final List<CashForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final cards = forecasts
            .map((forecast) => _ForecastCard(forecast: forecast))
            .toList(growable: false);

        if (!isWide) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                    child: card,
                  ),
                )
                .toList(growable: false),
          );
        }

        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: NexoSpacing.md),
                    child: card,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.forecast,
  });

  final CashForecast forecast;

  @override
  Widget build(BuildContext context) {
    final color =
        forecast.projectedMoney < 0 ? NexoColors.error : NexoColors.accent;

    return NexoCard(
      backgroundColor: NexoColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${forecast.days} dias',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NexoColors.inkMedium,
                ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            MoneyUtils.format(forecast.projectedMoney),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            forecast.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NexoColors.inkLow,
                ),
          ),
        ],
      ),
    );
  }
}

class _IncomeSuggestionCard extends StatelessWidget {
  const _IncomeSuggestionCard({
    required this.suggestions,
  });

  final List<IncomeSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quando entrar dinheiro',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
              child: _SuggestionRow(suggestion: suggestion),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
  });

  final IncomeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: NexoSpacing.xxs),
              Text(
                suggestion.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NexoColors.inkLow,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: NexoSpacing.md),
        Text(
          MoneyUtils.format(suggestion.amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: NexoColors.ink,
              ),
        ),
      ],
    );
  }
}

class _ClientInsightsCard extends StatelessWidget {
  const _ClientInsightsCard({
    required this.insights,
  });

  final List<ClientInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const NexoEmptyStateCard(
        title: 'Sem leitura de clientes ainda',
        message: 'Quando houver vendas, o app mostra quem vale manter.',
      );
    }

    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clientes para decidir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          ...insights.take(3).map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                  child: _ClientInsightRow(insight: insight),
                ),
              ),
        ],
      ),
    );
  }
}

class _ClientInsightRow extends StatelessWidget {
  const _ClientInsightRow({
    required this.insight,
  });

  final ClientInsight insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          insight.keep ? Icons.check_circle_rounded : Icons.warning_rounded,
          size: 20,
          color: insight.keep ? NexoColors.success : NexoColors.warning,
        ),
        const SizedBox(width: NexoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.clientName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: NexoSpacing.xxs),
              Text(
                insight.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NexoColors.inkMedium,
                    ),
              ),
              const SizedBox(height: NexoSpacing.xxs),
              Text(
                'Lucro ${MoneyUtils.format(insight.profit)} | Aberto ${MoneyUtils.format(insight.openAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NexoColors.inkLow,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.values,
    required this.onSelected,
  });

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(4)
        .toList(growable: false);

    if (cleanValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: NexoSpacing.xs,
      runSpacing: NexoSpacing.xs,
      children: cleanValues
          .map(
            (value) => ActionChip(
              label: Text(value),
              onPressed: () => onSelected(value),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.sale,
  });

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      backgroundColor: NexoColors.surfaceElevated,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.clientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: NexoSpacing.xxs),
                Text(
                  '${sale.serviceName} | ${DateLabelUtils.dayLabel(sale.expectedDate.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NexoColors.inkLow,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NexoSpacing.md),
          TextButton(
            onPressed: () async {
              final message =
                  'Oi, ${sale.clientName}. Passando para lembrar do pagamento de ${MoneyUtils.format(sale.ownerAmount)} referente a ${sale.serviceName}.';
              await Clipboard.setData(ClipboardData(text: message));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensagem copiada.')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }
}

class _DashboardMemory {
  const _DashboardMemory({
    required this.favoriteClientName,
    required this.clientNames,
    required this.commonIncomeAmount,
    required this.favoriteExpenseTitle,
    required this.expenseTitles,
    required this.commonExpenseAmount,
  });

  final String favoriteClientName;
  final List<String> clientNames;
  final double commonIncomeAmount;
  final String favoriteExpenseTitle;
  final List<String> expenseTitles;
  final double commonExpenseAmount;

  bool get hasData {
    return favoriteClientName.isNotEmpty ||
        favoriteExpenseTitle.isNotEmpty ||
        commonIncomeAmount > 0 ||
        commonExpenseAmount > 0;
  }

  factory _DashboardMemory.from({
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
  }) {
    final clientNames = _rankText(
      sales.map((sale) => sale.clientName),
    );
    final expenseTitles = _rankText(
      expenses.map((expense) => expense.title),
    );
    final receivedAmounts = sales
        .where((sale) => sale.status == SaleStatus.received)
        .map((sale) => sale.ownerAmount)
        .where((amount) => amount > 0)
        .toList(growable: false);
    final expenseAmounts = expenses
        .map((expense) => expense.amount)
        .where((amount) => amount > 0)
        .toList(growable: false);

    return _DashboardMemory(
      favoriteClientName: clientNames.isEmpty ? '' : clientNames.first,
      clientNames: clientNames,
      commonIncomeAmount: _commonAmount(receivedAmounts),
      favoriteExpenseTitle: expenseTitles.isEmpty ? '' : expenseTitles.first,
      expenseTitles: expenseTitles,
      commonExpenseAmount: _commonAmount(expenseAmounts),
    );
  }

  static List<String> _rankText(Iterable<String> values) {
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      labels[key] = trimmed;
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));

    return entries
        .map((entry) => labels[entry.key]!)
        .take(5)
        .toList(growable: false);
  }

  static double _commonAmount(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    final counts = <String, int>{};
    for (final value in values) {
      final key = value.round().toString();
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));

    return double.parse(entries.first.key);
  }
}

class _CashBreakdown extends StatelessWidget {
  const _CashBreakdown({
    required this.summary,
  });

  final LifeFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      backgroundColor: NexoColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caixa real',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          _PlanRow(
            label: 'Entradas confirmadas',
            value: MoneyUtils.format(summary.confirmedEntries),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Menos gastos',
            value: MoneyUtils.format(summary.businessExpenses),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Menos Daniel',
            value: MoneyUtils.format(summary.committedMoney),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Menos parcelas futuras',
            value: MoneyUtils.format(summary.futureInstallments),
          ),
          const Divider(height: NexoSpacing.xl),
          _PlanRow(
            label: 'Dinheiro livre',
            value: MoneyUtils.format(summary.freeMoney),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _TodayPlan extends StatelessWidget {
  const _TodayPlan({
    required this.summary,
    required this.onMarkReceived,
  });

  final LifeFinanceSummary summary;
  final Future<void> Function(String saleId) onMarkReceived;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plano dos proximos 7 dias',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          _PlanRow(
            label: 'Vai entrar',
            value: MoneyUtils.format(summary.toReceive7Days),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Precisa pagar',
            value: MoneyUtils.format(summary.toPay7Days),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Livre depois disso',
            value: MoneyUtils.format(summary.freeMoney - summary.toPay7Days),
            strong: true,
          ),
          if (summary.upcomingReceipts.isNotEmpty) ...[
            const SizedBox(height: NexoSpacing.lg),
            Text(
              'Receber agora',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: NexoSpacing.sm),
            ...summary.upcomingReceipts.take(3).map(
                  (sale) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                    child: _DueActionRow(
                      title: sale.clientName,
                      subtitle:
                          '${sale.serviceName} | ${DateLabelUtils.dayLabel(sale.expectedDate.toLocal())}',
                      value: MoneyUtils.format(sale.ownerAmount),
                      actionLabel: 'Recebi',
                      onPressed: () => onMarkReceived(sale.id),
                    ),
                  ),
                ),
          ],
          if (summary.upcomingBills.isNotEmpty) ...[
            const SizedBox(height: NexoSpacing.lg),
            Text(
              'Pagar sem esquecer',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: NexoSpacing.sm),
            ...summary.upcomingBills.take(3).map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                    child: _DueActionRow(
                      title: expense.title,
                      subtitle:
                          '${expense.scope.label} | ${DateLabelUtils.dayLabel(expense.expenseDate.toLocal())}',
                      value: MoneyUtils.format(expense.amount),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _DueActionRow extends StatelessWidget {
  const _DueActionRow({
    required this.title,
    required this.subtitle,
    required this.value,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String value;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: [title, subtitle, value].join('\n'),
      child: Container(
        padding: const EdgeInsets.all(NexoSpacing.sm),
        decoration: BoxDecoration(
          color: NexoColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NexoColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NexoColors.ink,
                        ),
                  ),
                  const SizedBox(height: NexoSpacing.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NexoColors.inkLow,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NexoSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: NexoSpacing.sm),
              Semantics(
                button: true,
                label: '$actionLabel $title $subtitle',
                onTap: onPressed,
                child: TextButton(
                  onPressed: onPressed,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
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
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
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
