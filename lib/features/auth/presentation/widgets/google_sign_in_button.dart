import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import 'google_logo.dart';
import 'social_auth_button.dart';

/// Botão oficial para entrada com a conta Google.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continuar com o Google',
    this.darkMode,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final bool? darkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = darkMode ?? (Theme.of(context).brightness == Brightness.dark);

    final bg = isDark ? const Color(0xFF131314) : AppColors.surfaceLowest;
    final fg = isDark ? const Color(0xFFE3E3E3) : AppColors.onSurface;
    final border = isDark ? const Color(0xFF8E918F) : AppColors.outlineVariant;

    return SocialAuthButton(
      onPressed: onPressed,
      isLoading: isLoading,
      icon: const GoogleLogo(size: 20),
      label: text,
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: border,
    );
  }
}
