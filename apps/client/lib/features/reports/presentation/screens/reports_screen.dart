import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/models/life_finance_summary.dart';
import '../../../../core/services/life_finance_service.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_alert_card.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([services.sales, services.expenses]),
      builder: (context, _) {
        final summary = LifeFinanceService.summarize(
          sales: services.sales.sales,
          expenses: services.expenses.expenses,
        );

        return NexoPageScaffold(
          title: 'Planos',
          subtitle: 'Socios, metas e alertas para nao perder dinheiro.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Falta para Daniel',
                      value: MoneyUtils.format(summary.partner.remaining),
                      footnote: 'Pagamento manual',
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: NexoMetricCard(
                      label: 'Meta guardada',
                      value: '${(summary.goal.progress * 100).round()}%',
                      footnote: MoneyUtils.format(summary.goal.saved),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.xl),
              _GoalCard(goal: summary.goal),
              const SizedBox(height: NexoSpacing.xl),
              _PartnerProjects(partner: summary.partner),
              const SizedBox(height: NexoSpacing.xl),
              const NexoSectionHeader(title: 'Alertas'),
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
            ],
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
  });

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    final forecast = switch (goal.monthsToReach) {
      0 => 'Ja bateu',
      null => 'Sem previsao',
      final months => '$months mes(es)',
    };

    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.title,
            style: Theme.of(context).textTheme.titleMedium,
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
          _PlanRow(
            label: 'Guardado',
            value: MoneyUtils.format(goal.saved),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Meta',
            value: MoneyUtils.format(goal.target),
          ),
          const SizedBox(height: NexoSpacing.sm),
          _PlanRow(
            label: 'Previsao',
            value: forecast,
          ),
        ],
      ),
    );
  }
}

class _PartnerProjects extends StatelessWidget {
  const _PartnerProjects({
    required this.partner,
  });

  final PartnerSummary partner;

  @override
  Widget build(BuildContext context) {
    if (partner.projects.isEmpty) {
      return const NexoEmptyStateCard(
        title: 'Nenhum valor para socio',
        message: 'Quando uma venda tiver Daniel, os valores aparecem aqui.',
      );
    }

    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daniel por projeto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexoSpacing.md),
          ...partner.projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
              child: _PlanRow(
                label: '${project.clientName} | ${project.projectName}',
                value: MoneyUtils.format(project.amount),
              ),
            ),
          ),
          const Divider(height: NexoSpacing.xl),
          _PlanRow(
            label: 'Falta pagar',
            value: MoneyUtils.format(partner.remaining),
            strong: true,
          ),
        ],
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
