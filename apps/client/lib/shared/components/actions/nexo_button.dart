import 'package:flutter/material.dart';

enum NexoButtonVariant {
  primary,
  secondary,
  ghost,
}

class NexoButton extends StatelessWidget {
  const NexoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NexoButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NexoButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      NexoButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          child: child,
        ),
      NexoButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      NexoButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          child: child,
        ),
    };

    if (!expanded) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

