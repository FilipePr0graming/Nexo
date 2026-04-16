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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1115),
            Color(0xFF0B0D12),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.9),
            radius: 1.35,
            colors: [
              Color(0x1A4FD1C5),
              Color(0x000B0D12),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.85, -0.55),
              radius: 1.25,
              colors: [
                Color(0x165AA7FF),
                Color(0x000B0D12),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
