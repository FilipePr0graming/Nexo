import 'package:flutter/material.dart';

import 'app_services.dart';

class NexoScope extends InheritedWidget {
  const NexoScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NexoScope>();
    assert(scope != null, 'NexoScope nao encontrado na arvore.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(NexoScope oldWidget) {
    return oldWidget.services != services;
  }
}
