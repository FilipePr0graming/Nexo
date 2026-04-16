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
        gradient: RadialGradient(
          center: Alignment(-0.55, -0.95),
          radius: 1.45,
          colors: [
            Color(0x141D2A4A),
            Color(0x000B0D12),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
