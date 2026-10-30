import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'social_auth_button.dart';

/// Botão oficial para entrada com a conta Apple.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continuar com a Apple',
    this.darkMode,
    this.isAvailable = true,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final bool? darkMode;
  final bool isAvailable;

  /// Retorna se a plataforma atual suporta nativamente o Sign in with Apple.
  static bool isSupportedOnCurrentPlatform() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    final isDark = darkMode ?? (Theme.of(context).brightness == Brightness.dark);

    // Conforme Apple Human Interface Guidelines:
    // Em fundo claro usa botão preto com texto branco; em escuro, botão branco com texto preto.
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;

    return SocialAuthButton(
      onPressed: onPressed,
      isLoading: isLoading,
      icon: Icon(
        Icons.apple,
        size: 22,
        color: fg,
      ),
      label: text,
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: null,
    );
  }
}
