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
          center: Alignment(-0.2, -0.9),
          radius: 1.25,
          colors: [
            Color(0x1AC77B3A),
            Color(0x0007080D),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
