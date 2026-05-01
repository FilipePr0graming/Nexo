import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../features/clients/presentation/screens/clients_screen.dart';
import '../../../features/clients/presentation/screens/new_client_screen.dart';
import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/final_ui/presentation/screens/final_pages.dart';
import '../../../features/finance/presentation/screens/new_expense_screen.dart';
import '../../../features/finance/presentation/screens/new_sale_screen.dart';
import '../actions/nexo_button.dart';
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
        onOpenClients: () => setState(() => _currentIndex = 3),
      ),
      const CasaScreen(),
      EmpresaScreen(
        onNewSale: _openNewSale,
        onNewExpense: _openNewExpense,
      ),
      ClientsScreen(
        onNewClient: _openNewClient,
      ),
      ProjetosScreen(onNewSale: _openNewSale),
      RecebimentosScreen(onNewSale: _openNewSale),
      DespesasScreen(onNewExpense: _openNewExpense),
      const ParceirosScreen(),
      const AssinaturasScreen(),
      const PlanejamentoScreen(),
      const MetasScreen(),
      const InteligenciaScreen(),
      const AnotacoesScreen(),
      const ConfiguracoesScreen(),
    ];
  }

  Future<void> _openQuickActions() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.xl),
      ),
      builder: (context) {
        return NexoQuickActionSheet(
          onNewSale: () {
            Navigator.of(context).pop();
            _openNewSale();
          },
          onNewExpense: () {
            Navigator.of(context).pop();
            _openNewExpense();
          },
          onNewClient: () {
            Navigator.of(context).pop();
            _openNewClient();
          },
        );
      },
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
      setState(() => _currentIndex = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo.')),
      );
    }
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActions,
        backgroundColor: NexoColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(NexoIcons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        color: NexoColors.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NexoSpacing.sm),
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
                    selected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Empresa',
                    icon: NexoIcons.company,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Planejar',
                    icon: NexoIcons.planning,
                    selected: _currentIndex == 9,
                    onTap: () => setState(() => _currentIndex = 9),
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
    final color = selected ? NexoColors.ink : NexoColors.inkLow;
    return InkWell(
      borderRadius: BorderRadius.circular(NexoRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NexoSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
