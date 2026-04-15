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
import '../../data/lookup_exception.dart';
import '../../models/address_lookup_result.dart';
import '../../models/client_model.dart';
import '../../models/company_lookup_result.dart';

enum _DanielChoice {
  no,
  yes,
}

enum _AutofillField {
  document,
  name,
  legalName,
  phone,
  zipCode,
  street,
  neighborhood,
  city,
  stateCode,
}

enum _MergeOutcome {
  applied,
  preservedManual,
  unchanged,
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

  final Set<_AutofillField> _dirtyFields = <_AutofillField>{};

  ClientType _clientType = ClientType.pf;
  ClientBillingType _billingType = ClientBillingType.oneOff;
  ClientStatus _status = ClientStatus.active;
  _DanielChoice _danielChoice = _DanielChoice.no;
  bool _isSaving = false;
  bool _isLookingUpCompany = false;
  bool _isLookingUpZipCode = false;
  bool _isApplyingLookup = false;

  String get _nameLabel {
    return _clientType == ClientType.pj ? 'Nome fantasia' : 'Nome completo';
  }

  String get _documentLabel {
    return _clientType == ClientType.pj ? 'CNPJ' : 'CPF';
  }

  @override
  void initState() {
    super.initState();
    _registerDirtyTracking();
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

  void _registerDirtyTracking() {
    _observe(_documentController, _AutofillField.document);
    _observe(_nameController, _AutofillField.name);
    _observe(_legalNameController, _AutofillField.legalName);
    _observe(_phoneController, _AutofillField.phone);
    _observe(_zipCodeController, _AutofillField.zipCode);
    _observe(_streetController, _AutofillField.street);
    _observe(_neighborhoodController, _AutofillField.neighborhood);
    _observe(_cityController, _AutofillField.city);
    _observe(_stateCodeController, _AutofillField.stateCode);
  }

  void _observe(
    TextEditingController controller,
    _AutofillField field,
  ) {
    controller.addListener(() {
      if (_isApplyingLookup) {
        return;
      }
      _dirtyFields.add(field);
    });
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

  Future<void> _lookupCompany() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLookingUpCompany = true);

    try {
      final result = await NexoScope.of(context)
          .clientAutofill
          .lookupCompany(_documentController.text);
      final feedback = _applyCompanyLookup(result);
      if (!mounted) {
        return;
      }
      _showLookupFeedback(
        successMessage: feedback,
      );
    } on LookupException catch (error) {
      if (!mounted) {
        return;
      }
      _showLookupFeedback(errorMessage: error.message);
    } finally {
      if (mounted) {
        setState(() => _isLookingUpCompany = false);
      }
    }
  }

  Future<void> _lookupZipCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLookingUpZipCode = true);

    try {
      final result = await NexoScope.of(context)
          .clientAutofill
          .lookupAddress(_zipCodeController.text);
      final feedback = _applyZipCodeLookup(result);
      if (!mounted) {
        return;
      }
      _showLookupFeedback(
        successMessage: feedback,
      );
    } on LookupException catch (error) {
      if (!mounted) {
        return;
      }
      _showLookupFeedback(errorMessage: error.message);
    } finally {
      if (mounted) {
        setState(() => _isLookingUpZipCode = false);
      }
    }
  }

  String _applyCompanyLookup(CompanyLookupResult result) {
    var applied = 0;
    var preserved = 0;

    void merge(
      TextEditingController controller,
      _AutofillField field,
      String? value,
    ) {
      switch (_mergeValue(controller, field, value)) {
        case _MergeOutcome.applied:
          applied += 1;
          break;
        case _MergeOutcome.preservedManual:
          preserved += 1;
          break;
        case _MergeOutcome.unchanged:
          break;
      }
    }

    _runLookupUpdate(() {
      merge(_documentController, _AutofillField.document, result.cnpj);
      merge(_legalNameController, _AutofillField.legalName, result.legalName);
      merge(_nameController, _AutofillField.name, result.tradeName);
      merge(_phoneController, _AutofillField.phone, result.phone);
      merge(_zipCodeController, _AutofillField.zipCode, result.zipCode);
      merge(_streetController, _AutofillField.street, result.street);
      merge(
        _neighborhoodController,
        _AutofillField.neighborhood,
        result.neighborhood,
      );
      merge(_cityController, _AutofillField.city, result.city);
      merge(_stateCodeController, _AutofillField.stateCode, result.stateCode);
    });

    return _buildFeedbackMessage(
      foundLabel: 'Empresa encontrada.',
      applied: applied,
      preserved: preserved,
    );
  }

  String _applyZipCodeLookup(AddressLookupResult result) {
    var applied = 0;
    var preserved = 0;

    void merge(
      TextEditingController controller,
      _AutofillField field,
      String? value,
    ) {
      switch (_mergeValue(controller, field, value)) {
        case _MergeOutcome.applied:
          applied += 1;
          break;
        case _MergeOutcome.preservedManual:
          preserved += 1;
          break;
        case _MergeOutcome.unchanged:
          break;
      }
    }

    _runLookupUpdate(() {
      merge(_zipCodeController, _AutofillField.zipCode, result.zipCode);
      merge(_streetController, _AutofillField.street, result.street);
      merge(
        _neighborhoodController,
        _AutofillField.neighborhood,
        result.neighborhood,
      );
      merge(_cityController, _AutofillField.city, result.city);
      merge(_stateCodeController, _AutofillField.stateCode, result.stateCode);
    });

    return _buildFeedbackMessage(
      foundLabel: 'CEP encontrado.',
      applied: applied,
      preserved: preserved,
    );
  }

  _MergeOutcome _mergeValue(
    TextEditingController controller,
    _AutofillField field,
    String? nextValue,
  ) {
    final candidate = nextValue?.trim() ?? '';
    if (candidate.isEmpty) {
      return _MergeOutcome.unchanged;
    }

    final current = controller.text.trim();
    final wasEditedManually = _dirtyFields.contains(field);
    final currentDigits = _digitsOnly(current);
    final candidateDigits = _digitsOnly(candidate);

    if ((field == _AutofillField.document || field == _AutofillField.zipCode) &&
        currentDigits.isNotEmpty &&
        currentDigits == candidateDigits) {
      if (current == candidate) {
        return _MergeOutcome.unchanged;
      }

      controller.text = candidate;
      return _MergeOutcome.applied;
    }

    if (current.isNotEmpty && wasEditedManually) {
      return _MergeOutcome.preservedManual;
    }

    if (current == candidate) {
      return _MergeOutcome.unchanged;
    }

    controller.text = candidate;
    return _MergeOutcome.applied;
  }

  void _runLookupUpdate(VoidCallback action) {
    _isApplyingLookup = true;
    try {
      action();
    } finally {
      _isApplyingLookup = false;
    }
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _buildFeedbackMessage({
    required String foundLabel,
    required int applied,
    required int preserved,
  }) {
    if (applied == 0 && preserved > 0) {
      return '$foundLabel Mantive os campos que voce ja preencheu.';
    }

    if (applied > 0 && preserved > 0) {
      return '$foundLabel Atualizei os campos vazios e mantive os dados manuais.';
    }

    if (applied > 0) {
      return '$foundLabel Dados preenchidos automaticamente.';
    }

    return '$foundLabel Os dados ja estavam preenchidos.';
  }

  void _showLookupFeedback({
    String? successMessage,
    String? errorMessage,
  }) {
    final text = errorMessage ?? successMessage;
    if (text == null || text.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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

  Future<void> _lookupCompany() async {
    if (_clientType != ClientType.pj || _isLookingUpCnpj) {
      return;
    }

    setState(() => _isLookingUpCnpj = true);

    final autofill = NexoScope.of(context).clientAutofill;
    try {
      final result = await autofill.lookupCompanyByCnpj(_documentController.text);
      _mergeCompanyAutofill(result);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados da empresa preenchidos.')),
      );
    } on LookupValidationException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on LookupNotFoundException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on LookupRequestException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel buscar o CNPJ agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLookingUpCnpj = false);
      }
    }
  }

  Future<void> _lookupCep() async {
    if (_isLookingUpCep) {
      return;
    }

    setState(() => _isLookingUpCep = true);

    final autofill = NexoScope.of(context).clientAutofill;
    try {
      final result = await autofill.lookupAddressByCep(_zipCodeController.text);
      _mergeAddressAutofill(
        zipCode: result.zipCode,
        street: result.street,
        neighborhood: result.neighborhood,
        city: result.city,
        stateCode: result.stateCode,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereco preenchido pelo CEP.')),
      );
    } on LookupValidationException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on LookupNotFoundException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on LookupRequestException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel buscar o CEP agora.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLookingUpCep = false);
      }
    }
  }

  void _mergeCompanyAutofill(CompanyLookupResult result) {
    _setIfEmpty(_legalNameController, result.legalName);
    _setIfEmpty(_nameController, result.tradeName);
    _setIfEmpty(_phoneController, result.phone);
    _mergeAddressAutofill(
      zipCode: result.zipCode,
      street: result.street,
      neighborhood: result.neighborhood,
      city: result.city,
      stateCode: result.stateCode,
    );
  }

  void _mergeAddressAutofill({
    String? zipCode,
    String? street,
    String? neighborhood,
    String? city,
    String? stateCode,
  }) {
    _setIfEmpty(_zipCodeController, zipCode);
    _setIfEmpty(_streetController, street);
    _setIfEmpty(_neighborhoodController, neighborhood);
    _setIfEmpty(_cityController, city);
    _setIfEmpty(_stateCodeController, stateCode);
  }

  void _setIfEmpty(TextEditingController controller, String? value) {
    final current = controller.text.trim();
    final next = value?.trim() ?? '';
    if (current.isNotEmpty || next.isEmpty) {
      return;
    }

    controller.text = next;
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
                  if (_clientType == ClientType.pj) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: NexoTextField(
                            label: _documentLabel,
                            hint: '00.000.000/0000-00',
                            controller: _documentController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: NexoSpacing.md),
                        NexoButton(
                          label: _isLookingUpCompany
                              ? 'Buscando...'
                              : 'Buscar empresa',
                          variant: NexoButtonVariant.secondary,
                          expanded: false,
                          onPressed: _isLookingUpCompany || _isSaving
                              ? null
                              : _lookupCompany,
                        ),
                      ],
                    ),
                  ] else ...[
                    NexoTextField(
                      label: _documentLabel,
                      hint: '000.000.000-00',
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Telefone',
                    hint: '(00) 00000-0000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Origem',
                    hint: 'Indicacao, anuncio ou organico',
                    controller: _originController,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: NexoTextField(
                          label: 'CEP',
                          hint: '00000-000',
                          controller: _zipCodeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      NexoButton(
                        label:
                            _isLookingUpZipCode ? 'Buscando...' : 'Buscar CEP',
                        variant: NexoButtonVariant.secondary,
                        expanded: false,
                        onPressed: _isLookingUpZipCode || _isSaving
                            ? null
                            : _lookupZipCode,
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
                  Row(
                    children: [
                      Expanded(
                        child: NexoTextField(
                          label: 'UF',
                          hint: 'SP',
                          controller: _stateCodeController,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        flex: 3,
                        child: NexoTextField(
                          label: 'Complemento',
                          hint: 'Opcional',
                          controller: _addressComplementController,
                        ),
                      ),
                    ],
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
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
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
