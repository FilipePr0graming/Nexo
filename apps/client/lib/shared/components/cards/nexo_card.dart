import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_hoverable.dart';
import 'nexo_glass_card.dart';

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
    return NexoHoverable(
      enabled: onTap != null,
      onTap: onTap,
      child: NexoGlassCard(
        radius: radius,
        tint: backgroundColor ?? NexoColors.surface,
        borderColor: borderColor,
        boxShadow: boxShadow,
        padding: padding,
        child: child,
      ),
    );
  }
}
