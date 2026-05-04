import '../../features/finance/models/expense_model.dart';
import '../../features/finance/models/sale_model.dart';
import '../../features/goals/models/goal_model.dart';
import '../../shared/components/cards/nexo_alert_card.dart';
import '../models/life_finance_summary.dart';
import '../utils/date_label_utils.dart';
import '../utils/money_utils.dart';

class LifeFinanceService {
  const LifeFinanceService._();

  static LifeFinanceSummary summarize({
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
    List<GoalModel> goals = const [],
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final weekLimit = today.add(const Duration(days: 7));

    final received = sales
        .where((sale) => sale.status == SaleStatus.received)
        .toList(growable: false);
    final openSales = sales
        .where((sale) =>
            sale.status == SaleStatus.pending || sale.status == SaleStatus.late)
        .toList(growable: false);

    final confirmedEntries = _sum(received.map((sale) => sale.netAmount));
    final businessExpenses = _sum(expenses
        .where((expense) => expense.scope == ExpenseScope.business)
        .map((expense) => expense.amount));
    final personalExpenses = _sum(expenses
        .where((expense) => expense.scope == ExpenseScope.personal)
        .map((expense) => expense.amount));

    final partner = _partnerSummary(received, expenses);
    final committedMoney = partner.remaining;
    final futureInstallments = _sum(received.map(_futureInstallmentReserve));
    final lockedMoney = committedMoney + futureInstallments;
    final realProfit =
        _money(confirmedEntries - businessExpenses - committedMoney);
    final freeMoney = _money(confirmedEntries -
        businessExpenses -
        committedMoney -
        futureInstallments);

    final upcomingReceipts = openSales.where((sale) {
      final due = sale.expectedDate.toLocal();
      return !_isBeforeDay(due, today) && !due.isAfter(weekLimit);
    }).toList(growable: false)
      ..sort((left, right) => left.expectedDate.compareTo(right.expectedDate));

    final upcomingBills = expenses.where((expense) {
      final due = expense.expenseDate.toLocal();
      return !_isBeforeDay(due, today) && !due.isAfter(weekLimit);
    }).toList(growable: false)
      ..sort((left, right) => left.expenseDate.compareTo(right.expenseDate));

    final toReceive7Days =
        _sum(upcomingReceipts.map((sale) => sale.ownerAmount));
    final toPay7Days = _sum(upcomingBills.map((expense) => expense.amount));
    final entriesToday = _sum(received.where((sale) {
      final date = (sale.receivedDate ?? sale.movementDate).toLocal();
      return DateLabelUtils.isSameDay(date, today);
    }).map((sale) => sale.netAmount));
    final housePaidByCompany = _sum(expenses
        .where((expense) =>
            expense.scope == ExpenseScope.personal &&
            _containsBusinessAccount(expense.accountName))
        .map((expense) => expense.amount));

    final goal = _goalSummary(
      freeMoney: freeMoney,
      expenses: expenses,
      goals: goals,
      today: today,
    );
    final todayMoney = _todayMoneySnapshot(
      saldoTotal:
          _money(confirmedEntries - businessExpenses - personalExpenses),
      entradasHoje: entriesToday,
      entradasProximos7Dias: toReceive7Days,
      contasProximos7Dias: toPay7Days,
      partnerRemaining: partner.remaining,
      futureInstallments: futureInstallments,
      goal: goal,
      hasProtectedGoal: goals.any((goal) => goal.status == GoalStatus.active),
      sales: sales,
      expenses: expenses,
    );
    final forecasts = _forecasts(
      freeMoney: todayMoney.dinheiroLivreHoje,
      openSales: openSales,
      expenses: expenses,
      today: today,
    );
    final incomeSuggestions = _incomeSuggestions(
      expectedIncome: toReceive7Days,
      toPay7Days: toPay7Days,
      partnerRemaining: partner.remaining,
      goal: goal,
    );
    final clientInsights = _clientInsights(sales, today);
    final todayActions = _todayActions(
      freeMoney: freeMoney,
      toReceive7Days: toReceive7Days,
      toPay7Days: toPay7Days,
      upcomingReceipts: upcomingReceipts,
      upcomingBills: upcomingBills,
      goal: goal,
      forecasts: forecasts,
    );
    final decisions = _decisions(
      freeMoney: freeMoney,
      toPay7Days: toPay7Days,
      partnerRemaining: partner.remaining,
      goal: goal,
    );
    final alerts = _alerts(
      sales: sales,
      expenses: expenses,
      freeMoney: freeMoney,
      toPay7Days: toPay7Days,
      goal: goal,
      forecasts: forecasts,
      clientInsights: clientInsights,
      today: today,
      weekLimit: weekLimit,
    );

    return LifeFinanceSummary(
      today: todayMoney,
      confirmedEntries: confirmedEntries,
      businessExpenses: businessExpenses,
      personalExpenses: personalExpenses,
      committedMoney: committedMoney,
      futureInstallments: futureInstallments,
      freeMoney: freeMoney,
      lockedMoney: lockedMoney,
      toReceive7Days: toReceive7Days,
      toPay7Days: toPay7Days,
      realProfit: realProfit,
      housePaidByCompany: housePaidByCompany,
      partner: partner,
      goal: goal,
      todayActions: todayActions,
      forecasts: forecasts,
      incomeSuggestions: incomeSuggestions,
      clientInsights: clientInsights,
      decisions: decisions,
      alerts: alerts,
      upcomingReceipts: upcomingReceipts,
      upcomingBills: upcomingBills,
    );
  }

  static TodayMoneySnapshot _todayMoneySnapshot({
    required double saldoTotal,
    required double entradasHoje,
    required double entradasProximos7Dias,
    required double contasProximos7Dias,
    required double partnerRemaining,
    required double futureInstallments,
    required GoalSummary goal,
    required bool hasProtectedGoal,
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
  }) {
    final hasFinancialData = sales.isNotEmpty || expenses.isNotEmpty;
    final protectedGoal = hasProtectedGoal && goal.saved > 0 ? goal.saved : 0.0;
    final reserveMinimum = _reserveMinimum(
      saldoTotal: saldoTotal,
      contasProximos7Dias: contasProximos7Dias,
      protectedGoal: protectedGoal,
      hasFinancialData: hasFinancialData,
    );
    final committed = _money(
      partnerRemaining + futureInstallments + protectedGoal,
    );
    final freeToday = _money(
      saldoTotal - contasProximos7Dias - committed - reserveMinimum,
    );

    if (!hasFinancialData) {
      return const TodayMoneySnapshot(
        saldoTotal: 0,
        entradasHoje: 0,
        entradasProximos7Dias: 0,
        contasProximos7Dias: 0,
        dinheiroComprometido: 0,
        reservaMinima: 0,
        dinheiroLivreHoje: 0,
        statusDoDia: TodayMoneyStatus.semDados,
        mensagemPrincipal:
            'Registre entradas e gastos para eu calcular seu dinheiro livre com seguranca.',
      );
    }

    final status = freeToday < 0 || saldoTotal < contasProximos7Dias
        ? TodayMoneyStatus.risco
        : freeToday < 300 || contasProximos7Dias > 0
            ? TodayMoneyStatus.atencao
            : TodayMoneyStatus.seguro;
    final message = switch (status) {
      TodayMoneyStatus.seguro =>
        'Voce tem ${MoneyUtils.format(freeToday)} livre hoje, depois de separar contas e compromissos.',
      TodayMoneyStatus.atencao =>
        'Voce tem ${MoneyUtils.format(freeToday)} disponivel, mas use com cuidado. Ha contas proximas.',
      TodayMoneyStatus.risco =>
        'Melhor segurar gastos agora. Seu caixa pode apertar nos proximos dias.',
      TodayMoneyStatus.semDados =>
        'Registre entradas e gastos para eu calcular seu dinheiro livre com seguranca.',
    };

    return TodayMoneySnapshot(
      saldoTotal: saldoTotal,
      entradasHoje: entradasHoje,
      entradasProximos7Dias: entradasProximos7Dias,
      contasProximos7Dias: contasProximos7Dias,
      dinheiroComprometido: committed,
      reservaMinima: reserveMinimum,
      dinheiroLivreHoje: freeToday,
      statusDoDia: status,
      mensagemPrincipal: message,
    );
  }

  static double _reserveMinimum({
    required double saldoTotal,
    required double contasProximos7Dias,
    required double protectedGoal,
    required bool hasFinancialData,
  }) {
    if (!hasFinancialData || saldoTotal <= 0) {
      return 0;
    }
    if (protectedGoal > 0) {
      return 0;
    }
    final base = contasProximos7Dias > 0 ? contasProximos7Dias * 0.1 : 100.0;
    return _money(base.clamp(0, saldoTotal * 0.2).toDouble());
  }

  static List<TodayAction> _todayActions({
    required double freeMoney,
    required double toReceive7Days,
    required double toPay7Days,
    required List<SaleModel> upcomingReceipts,
    required List<ExpenseModel> upcomingBills,
    required GoalSummary goal,
    required List<CashForecast> forecasts,
  }) {
    final actions = <TodayAction>[];
    final riskyForecast =
        forecasts.any((forecast) => forecast.projectedMoney < 0);

    if (upcomingReceipts.isNotEmpty) {
      final first = upcomingReceipts.first;
      actions.add(
        TodayAction(
          title: 'Cobrar ${first.clientName}',
          message:
              '${MoneyUtils.format(toReceive7Days)} previstos para entrar nos proximos 7 dias.',
          priority: ActionPriority.high,
        ),
      );
    }

    if (upcomingBills.isNotEmpty) {
      final first = upcomingBills.first;
      actions.add(
        TodayAction(
          title: 'Pagar ${first.title}',
          message:
              'Separe ${MoneyUtils.format(toPay7Days)} para contas da semana.',
          priority: ActionPriority.high,
        ),
      );
    }

    if (freeMoney - toPay7Days < 300 || riskyForecast) {
      actions.add(
        TodayAction(
          title: 'Segurar gastos extras',
          message: 'O dinheiro livre pode apertar depois das contas.',
          priority: ActionPriority.high,
        ),
      );
    }

    if (freeMoney - toPay7Days >= 500 && goal.progress < 1) {
      actions.add(
        TodayAction(
          title: 'Revisar meta ${goal.title}',
          message:
              'Separe pelo menos ${MoneyUtils.format((freeMoney - toPay7Days) * 0.2)} para a reserva.',
          priority: ActionPriority.medium,
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        const TodayAction(
          title: 'Manter o plano',
          message: 'Nao ha urgencia agora. Registre tudo que entrar ou sair.',
          priority: ActionPriority.low,
        ),
      );
    }

    return actions.take(4).toList(growable: false);
  }

  static List<CashForecast> _forecasts({
    required double freeMoney,
    required List<SaleModel> openSales,
    required List<ExpenseModel> expenses,
    required DateTime today,
  }) {
    return [7, 15, 30].map((days) {
      final limit = today.add(Duration(days: days));
      final toReceive = _sum(openSales.where((sale) {
        final due = sale.expectedDate.toLocal();
        return !_isBeforeDay(due, today) && !due.isAfter(limit);
      }).map((sale) => sale.ownerAmount));
      final toPay = _sum(expenses.where((expense) {
        final due = expense.expenseDate.toLocal();
        return !_isBeforeDay(due, today) && !due.isAfter(limit);
      }).map((expense) => expense.amount));
      final projected = _money(freeMoney + toReceive - toPay);
      final message = projected < 0
          ? 'Risco de faltar ${MoneyUtils.format(projected.abs())}.'
          : projected < 500
              ? 'Sobra pouco depois de entradas e contas.'
              : 'Caixa fica positivo depois de cobranças e contas.';

      return CashForecast(
        days: days,
        projectedMoney: projected,
        toReceive: toReceive,
        toPay: toPay,
        message: message,
      );
    }).toList(growable: false);
  }

  static List<IncomeSuggestion> _incomeSuggestions({
    required double expectedIncome,
    required double toPay7Days,
    required double partnerRemaining,
    required GoalSummary goal,
  }) {
    final base = expectedIncome > 0 ? expectedIncome : goal.saved;
    if (base <= 0) {
      return const [
        IncomeSuggestion(
          title: 'Quando entrar dinheiro',
          amount: 0,
          message: 'Registre o recebimento para o app sugerir a divisao.',
        ),
      ];
    }

    final payBills = base < toPay7Days ? base : toPay7Days;
    final payPartner = _money((base - payBills).clamp(0, partnerRemaining));
    final reserve = _money(((base - payBills - payPartner) * 0.3)
        .clamp(0, double.infinity)
        .toDouble());
    final freeUse = _money(base - payBills - payPartner - reserve);

    return [
      IncomeSuggestion(
        title: 'Pagar primeiro',
        amount: payBills,
        message: 'Use isso para contas dos proximos 7 dias.',
      ),
      if (payPartner > 0)
        IncomeSuggestion(
          title: 'Separar Daniel',
          amount: payPartner,
          message: 'Tira esse valor do dinheiro livre.',
        ),
      IncomeSuggestion(
        title: 'Guardar',
        amount: reserve,
        message: 'Vai para a reserva, antes de gastar.',
      ),
      IncomeSuggestion(
        title: 'Uso livre depois',
        amount: freeUse,
        message: freeUse <= 0
            ? 'Por enquanto nao sobra para compras.'
            : 'Use só se nao aparecer conta nova.',
      ),
    ];
  }

  static List<ClientInsight> _clientInsights(
    List<SaleModel> sales,
    DateTime today,
  ) {
    final groups = <String, List<SaleModel>>{};
    for (final sale in sales) {
      final key = sale.clientName.trim().isEmpty ? 'Cliente' : sale.clientName;
      groups.putIfAbsent(key, () => <SaleModel>[]).add(sale);
    }

    final insights = groups.entries.map((entry) {
      final clientSales = entry.value;
      final profit = _sum(clientSales
          .where((sale) => sale.status == SaleStatus.received)
          .map((sale) => sale.ownerAmount));
      final openAmount = _sum(clientSales
          .where((sale) =>
              sale.status == SaleStatus.pending ||
              sale.status == SaleStatus.late)
          .map((sale) => sale.ownerAmount));
      final lateCount = clientSales.where((sale) {
        final due = sale.expectedDate.toLocal();
        return sale.status == SaleStatus.late ||
            (sale.status == SaleStatus.pending && _isBeforeDay(due, today));
      }).length;
      final keep = profit > 0 && lateCount <= 1;
      final message = lateCount >= 2
          ? 'Atrasa demais. Cobre antes de aceitar mais trabalho.'
          : profit <= 0 && openAmount > 0
              ? 'So vale manter se pagar o que falta.'
              : 'Vale manter. Da lucro e nao pesa no caixa.';

      return ClientInsight(
        clientName: entry.key,
        profit: profit,
        openAmount: openAmount,
        lateCount: lateCount,
        message: message,
        keep: keep,
      );
    }).toList(growable: false);

    insights.sort((left, right) {
      if (left.lateCount != right.lateCount) {
        return right.lateCount.compareTo(left.lateCount);
      }
      return right.profit.compareTo(left.profit);
    });

    return insights.take(5).toList(growable: false);
  }

  static PartnerSummary _partnerSummary(
    List<SaleModel> received,
    List<ExpenseModel> expenses,
  ) {
    final projects = received
        .where((sale) => sale.danielValue > 0)
        .map(
          (sale) => PartnerProjectDebt(
            projectName: sale.projectGroup?.trim().isNotEmpty == true
                ? sale.projectGroup!.trim()
                : sale.serviceName,
            clientName: sale.clientName,
            amount: sale.danielValue,
            date: sale.movementDate.toLocal(),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => right.date.compareTo(left.date));

    final totalToPay = _sum(projects.map((project) => project.amount));
    final paid = _sum(expenses
        .where((expense) =>
            expense.scope == ExpenseScope.business && _isDanielPayment(expense))
        .map((expense) => expense.amount));

    return PartnerSummary(
      totalToPay: totalToPay,
      paid: paid > totalToPay ? totalToPay : paid,
      remaining: _money(totalToPay - paid).clamp(0, double.infinity).toDouble(),
      projects: projects,
    );
  }

  static GoalSummary _goalSummary({
    required double freeMoney,
    required List<ExpenseModel> expenses,
    required List<GoalModel> goals,
    required DateTime today,
  }) {
    final activeGoals = goals
        .where((goal) => goal.status == GoalStatus.active)
        .toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    if (activeGoals.isNotEmpty) {
      final goal = activeGoals.first;
      final monthlyPace = freeMoney > 0 ? freeMoney : 0.0;
      final missing = goal.targetAmount - goal.currentAmount;
      final monthsToReach = missing <= 0
          ? 0
          : monthlyPace <= 0
              ? null
              : (missing / monthlyPace).ceil();
      return GoalSummary(
        title: goal.title,
        target: _money(goal.targetAmount),
        saved: _money(goal.currentAmount),
        monthlyPace: _money(monthlyPace),
        monthsToReach: monthsToReach,
      );
    }

    final monthlyExpenses = _sum(expenses
        .where((expense) => DateLabelUtils.isInCurrentMonth(
            expense.expenseDate.toLocal(), today))
        .map((expense) => expense.amount));
    final target = monthlyExpenses <= 0 ? 3000.0 : monthlyExpenses * 3;
    final saved = freeMoney > 0 ? freeMoney : 0.0;
    final monthlyPace = freeMoney > 0 ? freeMoney : 0.0;
    final missing = target - saved;
    final monthsToReach = missing <= 0
        ? 0
        : monthlyPace <= 0
            ? null
            : (missing / monthlyPace).ceil();

    return GoalSummary(
      title: 'Reserva para ficar tranquilo',
      target: _money(target),
      saved: _money(saved),
      monthlyPace: _money(monthlyPace),
      monthsToReach: monthsToReach,
    );
  }

  static List<MoneyDecision> _decisions({
    required double freeMoney,
    required double toPay7Days,
    required double partnerRemaining,
    required GoalSummary goal,
  }) {
    final safeAfterWeek = freeMoney - toPay7Days;
    final canBuy = safeAfterWeek >= 300;
    final canPayDebt = safeAfterWeek >= 800 && partnerRemaining > 0;
    final canInvest = safeAfterWeek >= 1000 && goal.progress >= 0.35;

    return [
      MoneyDecision(
        title: 'Pode comprar?',
        canDo: canBuy,
        reason: canBuy
            ? 'Sim. Ainda sobra ${MoneyUtils.format(safeAfterWeek)} depois das contas da semana.'
            : 'Nao agora. Separe primeiro ${MoneyUtils.format(toPay7Days)} para os proximos 7 dias.',
      ),
      MoneyDecision(
        title: 'Pode pagar divida?',
        canDo: canPayDebt,
        reason: canPayDebt
            ? 'Sim, cabe pagar sem apertar a semana.'
            : partnerRemaining <= 0
                ? 'Nao ha divida de socio aberta no app.'
                : 'Melhor esperar: o dinheiro livre ainda esta curto.',
      ),
      MoneyDecision(
        title: 'Pode investir?',
        canDo: canInvest,
        reason: canInvest
            ? 'Sim. A reserva ja tem base e ainda sobra caixa.'
            : 'Ainda nao. Fortaleça a reserva antes de investir.',
      ),
    ];
  }

  static List<MoneyAlert> _alerts({
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
    required double freeMoney,
    required double toPay7Days,
    required GoalSummary goal,
    required List<CashForecast> forecasts,
    required List<ClientInsight> clientInsights,
    required DateTime today,
    required DateTime weekLimit,
  }) {
    final alerts = <MoneyAlert>[];
    final lateSales = sales.where((sale) {
      final due = sale.expectedDate.toLocal();
      return (sale.status == SaleStatus.late ||
              (sale.status == SaleStatus.pending &&
                  _isBeforeDay(due, today))) &&
          sale.ownerAmount > 0;
    }).toList(growable: false);

    final billsDueSoon = expenses.where((expense) {
      final due = expense.expenseDate.toLocal();
      return !_isBeforeDay(due, today) && !due.isAfter(weekLimit);
    }).toList(growable: false);
    final mixedExpenses = expenses.where((expense) {
      final account = expense.accountName.toLowerCase();
      return (expense.scope == ExpenseScope.personal &&
              _containsBusinessAccount(expense.accountName)) ||
          (expense.scope == ExpenseScope.business &&
              account.contains('pessoal'));
    }).toList(growable: false);
    final highExpense = _highestImpactExpense(expenses, today);
    final riskyForecasts =
        forecasts.where((forecast) => forecast.projectedMoney < 0).toList();
    final badClients = clientInsights
        .where((client) => client.lateCount >= 2 || !client.keep)
        .toList(growable: false);

    if (riskyForecasts.isNotEmpty) {
      final first = riskyForecasts.first;
      alerts.add(
        MoneyAlert(
          title: 'Risco de faltar dinheiro',
          message:
              'Em ${first.days} dias o caixa pode ficar ${MoneyUtils.format(first.projectedMoney)}. Cobre antes de gastar.',
          tone: NexoAlertTone.error,
        ),
      );
    }

    if (billsDueSoon.isNotEmpty) {
      alerts.add(
        MoneyAlert(
          title: 'Conta vencendo',
          message:
              '${billsDueSoon.length} conta(s) somam ${MoneyUtils.format(_sum(billsDueSoon.map((item) => item.amount)))} nos proximos 7 dias.',
          tone: NexoAlertTone.warning,
        ),
      );
    }

    if (lateSales.isNotEmpty) {
      alerts.add(
        MoneyAlert(
          title: 'Cliente atrasado',
          message:
              '${lateSales.length} recebimento(s) atrasados somam ${MoneyUtils.format(_sum(lateSales.map((sale) => sale.ownerAmount)))}.',
          tone: NexoAlertTone.error,
        ),
      );
    }

    if (freeMoney < toPay7Days || freeMoney < 500) {
      alerts.add(
        MoneyAlert(
          title: 'Caixa baixo',
          message:
              'Hoje ha ${MoneyUtils.format(freeMoney)} livre e ${MoneyUtils.format(toPay7Days)} para pagar em 7 dias.',
          tone: NexoAlertTone.error,
        ),
      );
    }

    if (highExpense != null) {
      alerts.add(
        MoneyAlert(
          title: 'Gasto alto',
          message:
              '${highExpense.title} pesou ${MoneyUtils.format(highExpense.amount)}. Confira se precisa repetir.',
          tone: NexoAlertTone.warning,
        ),
      );
    }

    if (badClients.isNotEmpty) {
      final client = badClients.first;
      alerts.add(
        MoneyAlert(
          title: 'Cliente para revisar',
          message: '${client.clientName}: ${client.message}',
          tone: client.lateCount >= 2
              ? NexoAlertTone.error
              : NexoAlertTone.warning,
        ),
      );
    }

    if (mixedExpenses.isNotEmpty) {
      alerts.add(
        MoneyAlert(
          title: 'Casa e empresa misturadas',
          message:
              '${mixedExpenses.length} gasto(s) parecem estar na conta errada. Corrija para saber o lucro real.',
          tone: NexoAlertTone.warning,
        ),
      );
    }

    if (goal.progress < 0.1) {
      alerts.add(
        MoneyAlert(
          title: 'Meta parada',
          message:
              'A reserva ainda esta em ${(goal.progress * 100).round()}%. Separe uma parte do proximo recebimento.',
          tone: NexoAlertTone.warning,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const MoneyAlert(
          title: 'Tudo sob controle',
          message: 'Nenhuma conta urgente ou recebimento atrasado agora.',
          tone: NexoAlertTone.success,
        ),
      );
    }

    return alerts.take(4).toList(growable: false);
  }

  static double _futureInstallmentReserve(SaleModel sale) {
    if (sale.installments <= 1 || sale.status != SaleStatus.received) {
      return 0;
    }

    final futureParts = sale.installments - 1;
    return _money((sale.netAmount / sale.installments) * futureParts);
  }

  static bool _containsBusinessAccount(String accountName) {
    final normalized = accountName.toLowerCase();
    return normalized.contains('empresa') || normalized.contains('business');
  }

  static bool _isDanielPayment(ExpenseModel expense) {
    final text = [
      expense.title,
      expense.category,
      expense.subcategory,
      expense.notes,
    ].whereType<String>().join(' ').toLowerCase();

    return text.contains('daniel') || text.contains('socio');
  }

  static ExpenseModel? _highestImpactExpense(
    List<ExpenseModel> expenses,
    DateTime today,
  ) {
    final monthExpenses = expenses
        .where((expense) => DateLabelUtils.isInCurrentMonth(
            expense.expenseDate.toLocal(), today))
        .toList(growable: false);

    if (monthExpenses.length < 2) {
      return null;
    }

    final average = _sum(monthExpenses.map((expense) => expense.amount)) /
        monthExpenses.length;
    final sorted = [...monthExpenses]
      ..sort((left, right) => right.amount.compareTo(left.amount));
    final highest = sorted.first;

    if (highest.amount >= 500 && highest.amount >= average * 1.8) {
      return highest;
    }

    return null;
  }

  static bool _isBeforeDay(DateTime value, DateTime day) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    return dateOnly.isBefore(dayOnly);
  }

  static double _sum(Iterable<double> values) {
    return _money(values.fold<double>(0, (total, value) => total + value));
  }

  static double _money(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
