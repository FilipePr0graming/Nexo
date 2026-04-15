import 'package:flutter/material.dart';

import 'core/app/app_services.dart';
import 'core/app/nexo_scope.dart';
import 'core/design_system/nexo_theme.dart';
import 'shared/components/app/nexo_shell.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  @override
  void dispose() {
    widget.services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NexoScope(
      services: widget.services,
      child: MaterialApp(
        title: 'Nexo',
        debugShowCheckedModeBanner: false,
        theme: NexoTheme.light(),
        home: const NexoShell(),
      ),
    );
  }
}
