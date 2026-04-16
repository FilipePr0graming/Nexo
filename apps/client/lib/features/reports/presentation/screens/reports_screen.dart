import 'package:flutter/material.dart';

import '../../../../core/design_system/nexo_colors.dart';
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
      subtitle: 'Entradas, saidas, lucro e pendencias. Sem ruido, pronto para operar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NexoSectionHeader(title: 'Entradas'),
          const SizedBox(height: NexoSpacing.md),
          const NexoEmptyStateCard(
            title: 'Sem entradas no periodo selecionado',
            message:
                'Assim que houver vendas recebidas, voce vera totais e recortes aqui.',
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Saidas'),
          const SizedBox(height: NexoSpacing.md),
          const NexoEmptyStateCard(
            title: 'Sem saidas no periodo selecionado',
            message:
                'Gastos registrados apareceram aqui com totais por tipo e conta.',
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Lucro'),
          const SizedBox(height: NexoSpacing.md),
          const NexoEmptyStateCard(
            title: 'Lucro aparece quando ha entradas e saidas',
            message:
                'O calculo de lucro liquido vai considerar o que entrou e saiu no periodo.',
          ),
          const SizedBox(height: NexoSpacing.xl),
          const NexoSectionHeader(title: 'Pendencias'),
          const SizedBox(height: NexoSpacing.md),
          const NexoEmptyStateCard(
            title: 'Nenhuma pendencia agora',
            message:
                'Vendas pendentes ou atrasadas aparecem aqui para voce agir rapido.',
          ),
        ],
      ),
    );
  }
}
