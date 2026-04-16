import 'package:flutter/material.dart';

import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    return NexoPageScaffold(
      title: 'Relatorios',
      subtitle: 'Resumo operacional com recortes por periodo, cliente e plataforma.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiGrid(
            isDesktop: isDesktop,
            items: const [
              _KpiItem(
                label: 'Entrou',
                value: 'R\$ 24.300,00',
                footnote: 'Periodo atual',
              ),
              _KpiItem(
                label: 'Saiu',
                value: 'R\$ 7.200,00',
                footnote: 'Gastos + taxas',
              ),
              _KpiItem(
                label: 'Sobrou',
                value: 'R\$ 17.100,00',
                footnote: 'Antes de retiradas',
              ),
              _KpiItem(
                label: 'A receber',
                value: 'R\$ 3.480,00',
                footnote: 'Em aberto',
              ),
            ],
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Por cliente'),
          const SizedBox(height: NexoSpacing.md),
          _BreakdownCard(
            rows: const [
              _BreakdownRow(label: 'Cliente A', value: 'R\$ 6.200,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Cliente B', value: 'R\$ 4.850,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Cliente C', value: 'R\$ 3.100,00', hint: 'Entrou'),
            ],
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Por plataforma'),
          const SizedBox(height: NexoSpacing.md),
          _BreakdownCard(
            rows: const [
              _BreakdownRow(label: 'Pix', value: 'R\$ 12.900,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Cartao', value: 'R\$ 8.140,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Boleto', value: 'R\$ 3.260,00', hint: 'Entrou'),
            ],
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Por periodo'),
          const SizedBox(height: NexoSpacing.md),
          _BreakdownCard(
            rows: const [
              _BreakdownRow(label: 'Ultimos 7 dias', value: 'R\$ 8.400,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Ultimos 30 dias', value: 'R\$ 24.300,00', hint: 'Entrou'),
              _BreakdownRow(label: 'Ultimos 90 dias', value: 'R\$ 61.950,00', hint: 'Entrou'),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.items,
    required this.isDesktop,
  });

  final List<_KpiItem> items;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: NexoMetricCard(
                label: items[i].label,
                value: items[i].value,
                footnote: items[i].footnote,
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: NexoSpacing.md),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          Row(
            children: [
              Expanded(
                child: NexoMetricCard(
                  label: items[i].label,
                  value: items[i].value,
                  footnote: items[i].footnote,
                ),
              ),
              const SizedBox(width: NexoSpacing.md),
              Expanded(
                child: NexoMetricCard(
                  label: items[i + 1].label,
                  value: items[i + 1].value,
                  footnote: items[i + 1].footnote,
                ),
              ),
            ],
          ),
          if (i + 2 < items.length) const SizedBox(height: NexoSpacing.md),
        ],
      ],
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.footnote,
  });

  final String label;
  final String value;
  final String footnote;
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.rows});

  final List<_BreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexoColors.border.withValues(alpha: 0.8)),
        color: NexoColors.surfaceElevated.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _BreakdownTile(row: rows[i]),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                color: NexoColors.divider.withValues(alpha: 0.8),
              ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({required this.row});

  final _BreakdownRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NexoSpacing.lg,
        vertical: NexoSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NexoColors.inkLow,
                      ),
                ),
              ],
            ),
          ),
          Text(
            row.value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}
