import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';

class NexoSelectField extends StatelessWidget {
  const NexoSelectField({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: NexoSpacing.xs),
        Material(
          color: NexoColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoRadius.md),
            side: const BorderSide(color: NexoColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(NexoRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NexoSpacing.md,
                vertical: NexoSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: NexoColors.inkLow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

