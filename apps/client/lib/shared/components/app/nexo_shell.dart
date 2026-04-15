import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../features/clients/presentation/screens/clients_screen.dart';
import '../../../features/clients/presentation/screens/new_client_screen.dart';
import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/finance/presentation/screens/finance_screen.dart';
import '../../../features/finance/presentation/screens/new_expense_screen.dart';
import '../../../features/finance/presentation/screens/new_sale_screen.dart';
import '../../../features/reports/presentation/screens/reports_screen.dart';
import '../actions/nexo_button.dart';
import 'nexo_quick_action_sheet.dart';

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
      ),
      ClientsScreen(
        onNewClient: _openNewClient,
      ),
      FinanceScreen(
        onNewSale: _openNewSale,
        onNewExpense: _openNewExpense,
      ),
      const ReportsScreen(),
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
      setState(() => _currentIndex = 1);
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
            icon: Icons.add_rounded,
            onPressed: _openQuickActions,
            expanded: false,
          ),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              backgroundColor: NexoColors.surface,
              indicatorColor: NexoColors.surfaceElevated,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Hoje'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_rounded),
                  label: Text('Clientes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payments_rounded),
                  label: Text('Financeiro'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded),
                  label: Text('Relatorios'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActions,
        backgroundColor: NexoColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        color: NexoColors.surface,
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
                    icon: Icons.grid_view_rounded,
                    selected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Clientes',
                    icon: Icons.people_alt_rounded,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Financeiro',
                    icon: Icons.payments_rounded,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Relatorios',
                    icon: Icons.insert_chart_outlined_rounded,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
