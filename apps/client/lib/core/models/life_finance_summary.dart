import '../../features/finance/models/expense_model.dart';
import '../../features/finance/models/sale_model.dart';
import '../../shared/components/cards/nexo_alert_card.dart';

class LifeFinanceSummary {
  const LifeFinanceSummary({
    required this.today,
    required this.confirmedEntries,
    required this.businessExpenses,
    required this.personalExpenses,
    required this.committedMoney,
    required this.futureInstallments,
    required this.freeMoney,
    required this.lockedMoney,
    required this.toReceive7Days,
    required this.toPay7Days,
    required this.realProfit,
    required this.housePaidByCompany,
    required this.partner,
    required this.goal,
    required this.todayActions,
    required this.forecasts,
    required this.incomeSuggestions,
    required this.clientInsights,
    required this.decisions,
    required this.alerts,
    required this.upcomingReceipts,
    required this.upcomingBills,
    required this.wallets,
  });

  final TodayMoneySnapshot today;
  final double confirmedEntries;
  final double businessExpenses;
  final double personalExpenses;
  final double committedMoney;
  final double futureInstallments;
  final double freeMoney;
  final double lockedMoney;
  final double toReceive7Days;
  final double toPay7Days;
  final double realProfit;
  final double housePaidByCompany;
  final PartnerSummary partner;
  final GoalSummary goal;
  final List<TodayAction> todayActions;
  final List<CashForecast> forecasts;
  final List<IncomeSuggestion> incomeSuggestions;
  final List<ClientInsight> clientInsights;
  final List<MoneyDecision> decisions;
  final List<MoneyAlert> alerts;
  final List<SaleModel> upcomingReceipts;
  final List<ExpenseModel> upcomingBills;
  final List<WalletBalance> wallets;
}

class WalletBalance {
  const WalletBalance({
    required this.name,
    required this.balance,
  });

  final String name;
  final double balance;
}

enum TodayMoneyStatus {
  seguro,
  atencao,
  risco,
  semDados,
}

class TodayMoneySnapshot {
  const TodayMoneySnapshot({
    required this.saldoTotal,
    required this.entradasHoje,
    required this.entradasProximos7Dias,
    required this.contasProximos7Dias,
    required this.dinheiroComprometido,
    required this.reservaMinima,
    required this.dinheiroLivreHoje,
    required this.statusDoDia,
    required this.mensagemPrincipal,
  });

  final double saldoTotal;
  final double entradasHoje;
  final double entradasProximos7Dias;
  final double contasProximos7Dias;
  final double dinheiroComprometido;
  final double reservaMinima;
  final double dinheiroLivreHoje;
  final TodayMoneyStatus statusDoDia;
  final String mensagemPrincipal;

  bool get hasEnoughData {
    return statusDoDia != TodayMoneyStatus.semDados;
  }

  String get title {
    return switch (statusDoDia) {
      TodayMoneyStatus.seguro => 'Tudo sob controle',
      TodayMoneyStatus.atencao => 'Use com cuidado',
      TodayMoneyStatus.risco => 'Segure gastos agora',
      TodayMoneyStatus.semDados => 'Registre seus movimentos',
    };
  }
}

class MoneyDecision {
  const MoneyDecision({
    required this.title,
    required this.canDo,
    required this.reason,
  });

  final String title;
  final bool canDo;
  final String reason;
}

class MoneyAlert {
  const MoneyAlert({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final NexoAlertTone tone;
}

class PartnerSummary {
  const PartnerSummary({
    required this.totalToPay,
    required this.paid,
    required this.remaining,
    required this.projects,
  });

  final double totalToPay;
  final double paid;
  final double remaining;
  final List<PartnerProjectDebt> projects;
}

class PartnerProjectDebt {
  const PartnerProjectDebt({
    required this.projectName,
    required this.clientName,
    required this.amount,
    required this.date,
  });

  final String projectName;
  final String clientName;
  final double amount;
  final DateTime date;
}

class GoalSummary {
  const GoalSummary({
    required this.title,
    required this.target,
    required this.saved,
    required this.monthlyPace,
    required this.monthsToReach,
  });

  final String title;
  final double target;
  final double saved;
  final double monthlyPace;
  final int? monthsToReach;

  double get progress {
    if (target <= 0) {
      return 0;
    }

    return (saved / target).clamp(0, 1).toDouble();
  }
}

class TodayAction {
  const TodayAction({
    required this.title,
    required this.message,
    required this.priority,
  });

  final String title;
  final String message;
  final ActionPriority priority;
}

enum ActionPriority {
  high,
  medium,
  low,
}

class CashForecast {
  const CashForecast({
    required this.days,
    required this.projectedMoney,
    required this.toReceive,
    required this.toPay,
    required this.message,
  });

  final int days;
  final double projectedMoney;
  final double toReceive;
  final double toPay;
  final String message;
}

class IncomeSuggestion {
  const IncomeSuggestion({
    required this.title,
    required this.amount,
    required this.message,
  });

  final String title;
  final double amount;
  final String message;
}

class ClientInsight {
  const ClientInsight({
    required this.clientName,
    required this.profit,
    required this.openAmount,
    required this.lateCount,
    required this.message,
    required this.keep,
  });

  final String clientName;
  final double profit;
  final double openAmount;
  final int lateCount;
  final String message;
  final bool keep;
}
