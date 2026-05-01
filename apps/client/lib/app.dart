import 'package:flutter/material.dart';

import 'core/app/app_services.dart';
import 'core/app/nexo_scope.dart';
import 'core/design_system/nexo_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
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
        home: _AuthGate(services: widget.services),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.services,
  });

  final AppServices services;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late bool _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.services.supabase.currentUser != null;
  }

  Future<void> _handleSignedIn() async {
    await widget.services.refreshRemoteData();
    if (mounted) {
      setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.services.supabaseEnabled || _isAuthenticated) {
      return const NexoShell();
    }

    return LoginScreen(onSignedIn: _handleSignedIn);
  }
}
