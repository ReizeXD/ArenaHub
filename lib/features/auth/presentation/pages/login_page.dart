import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/value_objects/email.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';

/// Tela de entrada.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed(AuthController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (controller.state case AuthFailed(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  failure.message,
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      controller.dismissError();
    }
  }

  /// A regra de e-mail vem do value object, não é reescrita aqui.
  String? _validateEmail(String? value) => Email.create(value ?? '').fold(
        onSuccess: (_) => null,
        onFailure: (failure) => failure.message,
      );

  /// No login só se checa presença: a política de força vale no cadastro.
  String? _validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'Informe sua senha' : null;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final isLoading = controller.state is AuthInProgress;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'ArenaHub',
                    textAlign: TextAlign.center,
                    style: AppText.displayMobile,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Sua quadra favorita a um toque',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Card(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('E-mail do atleta', style: AppText.labelLg),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: AppText.bodyMd,
                            decoration: const InputDecoration(
                              hintText: 'exemplo@arenahub.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Senha de acesso', style: AppText.labelLg),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: AppText.bodyMd,
                            onFieldSubmitted: (_) =>
                                isLoading ? null : _onLoginPressed(controller),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => _onLoginPressed(controller),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Entrar na quadra'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Highlights(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.xl + 4),
          boxShadow: AppShadows.accent,
        ),
        child: const Icon(
          Icons.sports_soccer_rounded,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Três selos no rodapé, como no design.
///
/// Textos deliberadamente verificáveis: nada de "+40 mil atletas", que o
/// sistema não tem como sustentar.
class _Highlights extends StatelessWidget {
  const _Highlights();

  static const List<({IconData icon, String title, String subtitle})> _items = [
    (
      icon: Icons.bolt_rounded,
      title: 'Reserva na hora',
      subtitle: 'Sem espera'
    ),
    (
      icon: Icons.schedule_rounded,
      title: 'Agenda ao vivo',
      subtitle: 'Horário real'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in _items) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm + 4,
                horizontal: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: AppRadius.slot,
              ),
              child: Column(
                children: [
                  Icon(item.icon, size: 20, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: AppText.labelMd.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: AppText.bodySm,
                  ),
                ],
              ),
            ),
          ),
          if (item != _items.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}
