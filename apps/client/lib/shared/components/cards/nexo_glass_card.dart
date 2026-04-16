import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_shadows.dart';

class NexoGlassCard extends StatelessWidget {
  const NexoGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.radius = NexoRadius.lg,
    this.tint,
    this.borderColor,
    this.blurSigma = 10,
    this.boxShadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? tint;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: (tint ?? NexoColors.surface).withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (borderColor ?? NexoColors.border).withValues(alpha: 0.55),
      ),
      boxShadow: boxShadow ?? NexoShadows.subtle,
    );

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) {
      return body;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: body,
      ),
    );
  }
}
