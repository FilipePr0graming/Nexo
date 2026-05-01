import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';

class NexoBackground extends StatelessWidget {
  const NexoBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NexoColors.canvas,
      ),
      child: child,
    );
  }
}
