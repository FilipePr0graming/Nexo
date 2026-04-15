import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/utils/date_label_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/actions/nexo_icon_button.dart';
import '../../../../shared/components/actions/nexo_option_sheet.dart';
import '../../../../shared/components/app/nexo_header.dart';
import '../../../../shared/components/inputs/nexo_segmented_field.dart';
import '../../../../shared/components/inputs/nexo_select_field.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';
import '../../models/expense_model.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  ExpenseScope _scope = ExpenseScope.business;
  String _category = 'Assinaturas de IA';
  String _accountName = 'Conta empresa';
  DateTime _expenseDate = DateTime.now();
  bool _isSaving = false;

  static const List<String> _businessCategories = [
    'Assinaturas de IA',
    'Softwares',
    'Marketing',
    'Ferramentas',
    'Impostos',
    'Outras operacionais',
  ];

  static const List<String> _personalCategories = [
    'Alimentacao',
    'Moradia',
    'Transporte',
    'Saude',
    'Lazer',
    'Outros',
  ];

  List<String> get _categories {
    return _scope == ExpenseScope.business
        ? _businessCategories
        : _personalCategories;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final selected = await NexoOptionSheet.show(
      context,
      title: 'Categoria',
      options: _categories,
      currentValue: _category,
    );

    if (selected != null) {
      setState(() => _category = selected);
    }
  }

  Future<void> _pickAccount() async {
    final options = _scope == ExpenseScope.business
        ? const ['Conta empresa', 'Cartao empresa', 'Conta pessoal']
        : const ['Conta pessoal', 'Cartao pessoal', 'Conta empresa'];

    final selected = await NexoOptionSheet.show(
      context,
      title: 'Conta pagadora',
      options: options,
      currentValue: _accountName,
    );

    if (selected != null) {
      setState(() => _accountName = selected);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _expenseDate = selected);
    }
  }

  Future<void> _save() async {
    final amount = MoneyUtils.parseInput(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor valido.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final description = _notesController.text.trim();

    await NexoScope.of(context).expenses.createExpense(
      title: description.isEmpty ? _category : description,
      category: _category,
      amount: amount,
      scope: _scope,
      accountName: _accountName,
      expenseDate: _expenseDate.toUtc(),
      notes: description,
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
                    title: 'Novo gasto',
                    subtitle: 'Registro direto, claro e pensado para uma mao so.',
                    trailing: NexoIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: NexoSpacing.xl),
                  NexoTextField(
                    label: 'Valor',
                    hint: '0,00',
                    controller: _amountController,
                    prefixText: 'R\$ ',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSegmentedField<ExpenseScope>(
                    label: 'Escopo',
                    value: _scope,
                    onChanged: (value) {
                      setState(() {
                        _scope = value;
                        _category = _categories.first;
                        _accountName = value == ExpenseScope.business
                            ? 'Conta empresa'
                            : 'Conta pessoal';
                      });
                    },
                    segments: const [
                      ButtonSegment(
                        value: ExpenseScope.business,
                        label: Text('Empresa'),
                      ),
                      ButtonSegment(
                        value: ExpenseScope.personal,
                        label: Text('Pessoal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoSelectField(
                    label: 'Categoria',
                    value: _category,
                    onTap: _pickCategory,
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: NexoSelectField(
                          label: 'Conta pagadora',
                          value: _accountName,
                          onTap: _pickAccount,
                        ),
                      ),
                      const SizedBox(width: NexoSpacing.md),
                      Expanded(
                        child: NexoSelectField(
                          label: 'Data',
                          value: DateLabelUtils.dayLabel(_expenseDate),
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NexoSpacing.lg),
                  NexoTextField(
                    label: 'Observacao',
                    hint: 'Detalhe opcional',
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
                  label: _isSaving ? 'Salvando...' : 'Salvar gasto',
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
