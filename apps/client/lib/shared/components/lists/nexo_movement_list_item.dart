import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_icons.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../core/design_system/nexo_typography.dart';
import 'nexo_list_tile_card.dart';

class NexoMovementListItem extends StatelessWidget {
  const NexoMovementListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    return NexoListTileCard(
      title: title,
      subtitle: subtitle,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isExpense ? '-' : '+'}$amount',
            style: NexoTypography.monoStyle(
              size: 15,
              weight: FontWeight.w600,
              color: NexoColors.ink,
            ),
          ),
          const SizedBox(height: NexoSpacing.xxs),
          Text(
            isExpense ? 'Saida' : 'Entrada',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: NexoColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isExpense ? NexoIcons.expense : NexoIcons.income,
          size: 18,
          color: NexoColors.ink,
        ),
      ),
    );
  }
}
