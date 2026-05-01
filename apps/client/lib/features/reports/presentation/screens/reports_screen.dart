import 'package:flutter/material.dart';

import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NexoPageScaffold(
      title: 'Relatorios',
      subtitle:
          'Base visual pronta para evoluir em indicadores e comparativos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: NexoMetricCard(
                  label: 'Entrou',
                  value: 'R\$ 24.300,00',
                  footnote: 'Periodo atual',
                ),
              ),
              SizedBox(width: NexoSpacing.md),
              Expanded(
                child: NexoMetricCard(
                  label: 'Sobrou',
                  value: 'R\$ 17.100,00',
                  footnote: 'Antes de retiradas',
                ),
              ),
            ],
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Proximos blocos'),
          const SizedBox(height: NexoSpacing.md),
          const NexoEmptyStateCard(
            title: 'Relatorios entram na fase seguinte',
            message:
                'A shell, a linguagem visual e os componentes de base ja estao prontos para clientes, plataforma, lucro liquido e inadimplencia.',
          ),
        ],
      ),
    );
  }
}
