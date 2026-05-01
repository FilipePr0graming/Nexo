import 'package:flutter/material.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../shared/components/actions/nexo_button.dart';
import '../../../../shared/components/app/nexo_background.dart';
import '../../../../shared/components/cards/nexo_card.dart';
import '../../../../shared/components/inputs/nexo_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignedIn,
  });

  final Future<void> Function() onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Informe e-mail e senha.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await NexoScope.of(context).supabase.signInWithEmail(
            email: email,
            password: password,
          );
      await widget.onSignedIn();
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Nao foi possivel entrar agora.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NexoBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NexoSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: NexoCard(
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nexo',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: NexoSpacing.xs),
                        Text(
                          'Entre para sincronizar seus dados com o Supabase.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: NexoSpacing.xl),
                        NexoTextField(
                          label: 'E-mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: NexoSpacing.md),
                        NexoTextField(
                          label: 'Senha',
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !_isLoading,
                          onSubmitted: (_) => _signIn(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: NexoSpacing.md),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: NexoColors.error),
                          ),
                        ],
                        const SizedBox(height: NexoSpacing.xl),
                        NexoButton(
                          label: _isLoading ? 'Entrando...' : 'Entrar',
                          icon: NexoIcons.login,
                          onPressed: _isLoading ? null : _signIn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
