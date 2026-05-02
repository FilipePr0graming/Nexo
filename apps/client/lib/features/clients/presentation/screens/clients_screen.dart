import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_empty_state_card.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';
import '../../../../shared/components/lists/nexo_list_tile_card.dart';
import '../../../../shared/components/lists/nexo_section_header.dart';
import '../../../finance/models/sale_model.dart';
import '../../models/client_model.dart';
import 'client_detail_screen.dart';

enum _ClientsFilter {
  all,
  monthly,
  annual,
  oneOff,
  daniel,
  open,
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({
    super.key,
    required this.onNewClient,
  });

  final VoidCallback onNewClient;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ClientsFilter _filter = _ClientsFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _openClientDetail(String clientId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientDetailScreen(clientId: clientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = NexoScope.of(context);
    final clientsService = services.clients;
    final salesService = services.sales;

    return AnimatedBuilder(
      animation: Listenable.merge([clientsService, salesService]),
      builder: (context, _) {
        final clients = _applyFilters(
          clientsService.clients,
          salesService.sales,
          _searchController.text,
        );

        return NexoPageScaffold(
          title: 'Clientes',
          subtitle:
              'Historico real por cliente, sem prender cadastro a um servico.',
          trailing: NexoIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Novo cliente',
            onPressed: widget.onNewClient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexoTextField(
                label: 'Buscar',
                hint: 'Nome, documento, cidade ou servico',
                controller: _searchController,
              ),
              const SizedBox(height: NexoSpacing.lg),
              Wrap(
                spacing: NexoSpacing.xs,
                runSpacing: NexoSpacing.xs,
                children: [
                  _buildFilterChip(_ClientsFilter.all, 'Todos'),
                  _buildFilterChip(_ClientsFilter.monthly, 'Mensal'),
                  _buildFilterChip(_ClientsFilter.annual, 'Anual'),
                  _buildFilterChip(_ClientsFilter.oneOff, 'Avulso'),
                  _buildFilterChip(_ClientsFilter.daniel, 'Daniel'),
                  _buildFilterChip(_ClientsFilter.open, 'Em aberto'),
                ],
              ),
              const SizedBox(height: NexoSpacing.xl),
              const NexoSectionHeader(title: 'Lista'),
              const SizedBox(height: NexoSpacing.md),
              if (clientsService.isLoading && clients.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: NexoSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (clients.isEmpty)
                NexoEmptyStateCard(
                  title: 'Nenhum cliente salvo ainda',
                  message:
                      'Cadastre o primeiro cliente para começar a relacionar vendas, servicos e historico financeiro.',
                  buttonLabel: 'Novo cliente',
                  onPressed: widget.onNewClient,
                )
              else
                Column(
                  children: clients.map((client) {
                    final clientSales =
                        _salesForClient(client, salesService.sales);
                    final openAmount = clientSales
                        .where(
                          (sale) =>
                              sale.status == SaleStatus.pending ||
                              sale.status == SaleStatus.late,
                        )
                        .fold<double>(
                            0, (total, sale) => total + sale.ownerAmount);
                    final totalSold = clientSales.fold<double>(
                      0,
                      (total, sale) => total + sale.ownerAmount,
                    );

                    final subtitleParts = <String>[
                      client.clientType.label,
                      client.billingType.label,
                      if (client.cityStateLabel != null) client.cityStateLabel!,
                    ];

                    final detailParts = <String>[
                      'Total ${MoneyUtils.format(totalSold)}',
                      'Em aberto ${MoneyUtils.format(openAmount)}',
                      if (client.document?.trim().isNotEmpty == true)
                        '${client.documentLabel} ${client.document!.trim()}',
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                      child: NexoListTileCard(
                        title: client.name,
                        subtitle: subtitleParts.join(' | '),
                        detail: detailParts.join(' | '),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Acoes do cliente',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditClientSheet(client);
                            }
                            if (value == 'delete') {
                              clientsService.deleteClient(client.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                        onTap: () => _openClientDetail(client.id),
                      ),
                    );
                  }).toList(growable: false),
                ),
              if (clientsService.errorMessage != null) ...[
                const SizedBox(height: NexoSpacing.lg),
                Text(
                  clientsService.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NexoColors.inkLow,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(_ClientsFilter filter, String label) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Future<void> _openEditClientSheet(ClientModel client) async {
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone ?? '');
    final notesController = TextEditingController(text: client.notes ?? '');

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
                    'Editar cliente',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Nome',
                    controller: nameController,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Telefone',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: NexoSpacing.md),
                  NexoTextField(
                    label: 'Observacoes',
                    controller: notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoButton(
                    label: 'Salvar alteracoes',
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        return;
                      }
                      await NexoScope.of(context).clients.updateClient(
                            client.copyWith(
                              name: name,
                              phone: _emptyToNull(phoneController.text),
                              notes: _emptyToNull(notesController.text),
                            ),
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
      phoneController.dispose();
      notesController.dispose();
    }
  }

  List<ClientModel> _applyFilters(
    List<ClientModel> clients,
    List<SaleModel> sales,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    return clients.where((client) {
      final clientSales = _salesForClient(client, sales);
      final hasOpenAmount = clientSales.any(
        (sale) =>
            sale.status == SaleStatus.pending || sale.status == SaleStatus.late,
      );

      final matchesFilter = switch (_filter) {
        _ClientsFilter.all => true,
        _ClientsFilter.monthly =>
          client.billingType == ClientBillingType.monthly,
        _ClientsFilter.annual => client.billingType == ClientBillingType.annual,
        _ClientsFilter.oneOff => client.billingType == ClientBillingType.oneOff,
        _ClientsFilter.daniel => client.hasDanielParticipation,
        _ClientsFilter.open => hasOpenAmount,
      };

      if (!matchesFilter) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = [
        client.name,
        client.legalName,
        client.document,
        client.origin,
        client.city,
        client.stateCode,
        client.zipCode,
        ...clientSales.map((sale) => sale.serviceName),
      ].whereType<String>().map((value) => value.toLowerCase()).join(' ');

      return haystack.contains(normalizedQuery);
    }).toList(growable: false);
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

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
