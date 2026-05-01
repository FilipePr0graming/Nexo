import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/cards/nexo_metric_card.dart';
import '../../../../shared/components/lists/nexo_list_tile_card.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../../finance/models/sale_model.dart';
import '../../models/client_model.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientId,
  });

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    final clientsService = services.clients;
    final salesService = services.sales;

    return AnimatedBuilder(
      animation: Listenable.merge([clientsService, salesService]),
      builder: (context, _) {
        final client = clientsService.clients
            .cast<ClientModel?>()
            .firstWhere((item) => item?.id == clientId, orElse: () => null);

        if (client == null) {
          return NexoPageScaffold(
            title: 'Cliente',
            subtitle: 'Detalhe do cliente',
            trailing: NexoIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
            child: const NexoEmptyStateCard(
              title: 'Cliente nao encontrado',
              message:
                  'Este cadastro nao esta mais disponivel na base local atual.',
            ),
          );
        }

        final sales = _salesForClient(client, salesService.sales);
        final totalBought = sales.fold<double>(
          0,
          (total, sale) => total + sale.grossAmount,
        );
        final totalPaid = sales
            .where((sale) => sale.status == SaleStatus.received)
            .fold<double>(
              0,
              (total, sale) => total + sale.netAmount,
            );
        final totalProfit = sales
            .where((sale) => sale.status == SaleStatus.received)
            .fold<double>(
              0,
              (total, sale) => total + sale.ownerAmount,
            );
        final totalOpen = sales
            .where(
              (sale) =>
                  sale.status == SaleStatus.pending ||
                  sale.status == SaleStatus.late,
            )
            .fold<double>(
              0,
              (total, sale) => total + sale.ownerAmount,
            );
        final totalDaniel = sales.fold<double>(
          0,
          (total, sale) => total + sale.danielValue,
        );

        final subtitleParts = <String>[
          client.clientType.label,
          client.billingType.label,
          client.status.label,
        ];

        return NexoPageScaffold(
          title: client.name,
          subtitle: subtitleParts.join(' | '),
          trailing: NexoIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: NexoSpacing.md),
                    _InfoRow(
                      label: 'Tipo',
                      value: client.clientType.label,
                    ),
                    if (client.document?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: client.documentLabel,
                        value: client.document!,
                      ),
                    ],
                    if (client.legalName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: 'Razao social',
                        value: client.legalName!,
                      ),
                    ],
                    if (client.phone?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: 'Telefone',
                        value: client.phone!,
                      ),
                    ],
                    if (client.origin?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: 'Origem',
                        value: client.origin!,
                      ),
                    ],
                    if (client.addressLine != null) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: 'Endereco',
                        value: client.addressLine!,
                      ),
                    ],
                    if (client.notes?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: NexoSpacing.sm),
                      _InfoRow(
                        label: 'Observacoes',
                        value: client.notes!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: NexoSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final soldCard = NexoMetricCard(
                    label: 'Comprou',
                    value: MoneyUtils.format(totalBought),
                    footnote: 'Valor bruto registrado',
                  );
                  final openCard = NexoMetricCard(
                    label: 'Falta pagar',
                    value: MoneyUtils.format(totalOpen),
                    footnote: 'Pendente ou atrasado',
                  );
                  final countCard = NexoMetricCard(
                    label: 'Lucro total',
                    value: MoneyUtils.format(totalProfit),
                    footnote: 'O que ficou para voce',
                  );
                  final paidCard = NexoMetricCard(
                    label: 'Ja pagou',
                    value: MoneyUtils.format(totalPaid),
                    footnote: 'Dinheiro confirmado',
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: soldCard),
                        const SizedBox(width: NexoSpacing.md),
                        Expanded(child: paidCard),
                        const SizedBox(width: NexoSpacing.md),
                        Expanded(child: openCard),
                        const SizedBox(width: NexoSpacing.md),
                        Expanded(child: countCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      soldCard,
                      const SizedBox(height: NexoSpacing.md),
                      paidCard,
                      const SizedBox(height: NexoSpacing.md),
                      openCard,
                      const SizedBox(height: NexoSpacing.md),
                      countCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: NexoSpacing.x2l),
              const NexoSectionHeader(title: 'Historico de vendas e servicos'),
              const SizedBox(height: NexoSpacing.md),
              if (sales.isEmpty)
                const NexoEmptyStateCard(
                  title: 'Sem vendas ainda',
                  message:
                      'Quando este cliente tiver vendas registradas, todo o historico aparece aqui.',
                )
              else
                Column(
                  children: sales.map((sale) {
                    final subtitleParts = <String>[
                      sale.platform,
                      sale.status.label,
                      DateLabelUtils.dayLabel(sale.movementDate.toLocal()),
                    ];

                    final detailParts = <String>[
                      if (sale.projectGroup?.trim().isNotEmpty == true)
                        'Projeto ${sale.projectGroup!.trim()}',
                      if (sale.serviceStage?.trim().isNotEmpty == true)
                        'Etapa ${sale.serviceStage!.trim()}',
                      'Pago ${MoneyUtils.format(sale.netAmount)}',
                      if (sale.danielValue > 0)
                        'Daniel ${MoneyUtils.format(sale.danielValue)}',
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                      child: NexoListTileCard(
                        title: sale.serviceName,
                        subtitle: subtitleParts.join(' | '),
                        detail: detailParts.join(' | '),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              MoneyUtils.format(sale.ownerAmount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: NexoColors.ink),
                            ),
                            const SizedBox(height: NexoSpacing.xxs),
                            Text(
                              sale.status.label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              if (totalDaniel > 0) ...[
                const SizedBox(height: NexoSpacing.xl),
                NexoCard(
                  child: _InfoRow(
                    label: 'Daniel',
                    value:
                        'Este cliente gerou ${MoneyUtils.format(totalDaniel)} para pagar manualmente ao socio.',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<SaleModel> _salesForClient(ClientModel client, List<SaleModel> sales) {
    final normalizedName = client.name.trim().toLowerCase();
    final related = sales.where((sale) {
      if (sale.clientId != null && sale.clientId == client.id) {
        return true;
      }
      return sale.clientName.trim().toLowerCase() == normalizedName;
    }).toList(growable: false);

    related
        .sort((left, right) => right.movementDate.compareTo(left.movementDate));
    return related;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: NexoSpacing.md),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NexoColors.ink,
                ),
          ),
        ),
      ],
    );
  }
}
