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
          center: Alignment(-0.35, -0.85),
          radius: 1.35,
          colors: [
            Color(0x0DB87444),
            Color(0x0007080D),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
