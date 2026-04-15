import 'package:flutter/material.dart';

abstract final class NexoShadows {
  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get overlay => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ];
}

