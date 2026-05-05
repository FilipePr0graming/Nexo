import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_spacing.dart';
import 'nexo_card.dart';

class NexoMetricCard extends StatelessWidget {
  const NexoMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.footnote,
    this.onTap,
  });

  final String label;
  final String value;
  final String? footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      onTap: onTap,
      backgroundColor: NexoColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NexoColors.inkMedium,
                ),
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: NexoColors.ink,
                ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: NexoSpacing.sm),
            Text(
              footnote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: NexoColors.inkLow,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
