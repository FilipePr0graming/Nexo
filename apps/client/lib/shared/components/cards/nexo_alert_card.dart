import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import 'nexo_card.dart';

enum NexoAlertTone {
  success,
  warning,
  error,
}

class NexoAlertCard extends StatelessWidget {
  const NexoAlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final NexoAlertTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      NexoAlertTone.success => NexoColors.success,
      NexoAlertTone.warning => NexoColors.warning,
      NexoAlertTone.error => NexoColors.error,
    };

    final soft = switch (tone) {
      NexoAlertTone.success => NexoColors.successSoft,
      NexoAlertTone.warning => NexoColors.warningSoft,
      NexoAlertTone.error => NexoColors.errorSoft,
    };

    return NexoCard(
      backgroundColor: soft,
      borderColor: color.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(NexoRadius.pill),
            ),
          ),
          const SizedBox(width: NexoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NexoSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: NexoColors.inkMedium,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
