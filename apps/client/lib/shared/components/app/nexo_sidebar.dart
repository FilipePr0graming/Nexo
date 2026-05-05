import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_hoverable.dart';

class NexoSidebar extends StatelessWidget {
  const NexoSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _SidebarDestination(NexoIcons.dashboard, 'Hoje', 0),
      _SidebarDestination(NexoIcons.clients, 'Clientes', 1),
      _SidebarDestination(NexoIcons.finance, 'Finanças', 2),
      _SidebarDestination(NexoIcons.projects, 'Projetos', 4),
      _SidebarDestination(NexoIcons.planning, 'Planejamento', 6),
      _SidebarDestination(NexoIcons.goals, 'Metas', 7),
      _SidebarDestination(NexoIcons.notes, 'Anotações', 8),
      _SidebarDestination(Icons.menu_rounded, 'Menu', 3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexoSpacing.md,
        NexoSpacing.md,
        NexoSpacing.md,
        NexoSpacing.md,
      ),
      child: SizedBox(
        width: 252,
        child: Container(
          decoration: BoxDecoration(
            color: NexoColors.surfaceMuted,
            borderRadius: BorderRadius.circular(NexoRadius.lg),
            border: Border.all(color: NexoColors.divider),
          ),
          padding: const EdgeInsets.all(NexoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SidebarHeader(),
              const SizedBox(height: NexoSpacing.lg),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SidebarItem(
                      icon: item.icon,
                      label: item.label,
                      selected: selectedIndex == item.index,
                      onTap: () => onSelected(item.index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NexoRadius.md),
            color: NexoColors.accent,
          ),
          child: const Icon(
            NexoIcons.dashboard,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: NexoSpacing.sm),
        Expanded(
          child: Text(
            'Nexo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: NexoColors.inkHigh,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = selected
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(NexoRadius.md),
            color: NexoColors.surfaceElevated,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F1A1C1B),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(NexoRadius.md),
          );

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NexoSpacing.md,
        vertical: 12,
      ),
      decoration: highlight,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? NexoColors.accent : NexoColors.inkLow,
          ),
          const SizedBox(width: NexoSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? NexoColors.inkHigh : NexoColors.inkMedium,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NexoHoverable(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _SidebarDestination {
  const _SidebarDestination(this.icon, this.label, this.index);

  final IconData icon;
  final String label;
  final int index;
}
