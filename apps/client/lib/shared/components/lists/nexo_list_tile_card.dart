import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../cards/nexo_card.dart';

class NexoListTileCard extends StatelessWidget {
  const NexoListTileCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.detail,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = [
      title,
      subtitle,
      if (detail != null) detail!,
    ].join('\n');

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: NexoCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: NexoSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: NexoSpacing.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NexoColors.inkLow,
                        ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: NexoSpacing.sm),
                    Text(
                      detail!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NexoColors.inkMedium,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: NexoSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
