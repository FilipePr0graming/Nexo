import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app/nexo_scope.dart';
import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../core/utils/date_label_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../features/clients/presentation/screens/clients_screen.dart';
import '../../../features/clients/presentation/screens/new_client_screen.dart';
import '../../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/final_ui/presentation/screens/final_pages.dart';
import '../../../features/finance/presentation/screens/finance_screen.dart';
import '../../../features/finance/models/sale_model.dart';
import '../../../features/finance/presentation/screens/new_expense_screen.dart';
import '../../../features/finance/presentation/screens/new_sale_screen.dart';
import '../../../features/menu/presentation/screens/menu_screen.dart';
import '../actions/nexo_button.dart';
import '../inputs/nexo_text_field.dart';
import 'nexo_background.dart';
import 'nexo_quick_action_sheet.dart';
import 'nexo_sidebar.dart';

class NexoShell extends StatefulWidget {
  const NexoShell({super.key});

  @override
  State<NexoShell> createState() => _NexoShellState();
}

class _NexoShellState extends State<NexoShell> {
  int _currentIndex = 0;

  List<Widget> _buildPages() {
    return [
      DashboardScreen(
        onNewSale: _openNewSale,
        onNewExpense: _openNewExpense,
        onOpenClients: () => setState(() => _currentIndex = 1),
        onOpenCalculator: () => setState(() => _currentIndex = 11),
      ),
      ClientsScreen(
        onNewClient: _openNewClient,
      ),
      FinanceScreen(
        onNewSale: _openNewSale,
        onNewExpense: _openNewExpense,
      ),
      MenuScreen(
        onOpenProjects: () => setState(() => _currentIndex = 4),
        onOpenPartners: () => setState(() => _currentIndex = 5),
        onOpenPlanning: () => setState(() => _currentIndex = 6),
        onOpenGoals: () => setState(() => _currentIndex = 7),
        onOpenNotes: () => setState(() => _currentIndex = 8),
        onOpenCalculator: () => setState(() => _currentIndex = 11),
        onOpenHome: () => setState(() => _currentIndex = 10),
        onOpenCompany: () => setState(() => _currentIndex = 9),
        onOpenSettings: _openSettingsDialog,
      ),
      ProjetosScreen(onNewSale: _openNewSale),
      const ParceirosScreen(),
      const PlanejamentoScreen(),
      const MetasScreen(),
      const AnotacoesScreen(),
      EmpresaScreen(
        onNewSale: _openNewSale,
        onNewExpense: _openNewExpense,
      ),
      const CasaScreen(),
      const CalculatorScreen(),
    ];
  }

  Future<void> _openQuickActions() async {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final actions = NexoQuickActionSheet(
      onReceiveMoney: () {
        Navigator.of(context).pop();
        _openNewSale();
      },
      onPayBill: () {
        Navigator.of(context).pop();
        _openNewExpense();
      },
      onAddExpense: () {
        Navigator.of(context).pop();
        _openNewExpense();
      },
      onChargeClient: () {
        Navigator.of(context).pop();
        _openChargeClientSheet();
      },
      onNewReminder: () {
        Navigator.of(context).pop();
        _openReminderSheet();
      },
      onNewNote: () {
        Navigator.of(context).pop();
        _openNoteSheet();
      },
      onOpenCalculator: () {
        Navigator.of(context).pop();
        setState(() => _currentIndex = 11);
      },
    );

    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: NexoColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: actions,
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.xl),
      ),
      builder: (context) => actions,
    );
  }

  Future<void> _openNewSale() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewSaleScreen(),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda salva.')),
      );
    }
  }

  Future<void> _openNewExpense() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewExpenseScreen(),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto salvo.')),
      );
    }
  }

  Future<void> _openNewClient() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NewClientScreen(),
      ),
    );

    if (created == true && mounted) {
      setState(() => _currentIndex = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo.')),
      );
    }
  }

  Future<void> _openChargeClientSheet() {
    final services = NexoScope.of(context);
    return _showShellSheet(
      title: 'Cobrar cliente',
      child: AnimatedBuilder(
        animation: services.sales,
        builder: (context, _) {
          final pending = services.sales.sales
              .where((sale) =>
                  sale.status == SaleStatus.pending ||
                  sale.status == SaleStatus.late)
              .toList(growable: false)
            ..sort((left, right) =>
                left.expectedDate.compareTo(right.expectedDate));

          if (pending.isEmpty) {
            return Text(
              'Sem cobrança em aberto agora.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: pending.take(5).map((sale) {
              return Padding(
                padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                child: _ChargeClientTile(
                  sale: sale,
                  onCopy: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final message =
                        'Oi, ${sale.clientName}. Passando para lembrar do pagamento de ${MoneyUtils.format(sale.ownerAmount)} referente a ${sale.serviceName}.';
                    await Clipboard.setData(ClipboardData(text: message));
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Cobrança copiada.')),
                      );
                    }
                  },
                  onReceived: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await services.sales.markAsReceived(sale.id);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Recebimento marcado.')),
                      );
                    }
                  },
                ),
              );
            }).toList(growable: false),
          );
        },
      ),
    );
  }

  Future<void> _openReminderSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final now = DateTime.now();
    final dateController = TextEditingController(
      text:
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
    );
    final timeController = TextEditingController(text: '09:00');
    var recurrence = '';
    var relatedTable = '';

    return _showShellSheet(
      title: 'Criar lembrete',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexoTextField(
                label: 'Título',
                hint: 'Ex.: Cobrar Anderson',
                controller: titleController,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Detalhe',
                hint: 'Opcional',
                controller: descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: NexoSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: NexoTextField(
                      label: 'Data',
                      hint: 'dd/mm/aaaa',
                      controller: dateController,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  SizedBox(
                    width: 108,
                    child: NexoTextField(
                      label: 'Hora',
                      hint: '09:00',
                      controller: timeController,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: recurrence,
                decoration: const InputDecoration(labelText: 'Repetir'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Não')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                  DropdownMenuItem(value: 'annual', child: Text('Anual')),
                ],
                onChanged: (value) =>
                    setSheetState(() => recurrence = value ?? ''),
              ),
              const SizedBox(height: NexoSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: relatedTable,
                decoration: const InputDecoration(labelText: 'Relacionado a'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Livre')),
                  DropdownMenuItem(value: 'expenses', child: Text('Conta')),
                  DropdownMenuItem(value: 'clients', child: Text('Cliente')),
                  DropdownMenuItem(value: 'notes', child: Text('Nota')),
                  DropdownMenuItem(value: 'purchases', child: Text('Compra')),
                ],
                onChanged: (value) =>
                    setSheetState(() => relatedTable = value ?? ''),
              ),
              const SizedBox(height: NexoSpacing.lg),
              FilledButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final due = _parseDateTime(
                    dateController.text,
                    timeController.text,
                  );
                  if (title.isEmpty || due == null) {
                    return;
                  }
                  await NexoScope.of(context).reminders.createReminder(
                        title: title,
                        description: descriptionController.text,
                        dueDate: due,
                        recurrence: recurrence.isEmpty ? null : recurrence,
                        relatedTable:
                            relatedTable.isEmpty ? null : relatedTable,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lembrete criado.')),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('Criar lembrete'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      dateController.dispose();
      timeController.dispose();
    });
  }

  Future<void> _openNoteSheet() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final categoryController = TextEditingController();
    var isPinned = false;
    var isImportant = false;

    return _showShellSheet(
      title: 'Nova anotação',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NexoTextField(
                label: 'Título',
                hint: 'Ex.: Ideia para cliente',
                controller: titleController,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Texto',
                hint: 'Escreva a nota',
                controller: bodyController,
                maxLines: 4,
              ),
              const SizedBox(height: NexoSpacing.md),
              NexoTextField(
                label: 'Categoria',
                hint: 'Opcional',
                controller: categoryController,
              ),
              const SizedBox(height: NexoSpacing.md),
              Wrap(
                spacing: NexoSpacing.sm,
                children: [
                  FilterChip(
                    label: const Text('Fixar'),
                    selected: isPinned,
                    onSelected: (value) =>
                        setSheetState(() => isPinned = value),
                  ),
                  FilterChip(
                    label: const Text('Importante'),
                    selected: isImportant,
                    onSelected: (value) =>
                        setSheetState(() => isImportant = value),
                  ),
                ],
              ),
              const SizedBox(height: NexoSpacing.lg),
              FilledButton.icon(
                onPressed: () async {
                  final body = bodyController.text.trim();
                  if (body.isEmpty) {
                    return;
                  }
                  await NexoScope.of(context).notes.createNote(
                        title: titleController.text,
                        body: body,
                        category: categoryController.text,
                        isPinned: isPinned,
                        isImportant: isImportant,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Anotação salva.')),
                    );
                  }
                },
                icon: const Icon(NexoIcons.notes),
                label: const Text('Salvar anotação'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      titleController.dispose();
      bodyController.dispose();
      categoryController.dispose();
    });
  }

  Future<void> _openSettingsDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurações'),
          content: const Text('Conta conectada e dados sincronizados.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<T?> _showShellSheet<T>({
    required String title,
    required Widget child,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) {
      return showDialog<T>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: NexoColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(NexoSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: NexoSpacing.lg),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.xl),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            NexoSpacing.lg,
            NexoSpacing.md,
            NexoSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + NexoSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: NexoSpacing.lg),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime? _parseDateTime(String date, String time) {
    final dateParts = date.trim().split('/');
    final timeParts = time.trim().split(':');
    if (dateParts.length != 3 || timeParts.length < 2) {
      return null;
    }
    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if ([day, month, year, hour, minute].any((value) => value == null)) {
      return null;
    }
    return DateTime(year!, month!, day!, hour!, minute!).toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) {
      return Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: NexoSpacing.md),
          child: NexoButton(
            label: 'Registrar',
            icon: NexoIcons.add,
            onPressed: _openQuickActions,
            expanded: false,
          ),
        ),
        body: NexoBackground(
          child: Row(
            children: [
              NexoSidebar(
                selectedIndex: _currentIndex,
                onSelected: (index) => setState(() => _currentIndex = index),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NexoBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActions,
        backgroundColor: NexoColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        tooltip: 'Registrar',
        child: const Icon(NexoIcons.add),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: NexoColors.surface.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: NexoColors.border)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12171717),
                blurRadius: 18,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NexoSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    label: 'Hoje',
                    icon: NexoIcons.dashboard,
                    selected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Clientes',
                    icon: NexoIcons.clients,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Finanças',
                    icon: NexoIcons.finance,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Menu',
                    icon: Icons.menu_rounded,
                    selected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChargeClientTile extends StatelessWidget {
  const _ChargeClientTile({
    required this.sale,
    required this.onCopy,
    required this.onReceived,
  });

  final SaleModel sale;
  final VoidCallback onCopy;
  final VoidCallback onReceived;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        side: const BorderSide(color: NexoColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NexoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: NexoSpacing.xxs),
                      Text(
                        DateLabelUtils.dayLabel(sale.expectedDate.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NexoColors.inkMedium,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NexoSpacing.md),
                Text(
                  MoneyUtils.format(sale.ownerAmount),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: NexoSpacing.sm),
            Wrap(
              spacing: NexoSpacing.sm,
              runSpacing: NexoSpacing.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar cobrança'),
                ),
                FilledButton.icon(
                  onPressed: onReceived,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Marcar recebido'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NexoColors.accent : NexoColors.inkLow;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(NexoRadius.md),
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? NexoColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(NexoRadius.md),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
