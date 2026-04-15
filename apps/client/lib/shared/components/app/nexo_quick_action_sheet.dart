import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_spacing.dart';

class NexoQuickActionSheet extends StatelessWidget {
  const NexoQuickActionSheet({
    super.key,
    required this.onNewSale,
    required this.onNewExpense,
    required this.onNewClient,
  });

  final VoidCallback onNewSale;
  final VoidCallback onNewExpense;
  final VoidCallback onNewClient;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NexoSpacing.lg,
          NexoSpacing.md,
          NexoSpacing.lg,
          NexoSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: NexoSpacing.xs),
            Text(
              'Escolha a acao principal do momento.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NexoColors.inkMedium,
                  ),
            ),
            const SizedBox(height: NexoSpacing.lg),
            _SheetAction(
              icon: NexoIcons.newSale,
              title: 'Nova venda',
              subtitle: 'Registrar uma entrada com liquido e comissao.',
              onTap: onNewSale,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: NexoIcons.newExpense,
              title: 'Novo gasto',
              subtitle: 'Lancar um gasto pessoal ou da empresa.',
              onTap: onNewExpense,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: NexoIcons.newClient,
              title: 'Novo cliente',
              subtitle: 'Cadastrar um contato novo e ligar depois com vendas.',
              onTap: onNewClient,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: NexoColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(NexoSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NexoColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: NexoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: NexoSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
