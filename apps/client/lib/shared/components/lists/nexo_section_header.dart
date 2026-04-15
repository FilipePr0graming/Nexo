import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';

class NexoSectionHeader extends StatelessWidget {
  const NexoSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: NexoColors.inkMedium,
                  ),
            ),
          ),
      ],
    );
  }
}

