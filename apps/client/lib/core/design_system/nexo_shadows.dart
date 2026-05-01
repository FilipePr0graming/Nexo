import 'package:flutter/material.dart';

abstract final class NexoShadows {
  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 20,
          offset: Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get overlay => const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 48,
          offset: Offset(0, 24),
        ),
      ];
}
