import 'package:flutter/material.dart';

abstract final class NexoShadows {
  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x0F1A1C1B),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get overlay => const [
        BoxShadow(
          color: Color(0x261A1C1B),
          blurRadius: 48,
          offset: Offset(0, 24),
        ),
      ];
}
