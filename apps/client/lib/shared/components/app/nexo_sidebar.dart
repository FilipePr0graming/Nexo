import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_hoverable.dart';
import '../cards/nexo_glass_card.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexoSpacing.md,
        NexoSpacing.md,
        NexoSpacing.md,
        NexoSpacing.md,
      ),
      child: SizedBox(
        width: 220,
        child: NexoGlassCard(
          radius: NexoRadius.xl,
          blurSigma: 20,
          tint: const Color(0xFF0C0E16),
          borderColor: NexoColors.border.withValues(alpha: 0.6),
          padding: const EdgeInsets.all(NexoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SidebarHeader(),
              const SizedBox(height: NexoSpacing.lg),
              _SidebarItem(
                icon: NexoIcons.dashboard,
                label: 'Hoje',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _SidebarItem(
                icon: NexoIcons.clients,
                label: 'Clientes',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _SidebarItem(
                icon: NexoIcons.finance,
                label: 'Financeiro',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _SidebarItem(
                icon: NexoIcons.reports,
                label: 'Relatorios',
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
              const Spacer(),
              const _SidebarHint(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NexoRadius.md),
            color: NexoColors.surfaceElevated.withValues(alpha: 0.9),
            border: Border.all(color: NexoColors.border.withValues(alpha: 0.7)),
          ),
          child: const Icon(NexoIcons.dashboard, size: 18),
        ),
        const SizedBox(width: NexoSpacing.sm),
        Expanded(
          child: Text(
            'Nexo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: -0.2,
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
            gradient: LinearGradient(
              colors: [
                NexoColors.accent.withValues(alpha: 0.18),
                NexoColors.accent.withValues(alpha: 0.06),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: NexoColors.accent.withValues(alpha: 0.22),
            ),
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
            color: selected ? NexoColors.inkHigh : NexoColors.inkMedium,
          ),
          const SizedBox(width: NexoSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? NexoColors.inkHigh : NexoColors.inkMedium,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _SidebarHint extends StatelessWidget {
  const _SidebarHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexoSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NexoRadius.lg),
        color: NexoColors.surfaceElevated.withValues(alpha: 0.55),
        border: Border.all(color: NexoColors.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        'Atalhos: use o botao Registrar para criar venda, gasto ou cliente.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: NexoColors.inkLow,
            ),
      ),
    );
  }
}
