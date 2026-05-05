import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_radius.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/models/life_finance_summary.dart';
import '../../../../core/services/life_finance_service.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../features/clients/models/client_model.dart';
import '../../../../features/finance/models/expense_model.dart';
import '../../../../features/finance/models/sale_model.dart';
import '../../../../features/goals/models/goal_model.dart';
import '../../../../features/notes/models/note_details.dart';
import '../../../../features/notes/models/note_model.dart';
import '../../../../features/partners/models/partner_payment_model.dart';
import '../../../../features/projects/models/project_model.dart';
import '../../../../features/reminders/models/reminder_model.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';

class CasaScreen extends StatelessWidget {
  const CasaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        final personalExpenses = data.expenses
            .where((expense) => expense.scope == ExpenseScope.personal)
            .toList(growable: false);
        final byCategory = _sumExpensesByCategory(personalExpenses);
        final monthlyTotal = _sum(personalExpenses.map((item) => item.amount));
        final safeToday = data.summary.freeMoney - data.summary.toPay7Days;

        return NexoPageScaffold(
          title: 'Casa',
          subtitle: 'Vida pessoal, familia e gastos da casa.',
          child: _TwoColumnStage(
            left: [
              _HeroAmount(
                eyebrow: 'Saldo da casa',
                value: MoneyUtils.format(-monthlyTotal),
                message: safeToday > 0
                    ? 'Ha ${MoneyUtils.format(safeToday)} livre depois das contas da semana.'
                    : 'Melhor nao comprar isso agora. O caixa esta justo.',
              ),
              _SectionTitle('Gastos por categoria'),
              if (byCategory.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem gastos pessoais',
                  message: 'Lance gastos da casa para acompanhar aqui.',
                )
              else
                _ResponsiveCards(
                  children: byCategory.entries
                      .map(
                        (entry) => _KpiCard(
                          icon: _categoryIcon(entry.key),
                          label: entry.key,
                          value: MoneyUtils.format(entry.value),
                        ),
                      )
                      .toList(growable: false),
                ),
              _SectionTitle('Ultimas movimentacoes'),
              _MovementList(expenses: personalExpenses.take(6).toList()),
            ],
            right: [
              _GoalCard(goal: data.summary.goal),
              _InsightPanel(
                title: 'Separacao real',
                lines: [
                  if (data.summary.housePaidByCompany > 0)
                    'A empresa bancou ${MoneyUtils.format(data.summary.housePaidByCompany)} da casa. Corrija isso para enxergar o resultado real.'
                  else
                    'Casa e empresa estao separadas nos registros atuais.',
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmpresaScreen extends StatelessWidget {
  const EmpresaScreen({
    super.key,
    required this.onNewSale,
    required this.onNewExpense,
  });

  final VoidCallback onNewSale;
  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        final businessExpenses = data.expenses
            .where((expense) => expense.scope == ExpenseScope.business)
            .toList(growable: false);
        final received = data.sales
            .where((sale) => sale.status == SaleStatus.received)
            .toList(growable: false);

        return NexoPageScaffold(
          title: 'Empresa',
          subtitle: 'Caixa, lucro, entradas e saidas da operacao.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResponsiveCards(
                children: [
                  _KpiCard(
                    icon: NexoIcons.receipts,
                    label: 'Faturamento total',
                    value: MoneyUtils.format(data.summary.confirmedEntries),
                    large: true,
                    highlighted: true,
                  ),
                  _KpiCard(
                    icon: NexoIcons.finance,
                    label: 'Resultado real',
                    value: MoneyUtils.format(data.summary.realProfit),
                    footnote: 'Depois de gastos e parceiros',
                  ),
                  _KpiCard(
                    icon: NexoIcons.expenses,
                    label: 'Gastos da empresa',
                    value: MoneyUtils.format(data.summary.businessExpenses),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.x2l),
              _TwoColumnStage(
                left: [
                  _SectionHeaderAction(
                    title: 'Entradas',
                    actionLabel: 'Adicionar',
                    onPressed: onNewSale,
                  ),
                  _SaleList(sales: received.take(5).toList(growable: false)),
                ],
                right: [
                  _SectionHeaderAction(
                    title: 'Saidas',
                    actionLabel: 'Adicionar',
                    onPressed: onNewExpense,
                  ),
                  _MovementList(expenses: businessExpenses.take(6).toList()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProjetosScreen extends StatelessWidget {
  const ProjetosScreen({super.key, required this.onNewSale});

  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        services.projects,
        services.sales,
        services.clients,
      ]),
      builder: (context, _) {
        final records = services.projects.projects;
        final derived = _projectSummaries(services.sales.sales);
        final portfolio = records.isEmpty
            ? _sum(derived.map((item) => item.total))
            : _sum(records.map((item) => item.budgetAmount));
        final pending = _sum(derived.map((item) => item.openAmount));
        final activeCount = records.isEmpty
            ? derived.length
            : records
                .where((item) => item.status == ProjectStatus.active)
                .length;

        return NexoPageScaffold(
          title: 'Projetos',
          subtitle: 'Carteira de trabalho, etapas e pagamentos por projeto.',
          trailing: Wrap(
            spacing: NexoSpacing.xs,
            runSpacing: NexoSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: () => _openProjectSheet(context),
                icon: const Icon(NexoIcons.add),
                label: const Text('Novo projeto'),
              ),
              OutlinedButton.icon(
                onPressed: onNewSale,
                icon: const Icon(NexoIcons.receipts),
                label: const Text('Venda'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResponsiveCards(
                children: [
                  _KpiCard(
                    icon: NexoIcons.projects,
                    label: 'Valor em carteira',
                    value: MoneyUtils.format(portfolio),
                    highlighted: true,
                  ),
                  _KpiCard(
                    icon: NexoIcons.projects,
                    label: 'Projetos ativos',
                    value: activeCount.toString(),
                  ),
                  _KpiCard(
                    icon: NexoIcons.receipts,
                    label: 'Recebimento pendente',
                    value: MoneyUtils.format(pending),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.x2l),
              _SectionTitle('Projetos em andamento'),
              if (records.isEmpty && derived.isEmpty)
                NexoEmptyStateCard(
                  title: 'Nenhum projeto ainda',
                  message: 'Crie um projeto ou registre uma venda vinculada.',
                  buttonLabel: 'Novo projeto',
                  onPressed: () => _openProjectSheet(context),
                )
              else if (records.isNotEmpty)
                _ResponsiveCards(
                  children: records
                      .map(
                        (project) => _ProjectRecordCard(
                          project: project,
                          clientName: _clientNameForProject(
                            project,
                            services.clients.clients,
                          ),
                          onDelete: () =>
                              services.projects.deleteProject(project.id),
                        ),
                      )
                      .toList(growable: false),
                )
              else
                _ResponsiveCards(
                  children: derived
                      .map((project) => _ProjectCard(project: project))
                      .toList(growable: false),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProjectSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final clientController = TextEditingController();
    final stageController = TextEditingController(text: 'briefing');
    final budgetController = TextEditingController();
    final notesController = TextEditingController();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: NexoColors.surface,
        builder: (sheetContext) {
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
                  Text(
                    'Novo projeto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Nome do projeto',
                    hint: 'Ex.: Site institucional',
                    controller: nameController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Cliente',
                    hint: 'Opcional',
                    controller: clientController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'Etapa',
                          hint: 'briefing',
                          controller: stageController,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Orcamento',
                          hint: '0,00',
                          controller: budgetController,
                          prefixText: 'R\$ ',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Notas',
                    hint: 'Contexto do projeto',
                    controller: notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoButton(
                    label: 'Salvar projeto',
                    icon: NexoIcons.add,
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        return;
                      }
                      final services = NexoScope.of(context);
                      final clientName = clientController.text.trim();
                      final matchedClient = services.clients.clients
                          .cast<ClientModel?>()
                          .firstWhere(
                            (client) =>
                                client != null &&
                                client.name.trim().toLowerCase() ==
                                    clientName.toLowerCase(),
                            orElse: () => null,
                          );
                      await services.projects.createProject(
                        clientId: matchedClient?.id,
                        name: name,
                        stage: stageController.text,
                        budgetAmount: MoneyUtils.parseInput(
                          budgetController.text,
                        ),
                        notes: notesController.text,
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      nameController.dispose();
      clientController.dispose();
      stageController.dispose();
      budgetController.dispose();
      notesController.dispose();
    }
  }

  String _clientNameForProject(
      ProjectModel project, List<ClientModel> clients) {
    final client = clients.cast<ClientModel?>().firstWhere(
          (item) => item?.id == project.clientId,
          orElse: () => null,
        );
    return client?.name ?? 'Cliente nao vinculado';
  }
}

class RecebimentosScreen extends StatelessWidget {
  const RecebimentosScreen({super.key, required this.onNewSale});

  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        return NexoPageScaffold(
          title: 'Recebimentos',
          subtitle: 'Entradas de dinheiro, taxas e status de pagamento.',
          trailing: FilledButton.icon(
            onPressed: onNewSale,
            icon: const Icon(NexoIcons.add),
            label: const Text('Receber'),
          ),
          child: _SaleList(sales: data.sales),
        );
      },
    );
  }
}

class DespesasScreen extends StatelessWidget {
  const DespesasScreen({super.key, required this.onNewExpense});

  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        return NexoPageScaffold(
          title: 'Despesas',
          subtitle: 'Contas pagas, contas futuras e gastos recorrentes.',
          trailing: FilledButton.icon(
            onPressed: onNewExpense,
            icon: const Icon(NexoIcons.add),
            label: const Text('Nova despesa'),
          ),
          child: _MovementList(expenses: data.expenses),
        );
      },
    );
  }
}

class ParceirosScreen extends StatelessWidget {
  const ParceirosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        final services = NexoScope.of(context);
        final partner = data.summary.partner;
        final openPartnerPayments = services.partnerPayments.openDanielPayments;
        final progress = partner.totalToPay <= 0
            ? 0.0
            : (partner.paid / partner.totalToPay).clamp(0, 1).toDouble();

        return NexoPageScaffold(
          title: 'Parceiros',
          subtitle: 'Daniel e repasses por projeto.',
          child: _TwoColumnStage(
            left: [
              _HeroAmount(
                eyebrow: 'Daniel',
                value: MoneyUtils.format(partner.totalToPay),
                message:
                    '${(progress * 100).round()}% pago. Falta ${MoneyUtils.format(partner.remaining)}.',
              ),
              _ProgressCard(
                title: 'Progresso de pagamento',
                progress: progress,
                leftLabel: 'Pago',
                leftValue: MoneyUtils.format(partner.paid),
                rightLabel: 'Pendente',
                rightValue: MoneyUtils.format(partner.remaining),
              ),
            ],
            right: [
              _SectionTitle('Repasses em aberto'),
              if (openPartnerPayments.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem repasse aberto',
                  message: 'Vendas com Daniel geram repasses automaticamente.',
                )
              else
                ...openPartnerPayments.map(
                  (item) => _PartnerPaymentTile(
                    payment: item,
                    onMarkPaid: () async {
                      await services.partnerPayments.markAsPaid(item);
                      await services.expenses.createExpense(
                        title: item.description,
                        category: 'Daniel',
                        amount: item.amount,
                        scope: ExpenseScope.business,
                        accountName: 'Conta empresa',
                        expenseDate: DateTime.now().toUtc(),
                        notes: 'Pagamento de socio Daniel',
                      );
                    },
                  ),
                ),
              const SizedBox(height: NexoSpacing.lg),
              _SectionTitle('Por projeto'),
              if (partner.projects.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem venda recebida com Daniel',
                  message:
                      'Quando receber vendas com Daniel, elas aparecem aqui.',
                )
              else
                ...partner.projects.map(
                  (item) => _LedgerTile(
                    icon: NexoIcons.partners,
                    title: '${item.clientName} - ${item.projectName}',
                    subtitle: DateLabelUtils.dayLabel(item.date),
                    value: MoneyUtils.format(item.amount),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AssinaturasScreen extends StatelessWidget {
  const AssinaturasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      includeClients: true,
      builder: (context, data) {
        final recurringExpenses =
            data.expenses.where((item) => item.recurrence != null).toList();
        final recurringClients = data.clients
            .where((client) => client.billingType != ClientBillingType.oneOff)
            .toList();

        return NexoPageScaffold(
          title: 'Assinaturas',
          subtitle: 'Recorrencias mensais e anuais da casa e da empresa.',
          child: _TwoColumnStage(
            left: [
              _SectionTitle('Clientes recorrentes'),
              if (recurringClients.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Nenhum cliente recorrente',
                  message: 'Clientes mensais ou anuais aparecem aqui.',
                )
              else
                ...recurringClients.map(
                  (client) => _LedgerTile(
                    icon: NexoIcons.subscriptions,
                    title: client.name,
                    subtitle: client.billingType.label,
                    value: client.status.label,
                  ),
                ),
            ],
            right: [
              _SectionTitle('Gastos recorrentes'),
              if (recurringExpenses.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Nenhuma conta recorrente',
                  message: 'Marque recorrencia ao criar uma despesa.',
                )
              else
                ...recurringExpenses.map(
                  (expense) => _LedgerTile(
                    icon: NexoIcons.expenses,
                    title: expense.title,
                    subtitle:
                        expense.recurrence == 'annual' ? 'Anual' : 'Mensal',
                    value: MoneyUtils.format(expense.amount),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlanejamentoScreen extends StatelessWidget {
  const PlanejamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        final services = NexoScope.of(context);
        final lastForecast = data.summary.forecasts.last;
        final openReminders = services.reminders.reminders
            .where((item) => item.status == ReminderStatus.open)
            .take(4)
            .toList(growable: false);
        return NexoPageScaffold(
          title: 'Planejamento',
          subtitle: 'Previsao financeira para os proximos dias.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroAmount(
                eyebrow: 'Resultado futuro',
                value: MoneyUtils.format(lastForecast.projectedMoney),
                message: lastForecast.message,
              ),
              const SizedBox(height: NexoSpacing.x2l),
              _ResponsiveCards(
                children: data.summary.forecasts
                    .map(
                      (forecast) => _KpiCard(
                        icon: NexoIcons.planning,
                        label: '${forecast.days} dias',
                        value: MoneyUtils.format(forecast.projectedMoney),
                        footnote:
                            'Entram ${MoneyUtils.format(forecast.toReceive)} | saem ${MoneyUtils.format(forecast.toPay)}',
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: NexoSpacing.x2l),
              _TwoColumnStage(
                left: [
                  _SectionTitle('Dinheiro que vai entrar'),
                  _SaleList(sales: data.summary.upcomingReceipts),
                ],
                right: [
                  _SectionTitle('Contas e compromissos'),
                  _MovementList(expenses: data.summary.upcomingBills),
                  if (openReminders.isNotEmpty) ...[
                    _SectionTitle('Alertas e lembretes'),
                    ...openReminders.map(
                      (reminder) => _LedgerTile(
                        icon: NexoIcons.planning,
                        title: reminder.title,
                        subtitle: DateLabelUtils.dayLabel(
                          reminder.dueDate.toLocal(),
                        ),
                        value: reminder.status.label,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    return AnimatedBuilder(
      animation:
          Listenable.merge([services.goals, services.sales, services.expenses]),
      builder: (context, _) {
        final summary = LifeFinanceService.summarize(
          sales: services.sales.sales,
          expenses: services.expenses.expenses,
          goals: services.goals.goals,
        );
        return NexoPageScaffold(
          title: 'Metas',
          subtitle: 'Guardar dinheiro com previsao clara.',
          trailing: FilledButton.icon(
            onPressed: () => _openGoalSheet(context),
            icon: const Icon(NexoIcons.add),
            label: const Text('Nova meta'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalCard(goal: summary.goal),
              const SizedBox(height: NexoSpacing.x2l),
              _SectionTitle('Seus objetivos'),
              const SizedBox(height: NexoSpacing.md),
              if (services.goals.goals.isEmpty)
                NexoEmptyStateCard(
                  title: 'Nenhuma meta cadastrada',
                  message: 'Crie uma meta para acompanhar dinheiro guardado.',
                  buttonLabel: 'Nova meta',
                  onPressed: () => _openGoalSheet(context),
                )
              else
                _ResponsiveCards(
                  children: services.goals.goals
                      .map(
                        (goal) => _GoalRecordCard(
                          goal: goal,
                          onDelete: () => services.goals.deleteGoal(goal.id),
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

  Future<void> _openGoalSheet(BuildContext context) async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: NexoColors.surface,
        builder: (sheetContext) {
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
                  Text('Nova meta',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Titulo',
                    hint: 'Ex.: Reserva de emergencia',
                    controller: titleController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Valor alvo',
                    hint: '0,00',
                    controller: targetController,
                    prefixText: 'R\$ ',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Ja guardado',
                    hint: '0,00',
                    controller: currentController,
                    prefixText: 'R\$ ',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoButton(
                    label: 'Salvar meta',
                    icon: NexoIcons.add,
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final target =
                          MoneyUtils.parseInput(targetController.text);
                      if (title.isEmpty || target <= 0) {
                        return;
                      }
                      await NexoScope.of(context).goals.createGoal(
                            title: title,
                            targetAmount: target,
                            currentAmount:
                                MoneyUtils.parseInput(currentController.text),
                          );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      titleController.dispose();
      targetController.dispose();
      currentController.dispose();
    }
  }
}

class InteligenciaScreen extends StatelessWidget {
  const InteligenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FinancePageBuilder(
      builder: (context, data) {
        return NexoPageScaffold(
          title: 'Análise',
          subtitle: 'Recomendacoes baseadas nos dados reais do Nexo.',
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bom dia. Aqui esta o seu panorama de hoje.',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: NexoColors.accent,
                    ),
              ),
              const SizedBox(height: NexoSpacing.x2l),
              ...data.summary.todayActions.map(
                (item) => _InsightCard(
                  icon: _priorityIcon(item.priority),
                  title: item.title,
                  message: item.message,
                ),
              ),
              ...data.summary.alerts.map(
                (alert) => _InsightCard(
                  icon: NexoIcons.intelligence,
                  title: alert.title,
                  message: alert.message,
                ),
              ),
              _PromptBar(summary: data.summary),
            ],
          ),
        );
      },
    );
  }
}

class AnotacoesScreen extends StatelessWidget {
  const AnotacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    return AnimatedBuilder(
      animation: services.notes,
      builder: (context, _) {
        return NexoPageScaffold(
          title: 'Anotacoes',
          subtitle: 'Observacoes importantes para nao perder contexto.',
          trailing: FilledButton.icon(
            onPressed: () => _openNoteSheet(context),
            icon: const Icon(NexoIcons.add),
            label: const Text('Nova anotacao'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroAmount(
                eyebrow: 'Memoria do sistema',
                value: services.notes.notes.length.toString(),
                message:
                    'Notas sincronizadas para ideias, reunioes e detalhes financeiros.',
              ),
              const SizedBox(height: NexoSpacing.x2l),
              if (services.notes.notes.isEmpty)
                NexoEmptyStateCard(
                  title: 'Nenhuma anotacao ainda',
                  message: 'Crie uma nota rapida para guardar contexto.',
                  buttonLabel: 'Nova anotacao',
                  onPressed: () => _openNoteSheet(context),
                )
              else
                _ResponsiveCards(
                  children: services.notes.notes
                      .map(
                        (note) => _NoteRecordCard(
                          note: note,
                          onEdit: () => _openNoteSheet(context, note: note),
                          onDelete: () => services.notes.deleteNote(note.id),
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

  Future<void> _openNoteSheet(BuildContext context, {NoteModel? note}) async {
    final details = note == null
        ? const NoteDetails(content: '')
        : NoteDetails.fromBody(note.body);
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: details.content);
    final categoryController =
        TextEditingController(text: details.category ?? '');
    final reminderController = TextEditingController(
      text: details.reminderAt == null
          ? ''
          : '${details.reminderAt!.toLocal().day.toString().padLeft(2, '0')}/${details.reminderAt!.toLocal().month.toString().padLeft(2, '0')}/${details.reminderAt!.toLocal().year}',
    );
    var isPinned = details.isPinned;
    var isImportant = details.isImportant;
    var isDone = details.isDone;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: NexoColors.surface,
        builder: (sheetContext) {
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
                  Text(note == null ? 'Nova anotacao' : 'Editar anotacao',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Titulo',
                    hint: 'Ex.: Reuniao com cliente',
                    controller: titleController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Texto',
                    hint: 'Escreva a ideia, reuniao ou observacao',
                    controller: bodyController,
                    maxLines: 5,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Categoria',
                    hint: 'Casa, cliente, compra, Serasa...',
                    controller: categoryController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Lembrete',
                    hint: 'dd/mm/aaaa',
                    controller: reminderController,
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Wrap(
                        spacing: NexoSpacing.sm,
                        children: [
                          FilterChip(
                            label: const Text('Fixada'),
                            selected: isPinned,
                            onSelected: (value) =>
                                setState(() => isPinned = value),
                          ),
                          FilterChip(
                            label: const Text('Importante'),
                            selected: isImportant,
                            onSelected: (value) =>
                                setState(() => isImportant = value),
                          ),
                          FilterChip(
                            label: const Text('Concluida'),
                            selected: isDone,
                            onSelected: (value) =>
                                setState(() => isDone = value),
                          ),
                        ],
                      );
                    },
                  ),
                  if (details.previousContent?.isNotEmpty == true) ...[
                    const SizedBox(height: NexoSpacing.md),
                    TextButton.icon(
                      onPressed: () =>
                          bodyController.text = details.previousContent!,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Desfazer ultima alteracao'),
                    ),
                  ],
                  const SizedBox(height: NexoSpacing.lg),
                  NexoButton(
                    label: note == null ? 'Salvar anotacao' : 'Salvar edicao',
                    icon: NexoIcons.add,
                    onPressed: () async {
                      final body = bodyController.text.trim();
                      if (body.isEmpty) {
                        return;
                      }
                      final reminderAt =
                          _parseNoteDate(reminderController.text);
                      final scope = NexoScope.of(context);
                      final next = NoteDetails(
                        content: body,
                        category: categoryController.text,
                        reminderAt: reminderAt,
                        isPinned: isPinned,
                        isImportant: isImportant,
                        isDone: isDone,
                        previousContent:
                            details.content.isEmpty ? null : details.content,
                      );
                      if (note == null) {
                        await scope.notes.createNote(
                          title: titleController.text,
                          body: body,
                          category: categoryController.text,
                          reminderAt: reminderAt,
                          isPinned: isPinned,
                          isImportant: isImportant,
                        );
                      } else {
                        await scope.notes.updateNoteDetails(
                          note,
                          next,
                          title: titleController.text,
                        );
                      }
                      if (reminderAt != null) {
                        await scope.reminders.createReminder(
                          title: titleController.text.trim().isEmpty
                              ? body.split('\n').first
                              : titleController.text,
                          description: body,
                          dueDate: reminderAt,
                          relatedTable: 'notes',
                          relatedId: note?.id,
                        );
                      }
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      titleController.dispose();
      bodyController.dispose();
      categoryController.dispose();
      reminderController.dispose();
    }
  }

  DateTime? _parseNoteDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day, 9).toUtc();
  }
}

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NexoPageScaffold(
      title: 'Configuracoes',
      subtitle: 'Preferencias, usuarios e ajustes do aplicativo.',
      child: NexoEmptyStateCard(
        title: 'Sistema conectado',
        message:
            'Seus dados continuam sincronizados. Ajustes de usuarios e preferencias aparecem aqui.',
      ),
    );
  }
}

class _FinanceData {
  const _FinanceData({
    required this.sales,
    required this.expenses,
    required this.clients,
    required this.goals,
    required this.summary,
  });

  final List<SaleModel> sales;
  final List<ExpenseModel> expenses;
  final List<ClientModel> clients;
  final List<GoalModel> goals;
  final LifeFinanceSummary summary;
}

class _FinancePageBuilder extends StatelessWidget {
  const _FinancePageBuilder({
    required this.builder,
    this.includeClients = false,
  });

  final Widget Function(BuildContext context, _FinanceData data) builder;
  final bool includeClients;

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    return AnimatedBuilder(
      animation: includeClients
          ? Listenable.merge(
              [
                services.sales,
                services.expenses,
                services.clients,
                services.goals,
                services.partnerPayments,
                services.reminders,
              ],
            )
          : Listenable.merge(
              [
                services.sales,
                services.expenses,
                services.goals,
                services.partnerPayments,
                services.reminders,
              ],
            ),
      builder: (context, _) {
        final sales = services.sales.sales;
        final expenses = services.expenses.expenses;
        final goals = services.goals.goals;
        return builder(
          context,
          _FinanceData(
            sales: sales,
            expenses: expenses,
            clients: services.clients.clients,
            goals: goals,
            summary: LifeFinanceService.summarize(
              sales: sales,
              expenses: expenses,
              goals: goals,
            ),
          ),
        );
      },
    );
  }
}

class _TwoColumnStage extends StatelessWidget {
  const _TwoColumnStage({
    required this.left,
    required this.right,
  });

  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [...left, ...right].withSpacing(NexoSpacing.lg),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: left.withSpacing(NexoSpacing.lg),
              ),
            ),
            const SizedBox(width: NexoSpacing.x2l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: right.withSpacing(NexoSpacing.lg),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 980
            ? (constraints.maxWidth - (NexoSpacing.md * 2)) / 3
            : constraints.maxWidth >= 640
                ? (constraints.maxWidth - NexoSpacing.md) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: NexoSpacing.md,
          runSpacing: NexoSpacing.md,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({
    required this.eyebrow,
    required this.value,
    required this.message,
  });

  final String eyebrow;
  final String value;
  final String message;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      backgroundColor: NexoColors.accentSoft,
      borderColor: NexoColors.accent.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(NexoSpacing.x2l),
      radius: NexoRadius.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: NexoColors.inkMedium,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 48,
                  color: NexoColors.inkHigh,
                ),
          ),
          const SizedBox(height: NexoSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NexoColors.inkMedium,
                ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footnote,
    this.large = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? footnote;
  final bool large;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      backgroundColor:
          highlighted ? NexoColors.accentSoft : NexoColors.surfaceElevated,
      borderColor: NexoColors.border.withValues(alpha: 0.18),
      radius: NexoRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NexoColors.accent),
          const SizedBox(height: NexoSpacing.lg),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: NexoSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: large ? 34 : 24,
                  color: NexoColors.inkHigh,
                ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: NexoSpacing.sm),
            Text(footnote!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _SectionHeaderAction extends StatelessWidget {
  const _SectionHeaderAction({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title)),
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(NexoIcons.add, size: 16),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _SaleList extends StatelessWidget {
  const _SaleList({required this.sales});

  final List<SaleModel> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const NexoEmptyStateCard(
        title: 'Nenhum recebimento',
        message: 'Registros aparecem aqui quando houver vendas.',
      );
    }

    return Column(
      children: sales
          .map(
            (sale) => _LedgerTile(
              icon: NexoIcons.receipts,
              title: sale.clientName,
              subtitle: '${sale.serviceName} | ${sale.status.label}',
              value: MoneyUtils.format(sale.ownerAmount),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MovementList extends StatelessWidget {
  const _MovementList({required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const NexoEmptyStateCard(
        title: 'Nada registrado',
        message: 'Quando houver gastos, eles aparecem aqui.',
      );
    }

    return Column(
      children: expenses
          .map(
            (expense) => _LedgerTile(
              icon: _categoryIcon(expense.category),
              title: expense.title,
              subtitle: '${expense.category} | ${expense.scope.label}',
              value: '- ${MoneyUtils.format(expense.amount)}',
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
      child: NexoCard(
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(NexoSpacing.md),
        radius: NexoRadius.xl,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: NexoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(NexoRadius.md),
              ),
              child: Icon(icon, color: NexoColors.inkMedium, size: 20),
            ),
            const SizedBox(width: NexoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: NexoSpacing.xxs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: NexoSpacing.md),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _PartnerPaymentTile extends StatelessWidget {
  const _PartnerPaymentTile({
    required this.payment,
    required this.onMarkPaid,
  });

  final PartnerPaymentModel payment;
  final Future<void> Function() onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
      child: NexoCard(
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(NexoSpacing.md),
        radius: NexoRadius.xl,
        child: Row(
          children: [
            const Icon(NexoIcons.partners, color: NexoColors.accent),
            const SizedBox(width: NexoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.description,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: NexoSpacing.xxs),
                  Text(
                    '${DateLabelUtils.dayLabel(payment.dueDate.toLocal())} | ${payment.status.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: NexoSpacing.md),
            Text(
              MoneyUtils.format(payment.amount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: NexoSpacing.sm),
            TextButton(
              onPressed: onMarkPaid,
              child: const Text('Marcar pago'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    final forecast = switch (goal.monthsToReach) {
      0 => 'Meta batida',
      null => 'Sem previsao',
      final months => '$months mes(es)',
    };

    return NexoCard(
      radius: NexoRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: NexoSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(NexoRadius.pill),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: NexoColors.surfaceMuted,
              color: NexoColors.accent,
            ),
          ),
          const SizedBox(height: NexoSpacing.md),
          _ValueLine('Guardado', MoneyUtils.format(goal.saved)),
          _ValueLine('Meta', MoneyUtils.format(goal.target)),
          _ValueLine('Previsao', forecast),
        ],
      ),
    );
  }
}

class _GoalRecordCard extends StatelessWidget {
  const _GoalRecordCard({
    required this.goal,
    required this.onDelete,
  });

  final GoalModel goal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: [
        goal.title,
        MoneyUtils.format(goal.currentAmount),
        MoneyUtils.format(goal.targetAmount),
        goal.status.label,
      ].join('\n'),
      child: NexoCard(
        radius: NexoRadius.xl,
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir meta',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: NexoSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(NexoRadius.pill),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: NexoColors.surfaceMuted,
                color: NexoColors.accent,
              ),
            ),
            const SizedBox(height: NexoSpacing.md),
            _ValueLine('Guardado', MoneyUtils.format(goal.currentAmount)),
            _ValueLine('Meta', MoneyUtils.format(goal.targetAmount)),
            _ValueLine('Falta', MoneyUtils.format(goal.remaining)),
            _ValueLine('Status', goal.status.label),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.progress,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String title;
  final double progress;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: NexoSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(NexoRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: NexoColors.surfaceMuted,
              color: NexoColors.accent,
            ),
          ),
          const SizedBox(height: NexoSpacing.lg),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      icon: NexoIcons.income,
                      label: leftLabel,
                      value: leftValue)),
              const SizedBox(width: NexoSpacing.md),
              Expanded(
                  child: _KpiCard(
                      icon: NexoIcons.expense,
                      label: rightLabel,
                      value: rightValue)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final _ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: [
        project.name,
        project.clientName,
        MoneyUtils.format(project.total),
        MoneyUtils.format(project.received),
        MoneyUtils.format(project.openAmount),
      ].join('\n'),
      child: NexoCard(
        radius: NexoRadius.hero,
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: NexoSpacing.xxs),
                      Text(project.clientName,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _StatusPill(project.openAmount > 0 ? 'Aberto' : 'Em dia'),
              ],
            ),
            const SizedBox(height: NexoSpacing.xl),
            _ValueLine('Total do contrato', MoneyUtils.format(project.total)),
            _ValueLine('Recebido', MoneyUtils.format(project.received)),
            _ValueLine('Falta pagar', MoneyUtils.format(project.openAmount)),
            const SizedBox(height: NexoSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(NexoRadius.pill),
              child: LinearProgressIndicator(
                value: project.progress,
                minHeight: 8,
                backgroundColor: NexoColors.surfaceMuted,
                color: NexoColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectRecordCard extends StatelessWidget {
  const _ProjectRecordCard({
    required this.project,
    required this.clientName,
    required this.onDelete,
  });

  final ProjectModel project;
  final String clientName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = project.budgetAmount <= 0
        ? 0.0
        : project.status == ProjectStatus.completed
            ? 1.0
            : 0.35;

    return Semantics(
      container: true,
      label: [
        project.name,
        clientName,
        project.stage,
        project.status.label,
        MoneyUtils.format(project.budgetAmount),
      ].join('\n'),
      child: NexoCard(
        radius: NexoRadius.hero,
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: NexoSpacing.xxs),
                      Text(clientName,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acoes do projeto',
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: NexoSpacing.xl),
            _ValueLine('Etapa', project.stage),
            _ValueLine('Status', project.status.label),
            _ValueLine('Orcamento', MoneyUtils.format(project.budgetAmount)),
            if (project.dueDate != null)
              _ValueLine(
                'Prazo',
                DateLabelUtils.dayLabel(project.dueDate!.toLocal()),
              ),
            const SizedBox(height: NexoSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(NexoRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: NexoColors.surfaceMuted,
                color: NexoColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            label == 'Em dia' ? NexoColors.successSoft : NexoColors.warningSoft,
        borderRadius: BorderRadius.circular(NexoRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color:
                  label == 'Em dia' ? NexoColors.success : NexoColors.warning,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: NexoSpacing.md),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
              child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexoSpacing.md),
      child: NexoCard(
        radius: NexoRadius.xl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NexoColors.accent),
            const SizedBox(width: NexoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: NexoSpacing.xs),
                  Text(message, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRecordCard extends StatelessWidget {
  const _NoteRecordCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = NoteDetails.fromBody(note.body);
    return Semantics(
      container: true,
      label: [
        note.title,
        details.content,
        DateLabelUtils.dayLabel(note.updatedAt.toLocal()),
      ].join('\n'),
      child: NexoCard(
        onTap: onEdit,
        radius: NexoRadius.xl,
        backgroundColor: NexoColors.surfaceElevated,
        borderColor: NexoColors.border.withValues(alpha: 0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar anotacao',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Excluir anotacao',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: NexoSpacing.sm),
            Text(
              details.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NexoColors.inkMedium,
                  ),
            ),
            const SizedBox(height: NexoSpacing.lg),
            Text(
              [
                if (details.category?.isNotEmpty == true) details.category!,
                DateLabelUtils.dayLabel(note.updatedAt.toLocal()),
                if (details.isPinned) 'Fixada',
                if (details.isImportant) 'Importante',
              ].join(' | '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptBar extends StatelessWidget {
  const _PromptBar({required this.summary});

  final LifeFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final safe = summary.freeMoney - summary.toPay7Days;
    return NexoCard(
      radius: NexoRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: NexoSpacing.lg,
        vertical: NexoSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: NexoColors.accent),
          const SizedBox(width: NexoSpacing.md),
          Expanded(
            child: Text(
              safe > 0
                  ? 'Pergunta respondida: ha ${MoneyUtils.format(safe)} livre depois das contas.'
                  : 'Pergunta respondida: melhor segurar gastos hoje.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ProjectSummary {
  const _ProjectSummary({
    required this.name,
    required this.clientName,
    required this.total,
    required this.received,
    required this.openAmount,
  });

  final String name;
  final String clientName;
  final double total;
  final double received;
  final double openAmount;

  double get progress {
    if (total <= 0) {
      return 0;
    }
    return (received / total).clamp(0, 1).toDouble();
  }
}

List<_ProjectSummary> _projectSummaries(List<SaleModel> sales) {
  final groups = <String, List<SaleModel>>{};
  for (final sale in sales) {
    final name = sale.projectGroup?.trim().isNotEmpty == true
        ? sale.projectGroup!.trim()
        : sale.serviceName;
    groups.putIfAbsent(name, () => <SaleModel>[]).add(sale);
  }

  final projects = groups.entries.map((entry) {
    final sales = entry.value;
    return _ProjectSummary(
      name: entry.key,
      clientName: sales.first.clientName,
      total: _sum(sales.map((sale) => sale.grossAmount)),
      received: _sum(sales
          .where((sale) => sale.status == SaleStatus.received)
          .map((sale) => sale.ownerAmount)),
      openAmount: _sum(sales
          .where((sale) =>
              sale.status == SaleStatus.pending ||
              sale.status == SaleStatus.late)
          .map((sale) => sale.ownerAmount)),
    );
  }).toList(growable: false)
    ..sort((left, right) => right.total.compareTo(left.total));

  return projects;
}

Map<String, double> _sumExpensesByCategory(List<ExpenseModel> expenses) {
  final result = <String, double>{};
  for (final expense in expenses) {
    result.update(
      expense.category,
      (current) => _money(current + expense.amount),
      ifAbsent: () => expense.amount,
    );
  }
  return result;
}

IconData _categoryIcon(String category) {
  final text = category.toLowerCase();
  if (text.contains('mercado') || text.contains('aliment')) {
    return Icons.shopping_cart_rounded;
  }
  if (text.contains('beb') || text.contains('saude')) {
    return Icons.child_care_rounded;
  }
  if (text.contains('energia') || text.contains('luz')) {
    return Icons.bolt_rounded;
  }
  if (text.contains('daniel') || text.contains('socio')) {
    return NexoIcons.partners;
  }
  if (text.contains('software') || text.contains('ferrament')) {
    return Icons.build_rounded;
  }
  return Icons.receipt_long_rounded;
}

IconData _priorityIcon(ActionPriority priority) {
  return switch (priority) {
    ActionPriority.high => Icons.warning_rounded,
    ActionPriority.medium => Icons.lightbulb_rounded,
    ActionPriority.low => Icons.check_circle_rounded,
  };
}

double _sum(Iterable<double> values) {
  return _money(values.fold<double>(0, (total, value) => total + value));
}

double _money(double value) {
  return (value * 100).roundToDouble() / 100;
}

extension _WidgetSpacing on List<Widget> {
  List<Widget> withSpacing(double spacing) {
    if (isEmpty) {
      return this;
    }
    final spaced = <Widget>[];
    for (var index = 0; index < length; index += 1) {
      if (index > 0) {
        spaced.add(SizedBox(height: spacing));
      }
      spaced.add(this[index]);
    }
    return spaced;
  }
}
