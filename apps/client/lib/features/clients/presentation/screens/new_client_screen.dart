import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/actions/nexo_option_sheet.dart';
import '../../../../shared/components/app/nexo_header.dart';
import '../../../../shared/components/inputs/nexo_segmented_field.dart';
import '../../../../shared/components/inputs/nexo_select_field.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';
import '../../models/client_model.dart';

enum _DanielChoice {
  no,
  yes,
}

class NewClientScreen extends StatefulWidget {
  const NewClientScreen({super.key});

  @override
  State<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends State<NewClientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  final TextEditingController _addressComplementController =
      TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateCodeController =
      TextEditingController(text: 'SP');
  final TextEditingController _notesController = TextEditingController();

  ClientType _clientType = ClientType.pf;
  ClientBillingType _billingType = ClientBillingType.oneOff;
  ClientStatus _status = ClientStatus.active;
  _DanielChoice _danielChoice = _DanielChoice.no;
  bool _isSaving = false;

  String get _nameLabel {
    return _clientType == ClientType.pj ? 'Nome fantasia' : 'Nome completo';
  }

  String get _documentLabel {
    return _clientType == ClientType.pj ? 'CNPJ' : 'CPF';
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _legalNameController,
      _documentController,
      _phoneController,
      _originController,
      _zipCodeController,
      _streetController,
      _streetNumberController,
      _addressComplementController,
      _neighborhoodController,
      _cityController,
      _stateCodeController,
      _notesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStatus() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Status do cliente',
      options: ClientStatus.values.map((value) => value.label).toList(),
      currentValue: _status.label,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _status =
          ClientStatus.values.firstWhere((value) => value.label == selected);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do cliente.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final clientsService = NexoScope.of(context).clients;
    await clientsService.createClient(
      name: name,
      clientType: _clientType,
      legalName: _legalNameController.text,
      document: _documentController.text,
      phone: _phoneController.text,
      notes: _notesController.text,
      origin: _originController.text,
      zipCode: _zipCodeController.text,
      street: _streetController.text,
      streetNumber: _streetNumberController.text,
      addressComplement: _addressComplementController.text,
      neighborhood: _neighborhoodController.text,
      city: _cityController.text,
      stateCode: _stateCodeController.text,
      status: _status,
      billingType: _billingType,
      hasDanielParticipation: _danielChoice == _DanielChoice.yes,
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
                    title: 'Novo cliente',
                    subtitle:
                        'Cadastro limpo para identificar PF ou PJ, documento e endereco.',
                    trailing: NexoIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: NexoSpacing.xl),
                  NexoSegmentedField<ClientType>(
                    label: 'Tipo de cliente',
                    value: _clientType,
                    onChanged: (value) => setState(() => _clientType = value),
                    segments: const [
                      ButtonSegment(
                        value: ClientType.pf,
                        label: Text('PF'),
                      ),
                      ButtonSegment(
                        value: ClientType.pj,
                        label: Text('PJ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: _nameLabel,
                    hint: _clientType == ClientType.pj
                        ? 'Nome exibido da empresa'
                        : 'Nome da pessoa',
                    controller: _nameController,
                  ),
                  if (_clientType == ClientType.pj) ...[
                    const SizedBox(height: NexoSpacing.lg),
                    NexoTextField(
                      label: 'Razao social',
                      hint: 'Nome juridico da empresa',
                      controller: _legalNameController,
                    ),
                  ],
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: _documentLabel,
                          hint: _clientType == ClientType.pj
                              ? '00.000.000/0000-00'
                              : '000.000.000-00',
                          controller: _documentController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Telefone',
                          hint: '(00) 00000-0000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Origem',
                    hint: 'Indicacao, anuncio ou organico',
                    controller: _originController,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'CEP',
                          hint: '00000-000',
                          controller: _zipCodeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'UF',
                          hint: 'SP',
                          controller: _stateCodeController,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: NexoTextField(
                          label: 'Rua',
                          hint: 'Endereco principal',
                          controller: _streetController,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Numero',
                          hint: 'S/N',
                          controller: _streetNumberController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'Bairro',
                          hint: 'Bairro',
                          controller: _neighborhoodController,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoTextField(
                          label: 'Cidade',
                          hint: 'Cidade',
                          controller: _cityController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Complemento',
                    hint: 'Opcional',
                    controller: _addressComplementController,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSelectField(
                    label: 'Status',
                    value: _status.label,
                    onTap: _pickStatus,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSegmentedField<ClientBillingType>(
                    label: 'Recorrencia',
                    value: _billingType,
                    onChanged: (value) => setState(() => _billingType = value),
                    segments: const [
                      ButtonSegment(
                        value: ClientBillingType.oneOff,
                        label: Text('Avulso'),
                      ),
                      ButtonSegment(
                        value: ClientBillingType.monthly,
                        label: Text('Mensal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSegmentedField<_DanielChoice>(
                    label: 'Daniel participa?',
                    value: _danielChoice,
                    onChanged: (value) => setState(() => _danielChoice = value),
                    segments: const [
                      ButtonSegment(
                        value: _DanielChoice.no,
                        label: Text('Nao'),
                      ),
                      ButtonSegment(
                        value: _DanielChoice.yes,
                        label: Text('Sim'),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Observacoes',
                    hint: 'Notas importantes sobre o cliente',
                    controller: _notesController,
                    maxLines: 3,
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
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: NexoSpacing.md),
              Expanded(
                child: NexoButton(
                  label: _isSaving ? 'Salvando...' : 'Salvar cliente',
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
