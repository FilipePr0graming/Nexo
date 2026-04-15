import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../core/design_system/nexo_typography.dart';
import 'nexo_card.dart';

class NexoMetricCard extends StatelessWidget {
  const NexoMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.footnote,
  });

  final String label;
  final String value;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      backgroundColor: NexoColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NexoColors.inkLow,
                ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            value,
            style: NexoTypography.monoStyle(
              size: 20,
              height: 1.2,
              weight: FontWeight.w700,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: NexoSpacing.sm),
            Text(
              footnote!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
