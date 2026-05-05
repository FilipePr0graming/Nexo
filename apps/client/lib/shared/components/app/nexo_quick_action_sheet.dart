import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_spacing.dart';

class NexoQuickActionSheet extends StatelessWidget {
  const NexoQuickActionSheet({
    super.key,
    required this.onReceiveMoney,
    required this.onPayBill,
    required this.onAddExpense,
    required this.onChargeClient,
    required this.onNewReminder,
    required this.onNewNote,
    required this.onOpenCalculator,
  });

  final VoidCallback onReceiveMoney;
  final VoidCallback onPayBill;
  final VoidCallback onAddExpense;
  final VoidCallback onChargeClient;
  final VoidCallback onNewReminder;
  final VoidCallback onNewNote;
  final VoidCallback onOpenCalculator;

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
            const SizedBox(height: NexoSpacing.lg),
            _SheetAction(
              icon: NexoIcons.newSale,
              title: 'Recebi dinheiro',
              onTap: onReceiveMoney,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: Icons.receipt_long_rounded,
              title: 'Paguei conta',
              onTap: onPayBill,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: NexoIcons.newExpense,
              title: 'Registrei gasto',
              onTap: onAddExpense,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: NexoIcons.clients,
              title: 'Cobrar cliente',
              onTap: onChargeClient,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: Icons.notifications_none_rounded,
              title: 'Criar lembrete',
              onTap: onNewReminder,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: NexoIcons.notes,
              title: 'Nova anotação',
              onTap: onNewNote,
            ),
            const SizedBox(height: NexoSpacing.sm),
            _SheetAction(
              icon: Icons.calculate_rounded,
              title: 'Calculadora',
              onTap: onOpenCalculator,
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
