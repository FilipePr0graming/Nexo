import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_spacing.dart';

class NexoTextField extends StatelessWidget {
  const NexoTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.prefixText,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final String? prefixText;
  final int maxLines;
  final bool enabled;
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          onTap: onTap,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NexoColors.ink,
                ),
          ),
        ),
      ],
    );
  }
}
