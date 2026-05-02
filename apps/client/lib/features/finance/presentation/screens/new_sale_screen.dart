import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/models/financial_summary.dart';
import '../../../../core/services/finance_calculator.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/actions/nexo_option_sheet.dart';
import '../../../../shared/components/app/nexo_header.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/inputs/nexo_segmented_field.dart';
import '../../../../shared/components/inputs/nexo_select_field.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';
import '../../../clients/models/client_model.dart';
import '../../../projects/models/project_model.dart';
import '../../models/sale_model.dart';

enum _PartnerChoice {
  no,
  yes,
}

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _projectGroupController = TextEditingController();
  final TextEditingController _serviceStageController = TextEditingController();
  final TextEditingController _grossController = TextEditingController();
  final TextEditingController _platformFeeController = TextEditingController();
  final TextEditingController _paymentFeeController = TextEditingController();
  final TextEditingController _danielPercentController =
      TextEditingController(text: '30');
  final TextEditingController _notesController = TextEditingController();

  _PartnerChoice _partnerChoice = _PartnerChoice.no;
  String _platform = 'Lastlink';
  String _payment = 'Pix';
  int _installments = 1;
  SaleStatus _status = SaleStatus.received;
  DateTime _saleDate = DateTime.now();
  DateTime _expectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _clientController,
      _serviceController,
      _grossController,
      _platformFeeController,
      _paymentFeeController,
      _danielPercentController,
    ]) {
      controller.addListener(_rebuildSummary);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _clientController,
      _serviceController,
      _projectGroupController,
      _serviceStageController,
      _grossController,
      _platformFeeController,
      _paymentFeeController,
      _danielPercentController,
      _notesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _grossAmount => MoneyUtils.parseInput(_grossController.text);
  double get _platformFee => MoneyUtils.parseInput(_platformFeeController.text);
  double get _manualPaymentFee =>
      MoneyUtils.parseInput(_paymentFeeController.text);
  double get _danielPercent => _partnerChoice == _PartnerChoice.yes
      ? MoneyUtils.parseInput(_danielPercentController.text)
      : 0;
  double get _paymentFee => _summary.paymentFee;
  double get _netAmount => _summary.netAmount;
  double get _danielValue => _summary.partnerCommitment;
  double get _ownerAmount => _summary.ownerAmount;

  bool get _isAutomaticPaymentFee {
    final payment = _payment.toLowerCase();
    return payment.contains('pix') ||
        payment.contains('cartao') ||
        payment.contains('cart') ||
        payment.contains('card');
  }

  String get _paymentFeeHint {
    final payment = _payment.toLowerCase();
    if (payment.contains('pix')) {
      return 'Pix sem taxa';
    }
    if (payment.contains('cartao') || payment.contains('cart')) {
      return '7% automatico';
    }
    return '0,00';
  }

  FinancialSummary get _summary => FinanceCalculator.summarize(
        grossAmount: _grossAmount,
        platformFee: _platformFee,
        paymentMethod: _payment,
        manualPaymentFee: _manualPaymentFee,
        hasDanielParticipation: _partnerChoice == _PartnerChoice.yes,
        danielPercent: _danielPercent,
      );

  void _rebuildSummary() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickPlatform() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Plataforma',
      options: const ['Lastlink', 'Pix direto', 'Mercado Pago', 'Outro'],
      currentValue: _platform,
    );

    if (selected != null) {
      setState(() => _platform = selected);
    }
  }

  Future<void> _pickPaymentMethod() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Forma de pagamento',
      options: const ['Pix', 'Cartao', 'Boleto', 'Outro'],
      currentValue: _payment,
    );

    if (selected != null) {
      setState(() {
        _payment = selected;
        if (selected == 'Pix') {
          _expectedDate = _saleDate;
          _paymentFeeController.clear();
        }
      });
    }
  }

  Future<void> _pickInstallments() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Parcelas',
      options: List<String>.generate(12, (index) => '${index + 1}x'),
      currentValue: '${_installments}x',
    );

    if (selected != null) {
      setState(() => _installments = int.parse(selected.replaceAll('x', '')));
    }
  }

  Future<void> _pickStatus() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Status',
      options: SaleStatus.values.map((status) => status.label).toList(),
      currentValue: _status.label,
    );

    if (selected != null) {
      setState(() {
        _status =
            SaleStatus.values.firstWhere((status) => status.label == selected);
      });
    }
  }

  Future<void> _pickDate({
    required bool expected,
  }) async {
    final initialDate = expected ? _expectedDate : _saleDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (expected) {
        _expectedDate = selected;
      } else {
        _saleDate = selected;
        if (_payment == 'Pix') {
          _expectedDate = selected;
        }
      }
    });
  }

  Future<void> _fillClientFromList() async {
    final clients = NexoScope.of(context).clients.clients;
    if (clients.isEmpty) {
      return;
    }

    final selected = await NexoOptionSheet.show(
      context,
      title: 'Clientes salvos',
      options: clients.map((client) => client.name).toList(growable: false),
      currentValue: _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
    );

    if (selected == null) {
      return;
    }

    final matchedClient = clients.cast<ClientModel?>().firstWhere(
          (client) => client != null && client.name == selected,
          orElse: () => null,
        );

    _clientController.text = selected;
    if (matchedClient != null) {
      setState(() {
        _partnerChoice = matchedClient.hasDanielParticipation
            ? _PartnerChoice.yes
            : _PartnerChoice.no;
      });
    }
  }

  Future<void> _save() async {
    final clientName = _clientController.text.trim();
    final serviceName = _serviceController.text.trim();

    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o cliente.')),
      );
      return;
    }

    if (_grossAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor bruto valido.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final services = NexoScope.of(context);
    final clients = services.clients.clients;
    final matchedClient = clients.cast<ClientModel?>().firstWhere(
          (client) =>
              client != null &&
              client.name.trim().toLowerCase() == clientName.toLowerCase(),
          orElse: () => null,
        );
    final projectName = _projectGroupController.text.trim();
    final matchedProject = services.projects.projects
        .cast<ProjectModel?>()
        .firstWhere(
          (project) =>
              project != null &&
              project.name.trim().toLowerCase() == projectName.toLowerCase(),
          orElse: () => null,
        );

    await services.sales.createSale(
      clientId: matchedClient?.id,
      projectId: matchedProject?.id,
      clientName: clientName,
      serviceName: serviceName.isEmpty ? 'Projeto' : serviceName,
      projectGroup: _projectGroupController.text,
      serviceStage: _serviceStageController.text,
      grossAmount: _grossAmount,
      platform: _platform,
      paymentMethod: _payment,
      installments: _installments,
      saleDate: _saleDate.toUtc(),
      expectedDate: _expectedDate.toUtc(),
      receivedDate: _status == SaleStatus.received ? _saleDate.toUtc() : null,
      status: _status,
      notes: _notesController.text,
      platformFee: _platformFee,
      paymentFee: _paymentFee,
      hasDanielParticipation: _partnerChoice == _PartnerChoice.yes,
      danielPercent: _danielPercent,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            NexoSpacing.md,
            NexoSpacing.md,
            NexoSpacing.md,
            120,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NexoHeader(
                    title: 'Nova venda',
                    subtitle:
                        'Cada venda pode ter um servico diferente dentro do historico do cliente.',
                    trailing: NexoIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: NexoSpacing.xl),
                  NexoTextField(
                    label: 'Cliente',
                    hint: 'Digite ou toque para escolher salvo',
                    controller: _clientController,
                    onTap: _fillClientFromList,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Servico',
                    hint: 'Ex.: Landing page de campanha',
                    controller: _serviceController,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'Grupo / projeto',
                          hint: 'Opcional',
                          controller: _projectGroupController,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Etapa do servico',
                          hint: 'Execucao, revisao...',
                          controller: _serviceStageController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Valor bruto',
                    hint: '0,00',
                    controller: _grossController,
                    prefixText: 'R\$ ',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoSelectField(
                          label: 'Plataforma',
                          value: _platform,
                          onTap: _pickPlatform,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoSelectField(
                          label: 'Pagamento',
                          value: _payment,
                          onTap: _pickPaymentMethod,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoSelectField(
                          label: 'Parcelas',
                          value: '${_installments}x',
                          onTap: _pickInstallments,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoSelectField(
                          label: 'Status',
                          value: _status.label,
                          onTap: _pickStatus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoSelectField(
                          label: 'Data da venda',
                          value: DateLabelUtils.dayLabel(_saleDate),
                          onTap: () => _pickDate(expected: false),
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoSelectField(
                          label: 'Recebimento previsto',
                          value: DateLabelUtils.dayLabel(_expectedDate),
                          onTap: () => _pickDate(expected: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'Taxa da plataforma',
                          hint: '0,00',
                          controller: _platformFeeController,
                          prefixText: 'R\$ ',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Taxa do pagamento',
                          hint: _paymentFeeHint,
                          controller: _paymentFeeController,
                          prefixText: 'R\$ ',
                          keyboardType: TextInputType.number,
                          enabled: !_isAutomaticPaymentFee,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSegmentedField<_PartnerChoice>(
                    label: 'Daniel participou?',
                    value: _partnerChoice,
                    onChanged: (value) =>
                        setState(() => _partnerChoice = value),
                    segments: const [
                      ButtonSegment(
                        value: _PartnerChoice.no,
                        label: Text('Nao'),
                      ),
                      ButtonSegment(
                        value: _PartnerChoice.yes,
                        label: Text('Sim'),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: '% Daniel',
                    hint: '30',
                    controller: _danielPercentController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Observacao',
                    hint: 'Detalhe opcional da venda',
                    controller: _notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: NexoSpacing.xl),
                  NexoCard(
                    backgroundColor: NexoColors.surfaceElevated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo automatico',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: NexoSpacing.md),
                        _SummaryRow(
                          label: 'Taxas',
                          value: MoneyUtils.format(_platformFee + _paymentFee),
                        ),
                        const SizedBox(height: NexoSpacing.xs),
                        _SummaryRow(
                          label: 'Liquido',
                          value: MoneyUtils.format(_netAmount),
                        ),
                        const SizedBox(height: NexoSpacing.xs),
                        _SummaryRow(
                          label: 'Daniel',
                          value: MoneyUtils.format(_danielValue),
                        ),
                        const SizedBox(height: NexoSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: NexoSpacing.md),
                        _SummaryRow(
                          label: 'Sobra final',
                          value: MoneyUtils.format(_ownerAmount),
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NexoSpacing.md,
            NexoSpacing.md,
            NexoSpacing.md,
            NexoSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: NexoButton(
                  label: 'Cancelar',
                  variant: NexoButtonVariant.secondary,
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: NexoSpacing.md),
              Expanded(
                child: NexoButton(
                  label: _isSaving ? 'Salvando...' : 'Salvar venda',
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
      children: [
        Expanded(
          child: Text(
            label,
            style: strong
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: strong ? NexoColors.ink : NexoColors.inkMedium,
              ),
        ),
      ],
    );
  }
}
