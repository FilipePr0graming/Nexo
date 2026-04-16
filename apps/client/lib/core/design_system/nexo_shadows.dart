import 'package:flutter/material.dart';

abstract final class NexoShadows {
  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 14,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get overlay => const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ];
}

