import 'package:flutter/material.dart';

import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_radius.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_card.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.onOpenProjects,
    required this.onOpenPartners,
    required this.onOpenPlanning,
    required this.onOpenGoals,
    required this.onOpenNotes,
    required this.onOpenCalculator,
    required this.onOpenHome,
    required this.onOpenCompany,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenProjects;
  final VoidCallback onOpenPartners;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenCalculator;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenCompany;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(NexoIcons.projects, 'Projetos', onOpenProjects),
      _MenuItem(NexoIcons.partners, 'Parceiros', onOpenPartners),
      _MenuItem(NexoIcons.planning, 'Planejamento', onOpenPlanning),
      _MenuItem(NexoIcons.goals, 'Metas', onOpenGoals),
      _MenuItem(NexoIcons.notes, 'Anotações', onOpenNotes),
      _MenuItem(Icons.calculate_rounded, 'Calculadora', onOpenCalculator),
      _MenuItem(NexoIcons.home, 'Casa', onOpenHome),
      _MenuItem(NexoIcons.company, 'Empresa', onOpenCompany),
      _MenuItem(Icons.settings_rounded, 'Configurações', onOpenSettings),
    ];

    return NexoPageScaffold(
      title: 'Menu',
      subtitle: 'Áreas do NEXO.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - (NexoSpacing.md * (columns - 1))) /
                  columns;

          return Wrap(
            spacing: NexoSpacing.md,
            runSpacing: NexoSpacing.md,
            children: items
                .map((item) => SizedBox(width: width, child: _MenuTile(item)))
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.item);

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: NexoCard(
        onTap: item.onTap,
        padding: const EdgeInsets.all(NexoSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: NexoColors.accentSoft,
                borderRadius: BorderRadius.circular(NexoRadius.md),
              ),
              child: Icon(item.icon, color: NexoColors.accent),
            ),
            const SizedBox(width: NexoSpacing.md),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: NexoColors.inkLow),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
