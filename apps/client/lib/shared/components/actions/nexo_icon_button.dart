import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';

class NexoIconButton extends StatelessWidget {
  const NexoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: NexoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        side: const BorderSide(color: NexoColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}
