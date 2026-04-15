import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../../../core/design_system/nexo_shadows.dart';

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
      color: backgroundColor ?? NexoColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? NexoColors.border),
      boxShadow: boxShadow ?? NexoShadows.subtle,
    );

    final content = Ink(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
