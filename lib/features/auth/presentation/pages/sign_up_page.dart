import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/failure.dart';
import '../../../../router/app_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/role.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';
import '../widgets/social_auth_widgets.dart';

/// Tela de cadastro de novo usuário no estilo Athletic Modernist.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUpPressed(AuthController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await controller.signUp(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: Role.player,
    );

    if (!mounted) return;
    _handleAuthFailure(controller);
  }

  Future<void> _onGoogleSignUpPressed(AuthController controller) async {
    setState(() => _isGoogleLoading = true);
    await controller.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    _handleAuthFailure(controller);
  }

  Future<void> _onAppleSignUpPressed(AuthController controller) async {
    setState(() => _isAppleLoading = true);
    await controller.signInWithApple();
    if (!mounted) return;
    setState(() => _isAppleLoading = false);
    _handleAuthFailure(controller);
  }

  void _handleAuthFailure(AuthController controller) {
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

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.split(RegExp(r'\s+')).length < 2) {
      return const InvalidNameFailure().message;
    }
    return null;
  }

  String? _validateEmail(String? value) => Email.create(value ?? '').fold(
        onSuccess: (_) => null,
        onFailure: (failure) => failure.message,
      );

  String? _validatePassword(String? value) =>
      Password.create(value ?? '').fold(
        onSuccess: (_) => null,
        onFailure: (failure) => failure.message,
      );

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme sua senha';
    }
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

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
                    'Criar conta',
                    textAlign: TextAlign.center,
                    style: AppText.displayMobile,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Junte-se à comunidade do ArenaHub',
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
                          Text('Nome completo', style: AppText.labelLg),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: AppText.bodyMd,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Carlos Silva',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: AppSpacing.md),
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
                            textInputAction: TextInputAction.next,
                            style: AppText.bodyMd,
                            decoration: InputDecoration(
                              hintText: 'Mínimo de 8 caracteres',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
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
                          const SizedBox(height: AppSpacing.md),
                          Text('Confirmar senha', style: AppText.labelLg),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            style: AppText.bodyMd,
                            onFieldSubmitted: (_) =>
                                isLoading ? null : _onSignUpPressed(controller),
                            decoration: InputDecoration(
                              hintText: 'Repita sua senha',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Mostrar confirmação de senha'
                                    : 'Ocultar confirmação de senha',
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => _onSignUpPressed(controller),
                            child: (isLoading && !_isGoogleLoading && !_isAppleLoading)
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Criar minha conta'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const SocialAuthDivider(label: 'ou cadastre-se com'),
                          const SizedBox(height: AppSpacing.md),
                          GoogleSignInButton(
                            text: 'Cadastre-se com o Google',
                            onPressed: isLoading
                                ? null
                                : () => _onGoogleSignUpPressed(controller),
                            isLoading: _isGoogleLoading,
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          AppleSignInButton(
                            text: 'Cadastre-se com a Apple',
                            onPressed: isLoading
                                ? null
                                : () => _onAppleSignUpPressed(controller),
                            isLoading: _isAppleLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta?',
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            try {
                              context.go(AppRoutes.login);
                            } catch (_) {
                              // Context sem GoRouter
                            }
                          }
                        },
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
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
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
