import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_spacing.dart';

class NexoOptionSheet extends StatelessWidget {
  const NexoOptionSheet({
    super.key,
    required this.title,
    required this.options,
    this.currentValue,
  });

  final String title;
  final List<String> options;
  final String? currentValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? currentValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: NexoColors.surface,
      builder: (_) {
        return NexoOptionSheet(
          title: title,
          options: options,
          currentValue: currentValue,
        );
      },
    );
  }

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
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: NexoSpacing.md),
            ...options.map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option),
                trailing: option == currentValue
                    ? const Icon(
                        Icons.check_rounded,
                        color: NexoColors.ink,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
