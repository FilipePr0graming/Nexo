import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_radius.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/design_system/nexo_typography.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/cards/nexo_alert_card.dart';
import '../../../../shared/components/cards/nexo_card.dart';
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
            .where((sale) =>
                sale.status == SaleStatus.pending ||
                sale.status == SaleStatus.late)
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
            businessExpenses.fold<double>(
                0, (total, expense) => total + expense.amount);
        final personalBalance = -personalExpenses.fold<double>(
            0, (total, expense) => total + expense.amount);
        final totalBalance = businessBalance + personalBalance;

        final receivedToday = receivedSales
            .where((sale) =>
                DateLabelUtils.isSameDay(sale.movementDate.toLocal(), now))
            .fold<double>(0, (total, sale) => total + sale.ownerAmount);
        final pendingAmount = pendingSales.fold<double>(
            0, (total, sale) => total + sale.ownerAmount);
        final monthlyExpenses = expenses
            .where((expense) => DateLabelUtils.isInCurrentMonth(
                expense.expenseDate.toLocal(), now))
            .fold<double>(0, (total, expense) => total + expense.amount);
        final danielThisMonth = sales
            .where((sale) => DateLabelUtils.isInCurrentMonth(
                sale.movementDate.toLocal(), now))
            .fold<double>(0, (total, sale) => total + sale.danielValue);

        final totalSalesAmount = receivedSales.fold<double>(
          0,
          (total, sale) => total + sale.ownerAmount,
        );

        final last30DaysAmount = receivedSales
            .where(
              (sale) => sale.movementDate
                  .toLocal()
                  .isAfter(now.subtract(const Duration(days: 30))),
            )
            .fold<double>(0, (total, sale) => total + sale.ownerAmount);

        final greetingName = _resolveGreetingName();
        final greetingLabel = _dayGreeting(now);

        final alerts = _buildAlerts(sales, expenses);
        final movements = _buildRecentMovements(sales, expenses);
        final width = MediaQuery.sizeOf(context).width;
        final isDesktop = width >= 1024;

        if (isDesktop) {
          return _DesktopDashboard(
            totalBalance: totalBalance,
            businessBalance: businessBalance,
            personalBalance: personalBalance,
            receivedToday: receivedToday,
            pendingAmount: pendingAmount,
            monthlyExpenses: monthlyExpenses,
            danielThisMonth: danielThisMonth,
            alerts: alerts,
            movements: movements,
            onNewSale: onNewSale,
            onNewExpense: onNewExpense,
            onOpenClients: onOpenClients,
            onRefresh: () {
              salesService.refresh();
              expensesService.refresh();
            },
            errorMessage:
                salesService.errorMessage ?? expensesService.errorMessage,
          );
        }

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              NexoSpacing.md,
              NexoSpacing.md,
              NexoSpacing.md,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileTopHeader(
                  greeting: '$greetingLabel,',
                  name: greetingName,
                ),
                const SizedBox(height: NexoSpacing.lg),
                _WalletHeroCard(
                  total: MoneyUtils.format(totalBalance),
                  business: MoneyUtils.format(businessBalance),
                  personal: MoneyUtils.format(personalBalance),
                ),
                const SizedBox(height: NexoSpacing.md),
                _SalesTodayCard(
                  value: MoneyUtils.format(receivedToday),
                ),
                const SizedBox(height: NexoSpacing.lg),
                _LightMetricRow(
                  leftIcon: NexoIcons.chart,
                  leftLabel: 'Vendas totais',
                  leftValue: MoneyUtils.format(totalSalesAmount),
                  rightIcon: NexoIcons.calendar,
                  rightLabel: 'Vendas 30 dias',
                  rightValue: MoneyUtils.format(last30DaysAmount),
                ),
                const SizedBox(height: NexoSpacing.xl),
                _RevenueChartSection(
                  title: 'Receita dos ultimos 7 dias',
                  points: _last7DaysRevenue(receivedSales, now),
                ),
                const SizedBox(height: NexoSpacing.x2l),
                const NexoSectionHeader(title: 'Atalhos'),
                const SizedBox(height: NexoSpacing.md),
                _QuickActionsGrid(
                  children: [
                    NexoQuickActionCard(
                      icon: NexoIcons.newSale,
                      title: 'Nova venda',
                      caption: 'Registrar entrada com comissao.',
                      onTap: onNewSale,
                    ),
                    NexoQuickActionCard(
                      icon: NexoIcons.newExpense,
                      title: 'Novo gasto',
                      caption: 'Lancar gasto em poucos toques.',
                      onTap: onNewExpense,
                    ),
                    NexoQuickActionCard(
                      icon: NexoIcons.clients,
                      title: 'Clientes',
                      caption: 'Abrir lista e cadastrar novo cliente.',
                      onTap: onOpenClients,
                    ),
                  ],
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
          ),
        );
      },
    );
  }

  static String _dayGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String _resolveGreetingName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata;
      final name = (metadata?['name'] ?? metadata?['full_name'])?.toString();
      if (name != null && name.trim().isNotEmpty) return name.trim();

      final email = user?.email;
      if (email != null && email.contains('@')) {
        final raw = email.split('@').first;
        if (raw.trim().isNotEmpty) {
          final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ').trim();
          if (cleaned.isNotEmpty) {
            final parts = cleaned.split(RegExp(r'\s+'));
            final first = parts.first;
            return first.isEmpty
                ? 'Filipe'
                : '${first[0].toUpperCase()}${first.substring(1)}';
          }
        }
      }
    } catch (_) {}

    return 'Filipe';
  }

  static List<double> _last7DaysRevenue(
    List<SaleModel> receivedSales,
    DateTime now,
  ) {
    final buckets = List<double>.filled(7, 0);
    final today = DateTime(now.year, now.month, now.day);

    for (final sale in receivedSales) {
      final date = sale.movementDate.toLocal();
      final d = DateTime(date.year, date.month, date.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < 7) {
        buckets[6 - diff] += sale.ownerAmount;
      }
    }

    return buckets;
  }
}

class _MobileTopHeader extends StatelessWidget {
  const _MobileTopHeader({
    required this.greeting,
    required this.name,
  });

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NexoColors.inkLow,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: NexoSpacing.md),
        _CircleIconButton(
          icon: NexoIcons.bell,
          onTap: () {},
        ),
        const SizedBox(width: NexoSpacing.sm),
        _CircleIconButton(
          icon: NexoIcons.settings,
          onTap: () {},
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexoRadius.pill),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: NexoColors.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: NexoColors.border.withValues(alpha: 0.45),
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: NexoColors.ink),
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.total,
    required this.business,
    required this.personal,
  });

  final String total;
  final String business;
  final String personal;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      radius: NexoRadius.hero,
      padding: const EdgeInsets.all(NexoSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F5E5C),
          Color(0xFF1B4D8B),
        ],
      ),
      borderColor: Colors.white.withValues(alpha: 0.10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x52000000),
          blurRadius: 26,
          offset: Offset(0, 16),
        ),
      ],
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 26,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Minha carteira',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(width: NexoSpacing.sm),
                  Icon(
                    NexoIcons.eye,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.md),
              Text(
                total.replaceFirst('R\$ ', ''),
                style: NexoTypography.monoStyle(
                  size: 34,
                  height: 1.05,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: NexoSpacing.xs),
              Text(
                'Empresa: ${business.replaceFirst('R\$ ', '')}  •  Pessoal: ${personal.replaceFirst('R\$ ', '')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesTodayCard extends StatelessWidget {
  const _SalesTodayCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      radius: NexoRadius.xl,
      padding: const EdgeInsets.all(NexoSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF0E6B64),
          Color(0xFF7CBF6A),
        ],
      ),
      borderColor: Colors.white.withValues(alpha: 0.08),
      boxShadow: const [
        BoxShadow(
          color: Color(0x52000000),
          blurRadius: 22,
          offset: Offset(0, 14),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              NexoIcons.income,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: NexoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendas hoje',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LightMetricRow extends StatelessWidget {
  const _LightMetricRow({
    required this.leftIcon,
    required this.leftLabel,
    required this.leftValue,
    required this.rightIcon,
    required this.rightLabel,
    required this.rightValue,
  });

  final IconData leftIcon;
  final String leftLabel;
  final String leftValue;
  final IconData rightIcon;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LightMetric(
            icon: leftIcon,
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: NexoSpacing.md),
        Expanded(
          child: _LightMetric(
            icon: rightIcon,
            label: rightLabel,
            value: rightValue,
          ),
        ),
      ],
    );
  }
}

class _LightMetric extends StatelessWidget {
  const _LightMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NexoColors.inkLow),
        const SizedBox(width: NexoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NexoColors.inkLow,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueChartSection extends StatelessWidget {
  const _RevenueChartSection({
    required this.title,
    required this.points,
  });

  final String title;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: NexoColors.inkLow,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: NexoSpacing.md),
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _SparklinePainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2433).withValues(alpha: 0.9)
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final minValue = points.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final normalized = (points[i] - minValue) / range;
      final y = size.height - (normalized * (size.height * 0.75)) - 12;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = NexoColors.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.totalBalance,
    required this.businessBalance,
    required this.personalBalance,
    required this.receivedToday,
    required this.pendingAmount,
    required this.monthlyExpenses,
    required this.danielThisMonth,
    required this.alerts,
    required this.movements,
    required this.onNewSale,
    required this.onNewExpense,
    required this.onOpenClients,
    required this.onRefresh,
    required this.errorMessage,
  });

  final double totalBalance;
  final double businessBalance;
  final double personalBalance;
  final double receivedToday;
  final double pendingAmount;
  final double monthlyExpenses;
  final double danielThisMonth;
  final List<_DashboardAlert> alerts;
  final List<_DashboardMovement> movements;
  final VoidCallback onNewSale;
  final VoidCallback onNewExpense;
  final VoidCallback onOpenClients;
  final VoidCallback onRefresh;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NexoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hoje',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              NexoIconButton(
                icon: NexoIcons.refresh,
                tooltip: 'Atualizar',
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: NexoSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: NexoMetricCard(
                  label: 'Saldo geral',
                  value: MoneyUtils.format(totalBalance),
                  footnote:
                      'Empresa: ${MoneyUtils.format(businessBalance)} | Pessoal: ${MoneyUtils.format(personalBalance)}',
                ),
              ),
              const SizedBox(width: NexoSpacing.lg),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _DashboardStatCard(
                      label: 'Recebido hoje',
                      value: MoneyUtils.format(receivedToday),
                      footnote: 'Liquido confirmado',
                      size: _DashboardStatSize.primary,
                    ),
                    const SizedBox(height: NexoSpacing.md),
                    _DashboardStatCard(
                      label: 'A receber',
                      value: MoneyUtils.format(pendingAmount),
                      footnote: 'Pendencias registradas',
                      size: _DashboardStatSize.primary,
                    ),
                    const SizedBox(height: NexoSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardStatCard(
                            label: 'Gastos do mes',
                            value: MoneyUtils.format(monthlyExpenses),
                            footnote: 'Empresa + pessoal',
                            size: _DashboardStatSize.secondary,
                          ),
                        ),
                        const SizedBox(width: NexoSpacing.md),
                        Expanded(
                          child: _DashboardStatCard(
                            label: 'Daniel',
                            value: MoneyUtils.format(danielThisMonth),
                            footnote: 'Comissao no periodo',
                            size: _DashboardStatSize.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NexoSpacing.x2l),
          const NexoSectionHeader(title: 'Acoes rapidas'),
          const SizedBox(height: NexoSpacing.md),
          _QuickActionsGrid(
            children: [
              NexoQuickActionCard(
                icon: NexoIcons.newSale,
                title: 'Nova venda',
                caption: 'Registrar entrada com comissao.',
                onTap: onNewSale,
              ),
              NexoQuickActionCard(
                icon: NexoIcons.newExpense,
                title: 'Novo gasto',
                caption: 'Lancar gasto em poucos toques.',
                onTap: onNewExpense,
              ),
              NexoQuickActionCard(
                icon: NexoIcons.clients,
                title: 'Clientes',
                caption: 'Abrir lista e cadastrar novo cliente.',
                onTap: onOpenClients,
              ),
            ],
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
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: NexoSpacing.lg),
            Text(errorMessage!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

List<_DashboardAlert> _buildAlerts(
  List<SaleModel> sales,
  List<ExpenseModel> expenses,
) {
  final alerts = <_DashboardAlert>[];

  final lateSales =
      sales.where((sale) => sale.status == SaleStatus.late).toList();
  final pendingSales =
      sales.where((sale) => sale.status == SaleStatus.pending).toList();
  final mixedExpenses = expenses.where((expense) {
    final account = expense.accountName.toLowerCase();
    return (expense.scope == ExpenseScope.business &&
            account.contains('pessoal')) ||
        (expense.scope == ExpenseScope.personal &&
            account.contains('empresa'));
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

    final topEntry =
        revenueByPlatform.entries.fold<MapEntry<String, double>?>(
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

enum _DashboardStatSize {
  primary,
  secondary,
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.footnote,
    required this.size,
  });

  final String label;
  final String value;
  final String footnote;
  final _DashboardStatSize size;

  @override
  Widget build(BuildContext context) {
    final isPrimary = size == _DashboardStatSize.primary;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: NexoColors.inkMedium,
          fontWeight: FontWeight.w600,
        );

    final valueStyle = switch (size) {
      _DashboardStatSize.primary => Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
      _DashboardStatSize.secondary => Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
    };

    final footnoteStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: NexoColors.inkLow,
        );

    return NexoCard(
      padding: const EdgeInsets.all(NexoSpacing.xl),
      radius: 22,
      gradient: isPrimary
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C6F6A),
                Color(0xFF2B5EA1),
              ],
            )
          : null,
      backgroundColor: isPrimary ? null : NexoColors.surface,
      borderColor: isPrimary ? Colors.white.withValues(alpha: 0.08) : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x52000000),
          blurRadius: 18,
          offset: Offset(0, 12),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle?.copyWith(
              color: isPrimary ? Colors.white.withValues(alpha: 0.88) : null,
            ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            value,
            style: valueStyle?.copyWith(
              color: isPrimary ? Colors.white : null,
            ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            footnote,
            style: footnoteStyle?.copyWith(
              color:
                  isPrimary ? Colors.white.withValues(alpha: 0.72) : null,
            ),
          ),
        ],
      ),
    );
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
