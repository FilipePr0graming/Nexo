import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_hoverable.dart';

class NexoCard extends StatelessWidget {
  const NexoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NexoSpacing.lg),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = NexoRadius.lg,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: (backgroundColor ?? NexoColors.surface).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (borderColor ?? NexoColors.border).withValues(alpha: 0.85),
      ),
      boxShadow: boxShadow ?? const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );

    return NexoHoverable(
      enabled: onTap != null,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
