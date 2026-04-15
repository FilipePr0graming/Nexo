import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_button.dart';
import 'nexo_card.dart';

class NexoEmptyStateCard extends StatelessWidget {
  const NexoEmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: NexoSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: NexoSpacing.lg),
            NexoButton(
              label: buttonLabel!,
              onPressed: onPressed,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}

